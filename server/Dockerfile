FROM python:3.12-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app ./app
COPY admin.html ./admin.html

RUN mkdir -p /app/data && chown -R 10001:10001 /app/data
ENV SAQGO_DATA_FILE=/app/data/saqgo.sqlite3
USER 10001
EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--no-access-log"]

