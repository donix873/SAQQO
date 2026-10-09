# SAQGO API

This server is the only place for the private Yandex geocoder and routing
keys. Flutter, the APK, and GitHub Pages never receive those values.

## Local launch

```bash
cd server
cp .env.example .env
# Put only the server keys into .env.
docker build -t saqgo-api .
docker run --env-file .env -p 8000:8000 saqgo-api
```

Check it at `http://localhost:8000/v1/health`.

## Production rules

- deploy behind HTTPS;
- restrict `SAQGO_ALLOWED_ORIGINS` to the real web address;
- use a Kazakhstan-compatible Postgres/PostGIS deployment before storing
  confirmed hazards;
- do not add LifeLog, full GPS tracks, raw address queries, or provider keys
  to logs, analytics, crash reports, or GitHub;
- protect the future admin API with separate authentication, MFA and audit
  records. It is intentionally not exposed in this first server module.
