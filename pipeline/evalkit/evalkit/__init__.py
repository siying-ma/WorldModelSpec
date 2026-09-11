"""evalkit — a jurisdiction-neutral evaluation pipeline for traffic-rule monitors.

    L0  trace        rsv/*.pkl, ego_logs.json          what the monitor sees
    L1  facts        facts.jsonl                       what physically happened
    L2  readings     readings/<jurisdiction>.jsonl     what the law demands
    L3  labels       derived, never written by hand    the ground truth

Human effort is spent on L2 alone: O(obligations), once per jurisdiction.
"""
__all__ = ["facts", "reading", "evaluate", "metrics", "extract_sg", "mutation",
           "corpus"]
