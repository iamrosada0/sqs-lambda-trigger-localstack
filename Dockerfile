FROM python:3.11-slim AS builder

WORKDIR /app

COPY lambda_function.py .

RUN apt-get update && apt-get install -y zip

RUN zip function.zip lambda_function.py

CMD ["cat", "function.zip"]
