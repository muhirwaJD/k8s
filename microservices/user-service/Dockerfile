FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py start.sh ./
RUN chmod +x start.sh

RUN adduser --disabled-password --no-create-home appuser
USER appuser

EXPOSE 5001

CMD ["./start.sh"]
