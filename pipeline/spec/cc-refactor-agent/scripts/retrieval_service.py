#!/usr/bin/env python3
"""

python scripts/retrieval_service.py \
  --model-path <embedding-checkpoint-dir> \
  --index-path <strategies_index.faiss> \
  --metadata-path <strategies_index.meta.json> \
  --port 8010 \
  --cuda-visible-devices 1

Long-running embedding retrieval service.

Startup flow:
1) Launch embedding model with `swift.llm.run_deploy`
2) Load FAISS index + metadata JSON
3) Expose HTTP API for top-k retrieval

Stop the service with Ctrl+C.
"""

from __future__ import annotations

import argparse
import asyncio
import json
import os
import sys
import threading
from contextlib import asynccontextmanager
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import numpy as np
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from openai import OpenAI

import faiss
import uvicorn


@dataclass
class RetrievalConfig:
    model_path: str
    index_path: Path
    metadata_path: Path
    host: str
    port: int
    infer_backend: str
    timeout_s: float
    default_top_k: int
    max_concurrent_requests: int
    acquire_timeout_s: float
    serialize_embeddings: bool
    debug_mode: bool


class RetrievalEngine:
    def __init__(
        self,
        client: OpenAI,
        model_id: str,
        index: Any,
        metadata: list[dict[str, Any]],
        *,
        serialize_embeddings: bool = False,
        debug_mode: bool = False,
    ):
        self.client = client
        self.model_id = model_id
        self.index = index
        self.metadata = metadata
        self._embed_lock = threading.Lock() if serialize_embeddings else None
        self._index_search_lock = threading.Lock()
        self.debug_mode = debug_mode

        if self.index.ntotal == 0:
            raise ValueError("FAISS index is empty.")
        if not self.metadata:
            raise ValueError("Metadata is empty.")

    @classmethod
    def from_paths(
        cls,
        *,
        client: OpenAI,
        model_id: str,
        index_path: Path,
        metadata_path: Path,
        serialize_embeddings: bool = False,
        debug_mode: bool = False,
    ) -> "RetrievalEngine":
        index = faiss.read_index(str(index_path))
        metadata = _load_metadata(metadata_path)
        if len(metadata) < index.ntotal:
            print(
                f"WARNING: metadata has {len(metadata)} rows but index has {index.ntotal} vectors.",
                file=sys.stderr,
            )
        return cls(
            client=client,
            model_id=model_id,
            index=index,
            metadata=metadata,
            serialize_embeddings=serialize_embeddings,
            debug_mode=debug_mode,
        )

    def embed_text(self, text: str) -> np.ndarray:
        if self._embed_lock is None:
            return self._embed_text_unsafe(text)
        with self._embed_lock:
            return self._embed_text_unsafe(text)

    def _embed_text_unsafe(self, text: str) -> np.ndarray:
        # Mirrors the existing embedding request shape in scripts/test_embed.py.
        messages = [
            {
                "role": "user",
                "content": [{"type": "text", "text": text}],
            }
        ]
        response = self.client.chat.completions.create(
            model=self.model_id,
            messages=messages,
        )

        data0 = response.data[0]
        if isinstance(data0, dict):
            embedding = data0["embedding"]
        else:
            embedding = data0.embedding

        vec = np.asarray(embedding, dtype=np.float32)
        if vec.ndim != 1:
            raise ValueError(f"Expected 1D embedding, got shape={vec.shape}")

        if self.debug_mode:
            shape = len(vec)
            sample = str(vec.tolist())
            if shape > 6:
                v = vec.tolist()
                sample = str(v[:3])[:-1] + ", ..., " + str(v[-3:])[1:]
            l2_norm = float(np.linalg.norm(vec))
            print(f"messages: {messages}")
            print(f"Embedding(shape: [1, {shape}]): {sample}")
            print(f"Embedding L2 norm: {l2_norm:.6f}")

        if hasattr(self.index, "d") and self.index.d != vec.shape[0]:
            raise ValueError(
                f"Embedding dimension mismatch: index.d={self.index.d}, embedding={vec.shape[0]}"
            )

        return vec

    def retrieve(self, text_sequence: list[str], top_k: int) -> list[dict[str, Any]]:
        query = _format_query_text(text_sequence)
        if not query.strip():
            raise ValueError("Input text sequence is empty.")
        if int(top_k) <= 0:
            raise ValueError("top_k must be > 0")

        vec = self.embed_text(query).reshape(1, -1)
        if _uses_inner_product_metric(self.index):
            vec = np.ascontiguousarray(vec, dtype=np.float32)
            faiss.normalize_L2(vec)
            if self.debug_mode:
                print(f"Query L2 norm after normalization: {float(np.linalg.norm(vec[0])):.6f}")

        k = max(1, min(int(top_k), int(self.index.ntotal)))

        with self._index_search_lock:
            distances, indices = self.index.search(vec, k)
        scores = distances[0].tolist()
        ids = indices[0].tolist()

        out: list[dict[str, Any]] = []
        for rank, (idx, score) in enumerate(zip(ids, scores), start=1):
            if idx < 0:
                continue
            meta = self.metadata[idx] if idx < len(self.metadata) else {"_missing_metadata": True}
            out.append(
                {
                    "rank": rank,
                    "index": int(idx),
                    "score": float(score),
                    "example": meta,
                }
            )
        return out


def _format_query_text(text_sequence: list[str]) -> str:
    parts = [p.strip() for p in text_sequence if p and p.strip()]
    return "\n\n".join(parts)


def _load_metadata(path: Path) -> list[dict[str, Any]]:
    obj = json.loads(path.read_text(encoding="utf-8"))

    if isinstance(obj, list):
        data = obj
    elif isinstance(obj, dict):
        for key in ("records", "items", "strategies", "examples", "data"):
            if isinstance(obj.get(key), list):
                data = obj[key]
                break
        else:
            raise ValueError(
                "Unsupported metadata JSON format. Expected a list or a dict with list field "
                "in {'records','items','strategies','examples','data'}."
            )
    else:
        raise ValueError("Unsupported metadata JSON format.")

    normalized: list[dict[str, Any]] = []
    for item in data:
        if isinstance(item, dict):
            normalized.append(item)
        else:
            normalized.append({"value": item})
    return normalized


def _parse_text_sequence(payload: dict[str, Any]) -> list[str]:
    if isinstance(payload.get("texts"), list):
        texts = payload["texts"]
        return [str(t) for t in texts]
    if isinstance(payload.get("text"), str):
        return [payload["text"]]
    raise ValueError("Request must contain either `texts` (list[str]) or `text` (str).")


def _uses_inner_product_metric(index: Any) -> bool:
    metric_type = getattr(index, "metric_type", None)
    return metric_type == faiss.METRIC_INNER_PRODUCT


def _make_app(config: RetrievalConfig) -> FastAPI:
    @asynccontextmanager
    async def lifespan(app: FastAPI):
        from swift.llm import DeployArguments, run_deploy

        loop = asyncio.get_running_loop()
        deploy_cm = run_deploy(
            DeployArguments(
                model=config.model_path,
                task_type="embedding",
                infer_backend=config.infer_backend,
                verbose=False,
                log_interval=-1,
            )
        )

        print("[startup] launching embedding model...")
        embed_port = await loop.run_in_executor(None, deploy_cm.__enter__)
        # Only reaches here if __enter__ succeeded; __exit__ is guarded by try/finally.
        try:
            client = OpenAI(
                api_key="EMPTY",
                base_url=f"http://127.0.0.1:{embed_port}/v1",
                timeout=config.timeout_s,
            )
            model_id = client.models.list().data[0].id
            print(f"[startup] embedding endpoint ready on port {embed_port}, model={model_id}")

            engine = RetrievalEngine.from_paths(
                client=client,
                model_id=model_id,
                index_path=config.index_path,
                metadata_path=config.metadata_path,
                serialize_embeddings=config.serialize_embeddings,
                debug_mode=config.debug_mode,
            )
            print(
                f"[startup] index loaded: ntotal={engine.index.ntotal}, "
                f"dim={getattr(engine.index, 'd', 'unknown')}, metadata={len(engine.metadata)}"
            )

            app.state.engine = engine
            app.state.sem = asyncio.Semaphore(config.max_concurrent_requests)

            yield
        finally:
            print("[shutdown] stopping embedding model...")
            await loop.run_in_executor(None, lambda: deploy_cm.__exit__(None, None, None))
            print("[shutdown] done")

    app = FastAPI(lifespan=lifespan)

    @app.get("/health")
    async def health(request: Request):
        engine: RetrievalEngine = request.app.state.engine
        sem: asyncio.Semaphore = request.app.state.sem
        avail = max(0, sem._value)
        return JSONResponse({
            "ok": True,
            "model": engine.model_id,
            "index_size": int(engine.index.ntotal),
            "index_dim": int(getattr(engine.index, "d", -1)),
            "inflight": config.max_concurrent_requests - avail,
            "max_concurrent": config.max_concurrent_requests,
            "available_slots": avail,
        })

    @app.post("/retrieve")
    async def retrieve(request: Request):
        sem: asyncio.Semaphore = request.app.state.sem
        engine: RetrievalEngine = request.app.state.engine

        try:
            await asyncio.wait_for(sem.acquire(), timeout=config.acquire_timeout_s)
        except asyncio.TimeoutError:
            return JSONResponse(
                status_code=429,
                content={
                    "ok": False,
                    "error": "Service busy. Too many concurrent requests.",
                    "max_concurrent": config.max_concurrent_requests,
                    "available_slots": 0,
                },
            )

        # Semaphore acquired — release it in finally no matter what.
        try:
            payload = await request.json()
            text_sequence = _parse_text_sequence(payload)
            top_k = int(payload.get("top_k", config.default_top_k))

            loop = asyncio.get_running_loop()
            results = await loop.run_in_executor(
                None, lambda: engine.retrieve(text_sequence=text_sequence, top_k=top_k)
            )
            return JSONResponse({"ok": True, "top_k": top_k, "results": results})
        except Exception as exc:  # noqa: BLE001
            return JSONResponse(status_code=400, content={"ok": False, "error": str(exc)})
        finally:
            sem.release()

    return app


def _build_arg_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Start embedding retrieval API service.")
    parser.add_argument("--model-path", required=True, help="Path to embedding model checkpoint")
    parser.add_argument("--index-path", required=True, help="Path to FAISS index file")
    parser.add_argument("--metadata-path", required=True, help="Path to metadata JSON file")
    parser.add_argument("--host", default="127.0.0.1", help="Service host")
    parser.add_argument("--port", type=int, default=8010, help="Service port")
    parser.add_argument("--infer-backend", default="vllm", help="Swift inference backend")
    parser.add_argument("--default-top-k", type=int, default=5, help="Default top-k")
    parser.add_argument("--timeout-s", type=float, default=30.0, help="HTTP timeout for OpenAI client")
    parser.add_argument(
        "--max-concurrent-requests",
        type=int,
        default=40,
        help="Maximum concurrent retrieval requests allowed",
    )
    parser.add_argument(
        "--acquire-timeout-s",
        type=float,
        default=5.00,
        help="How long a request waits for a worker slot before returning 429",
    )
    parser.add_argument(
        "--serialize-embeddings",
        action="store_true",
        help="Serialize embedding requests with a lock for strict thread safety",
    )
    parser.add_argument(
        "--debug-mode",
        action="store_true",
        help="Print embedding debug output (messages and embedding sample)",
    )
    parser.add_argument(
        "--cuda-visible-devices",
        default=None,
        help="Optional CUDA_VISIBLE_DEVICES value to set before deployment",
    )
    return parser


def main() -> None:
    args = _build_arg_parser().parse_args()

    config = RetrievalConfig(
        model_path=args.model_path,
        index_path=Path(args.index_path).resolve(),
        metadata_path=Path(args.metadata_path).resolve(),
        host=args.host,
        port=args.port,
        infer_backend=args.infer_backend,
        timeout_s=args.timeout_s,
        default_top_k=args.default_top_k,
        max_concurrent_requests=args.max_concurrent_requests,
        acquire_timeout_s=args.acquire_timeout_s,
        serialize_embeddings=args.serialize_embeddings,
        debug_mode=args.debug_mode,
    )

    if args.cuda_visible_devices is not None:
        os.environ["CUDA_VISIBLE_DEVICES"] = str(args.cuda_visible_devices)

    app = _make_app(config)
    print(f"[startup] retrieval API listening on http://{config.host}:{config.port}")
    print("[startup] stop with Ctrl+C")
    uvicorn.run(app, host=config.host, port=config.port, workers=1, access_log=False)


if __name__ == "__main__":
    main()
