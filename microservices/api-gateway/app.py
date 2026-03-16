import os
import requests
from flask import Flask, jsonify, request

app = Flask(__name__)

# Service URLs (injected via environment variables)
USER_SERVICE_URL = os.environ.get("USER_SERVICE_URL", "http://localhost:5001")
ORDER_SERVICE_URL = os.environ.get("ORDER_SERVICE_URL", "http://localhost:5002")


@app.route("/")
def index():
    return jsonify({
        "service": "api-gateway",
        "version": "1.0.0",
        "routes": {
            "/api/users": "User operations (proxied to user-service)",
            "/api/orders": "Order operations (proxied to order-service)",
            "/health": "Gateway health check",
        },
    })


@app.route("/health")
def health():
    """Check health of gateway and downstream services."""
    services = {}

    for name, url in [("user-service", USER_SERVICE_URL), ("order-service", ORDER_SERVICE_URL)]:
        try:
            resp = requests.get(f"{url}/health", timeout=3)
            services[name] = resp.json().get("status", "unknown")
        except requests.exceptions.RequestException:
            services[name] = "unreachable"

    all_healthy = all(s == "healthy" for s in services.values())
    return jsonify({
        "status": "healthy" if all_healthy else "degraded",
        "service": "api-gateway",
        "dependencies": services,
    }), 200 if all_healthy else 503


def proxy_request(base_url, path):
    """Forward a request to a downstream service."""
    try:
        url = f"{base_url}/{path}"
        resp = requests.get(url, timeout=5)
        return jsonify(resp.json()), resp.status_code
    except requests.exceptions.RequestException as e:
        return jsonify({"error": f"Service unavailable: {str(e)}"}), 503


# ── User routes ──────────────────────────────────────
@app.route("/api/users")
def proxy_users():
    return proxy_request(USER_SERVICE_URL, "users")


@app.route("/api/users/<int:user_id>")
def proxy_user(user_id):
    return proxy_request(USER_SERVICE_URL, f"users/{user_id}")


@app.route("/api/users/<int:user_id>/orders")
def proxy_user_orders(user_id):
    return proxy_request(USER_SERVICE_URL, f"users/{user_id}/orders")


# ── Order routes ─────────────────────────────────────
@app.route("/api/orders")
def proxy_orders():
    return proxy_request(ORDER_SERVICE_URL, "orders")


@app.route("/api/orders/<int:order_id>")
def proxy_order(order_id):
    return proxy_request(ORDER_SERVICE_URL, f"orders/{order_id}")


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
