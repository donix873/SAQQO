# Serve the tested browser snapshot and API from one HTTPS origin.
FROM python:3.12-slim
WORKDIR /app
COPY server/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY server/app ./app
COPY server/admin.html ./admin.html
ADD https://github.com/donix873/SAQQO/archive/refs/heads/gh-pages.tar.gz /tmp/web.tar.gz
RUN mkdir /app/web /app/data && tar -xzf /tmp/web.tar.gz --strip-components=1 -C /app/web && rm /tmp/web.tar.gz && chown 10001:10001 /app/data
ENV SAQGO_WEB_DIR=/app/web SAQGO_WEB_PATH=/SAQQO SAQGO_DATA_FILE=/app/data/saqgo.sqlite3
USER 10001
EXPOSE 8000
CMD ["sh", "-c", "exec uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000} --no-access-log"]
