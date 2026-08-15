import subprocess
import json
import os

def get_claude_status():
    env = os.environ.copy()
    # Ensure no API key is overriding your subscription
    env.pop("ANTHROPIC_API_KEY", None)

    try:
        result = subprocess.run(
            ["claude", "auth", "status"],
            capture_output=True,
            text=True,
            env=env
        )
        
        if result.returncode == 0:
            data = json.loads(result.stdout)
            
            # The 2026 CLI puts the specific plan in 'subscriptionType'
            # inside the raw data or top-level.
            plan_type = data.get("subscriptionType") or data.get("raw", {}).get("subscriptionType")
            
            return {
                "logged_in": True,
                "email": data.get("email"),
                "plan": plan_type.capitalize() if plan_type else "Free",
                "org": data.get("raw", {}).get("orgName")
            }
        return {"logged_in": False, "error": "Not authenticated"}
    except Exception as e:
        return {"logged_in": False, "error": str(e)}

# Test it
status = get_claude_status()
print(f"Active Session: {status['email']} ({status['plan']} Plan)")