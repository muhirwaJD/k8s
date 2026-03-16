#!/bin/sh
# Initialize the database, then start gunicorn

# Run the init_db() function from app.py before serving requests
python -c "from app import init_db; init_db()"

# Start the production server
exec gunicorn --bind 0.0.0.0:5001 --workers 2 --threads 2 app:app
