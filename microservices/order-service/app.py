from flask import Flask, jsonify

app = Flask(__name__)

# In-memory mock data
ORDERS = [
    {"id": 1, "user_id": 1, "product": "Laptop", "quantity": 1, "price": 1299.99, "status": "shipped"},
    {"id": 2, "user_id": 1, "product": "Mouse", "quantity": 2, "price": 29.99, "status": "delivered"},
    {"id": 3, "user_id": 2, "product": "Keyboard", "quantity": 1, "price": 79.99, "status": "processing"},
    {"id": 4, "user_id": 3, "product": "Monitor", "quantity": 1, "price": 499.99, "status": "shipped"},
    {"id": 5, "user_id": 2, "product": "Headphones", "quantity": 1, "price": 199.99, "status": "delivered"},
]


@app.route("/health")
def health():
    return jsonify({"status": "healthy", "service": "order-service"})


@app.route("/orders")
def get_orders():
    return jsonify({"orders": ORDERS, "count": len(ORDERS)})


@app.route("/orders/<int:order_id>")
def get_order(order_id):
    order = next((o for o in ORDERS if o["id"] == order_id), None)
    if order is None:
        return jsonify({"error": "Order not found"}), 404
    return jsonify(order)


@app.route("/orders/user/<int:user_id>")
def get_user_orders(user_id):
    user_orders = [o for o in ORDERS if o["user_id"] == user_id]
    return jsonify({"user_id": user_id, "orders": user_orders, "count": len(user_orders)})


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5002)
