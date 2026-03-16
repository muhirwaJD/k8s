import os
import requests
import psycopg2
import psycopg2.extras
from flask import Flask, jsonify

app = Flask(__name__)

# Service discovery (injected via environment variables)
ORDER_SERVICE_URL = os.environ.get("ORDER_SERVICE_URL", "http://localhost:5002")

# Database config (injected via environment variables)
DB_CONFIG = {
    "host":     os.environ.get("DB_HOST", "localhost"),
    "port":     os.environ.get("DB_PORT", 5432),
    "dbname":   os.environ.get("DB_NAME", "usersdb"),
    "user":     os.environ.get("DB_USER", "appuser"),
    "password": os.environ.get("DB_PASSWORD", "apppassword123"),
}


def get_db():
    """Open a new database connection for the current request."""
    return psycopg2.connect(**DB_CONFIG)


import time

def init_db():
    """Create the users table and seed it with data if empty.
    
    Includes a simple retry loop because PostgreSQL might take 
    a few seconds to start up in Docker.
    """
    max_retries = 10
    retry_count = 0
    conn = None

    while retry_count < max_retries:
        try:
            conn = get_db()
            break
        except Exception as e:
            retry_count += 1
            print(f"Waiting for database... (Attempt {retry_count}/{max_retries})")
            time.sleep(2)
    
    if not conn:
        print("Could not connect to database after multiple attempts. Exiting.")
        return

    with conn:
        with conn.cursor() as cur:
            # Create table if it doesn't exist yet
            cur.execute("""
                CREATE TABLE IF NOT EXISTS users (
                    id      SERIAL PRIMARY KEY,
                    name    TEXT NOT NULL,
                    email   TEXT NOT NULL UNIQUE,
                    role    TEXT NOT NULL DEFAULT 'user'
                );
            """)
            # Seed with mock data only if table is empty
            cur.execute("SELECT COUNT(*) FROM users;")
            count = cur.fetchone()[0]
            if count == 0:
                cur.executemany(
                    "INSERT INTO users (name, email, role) VALUES (%s, %s, %s);",
                    [
                        ("Alice Johnson", "alice@example.com", "admin"),
                        ("Bob Smith",     "bob@example.com",   "user"),
                        ("Charlie Brown", "charlie@example.com","user"),
                    ]
                )
    conn.close()
    print("Database initialized successfully ✅")


# ── Routes ────────────────────────────────────────────

@app.route("/health")
def health():
    try:
        conn = get_db()
        conn.close()
        db_status = "connected"
    except Exception:
        db_status = "unreachable"
    return jsonify({"status": "healthy", "service": "user-service", "database": db_status})


@app.route("/users")
def get_users():
    conn = get_db()
    with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
        cur.execute("SELECT * FROM users ORDER BY id;")
        users = cur.fetchall()
    conn.close()
    return jsonify({"users": [dict(u) for u in users], "count": len(users)})


@app.route("/users/<int:user_id>")
def get_user(user_id):
    conn = get_db()
    with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
        cur.execute("SELECT * FROM users WHERE id = %s;", (user_id,))
        user = cur.fetchone()
    conn.close()
    if user is None:
        return jsonify({"error": "User not found"}), 404
    return jsonify(dict(user))


@app.route("/users/<int:user_id>/orders")
def get_user_orders(user_id):
    """Calls order-service to get orders for this user — inter-service communication."""
    conn = get_db()
    with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
        cur.execute("SELECT * FROM users WHERE id = %s;", (user_id,))
        user = cur.fetchone()
    conn.close()

    if user is None:
        return jsonify({"error": "User not found"}), 404

    try:
        response = requests.get(f"{ORDER_SERVICE_URL}/orders/user/{user_id}", timeout=5)
        orders_data = response.json()
    except requests.exceptions.RequestException as e:
        return jsonify({"error": f"Failed to reach order-service: {str(e)}"}), 503

    return jsonify({
        "user": dict(user),
        "orders": orders_data.get("orders", []),
        "order_count": orders_data.get("count", 0),
    })


if __name__ == "__main__":
    init_db()   # Set up the table + seed data on startup
    app.run(host="0.0.0.0", port=5001)
