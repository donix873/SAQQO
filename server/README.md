# SAQGO API

FastAPI gateway хранит приватные ключи Yandex Geocoder/Router/Distance Matrix.
Flutter, APK и GitHub Pages этих ключей не получают.

## Endpoint

- `GET /v1/health` — liveness;
- `GET /v1/capabilities` — только публичные флаги настроенных провайдеров,
  без ключей;
- `GET /v1/places?query=...` — поиск адреса в границах Аркалыка;
- `POST /v1/routes` — маршрут и геометрия Yandex Router;
- `POST /v1/distance-matrix` — матрица расстояний.

Swagger и ReDoc намеренно отключены. Ошибки возвращаются в едином
`{"error": ...}` контракте с `X-Request-ID`.

## Локальный запуск

```bash
cd server
cp .env.example .env
# Поместите приватные серверные ключи только в .env.
docker build -t saqgo-api .
docker run --env-file .env -p 8000:8000 saqgo-api
```

Проверки:

```bash
curl http://localhost:8000/v1/health
curl http://localhost:8000/v1/capabilities
pytest
```

## Переменные

Список находится в `.env.example`. Для production обязательны:

- `YANDEX_GEOCODER_API_KEY`;
- `YANDEX_ROUTE_DETAILS_API_KEY`;
- `YANDEX_DISTANCE_MATRIX_API_KEY` при использовании матрицы;
- `SAQGO_ALLOWED_ORIGINS` с точными HTTPS origin web-клиента;
- `SAQGO_ENV=production`.

## Production

- размещать контейнер только за HTTPS reverse proxy;
- хранить секреты в secret manager платформы, не в образе и не в GitHub;
- ограничить CORS реальным доменом;
- не писать LifeLog, GPS-треки, адресные запросы или provider keys в логи,
  аналитику и crash reports;
- включить platform monitoring только для технических метрик без PII;
- до хранения подтверждённых рисков использовать совместимый с Казахстаном
  Postgres/PostGIS и определить сроки удаления данных;
- модерация `/admin` требует отдельного пароля, TOTP и HTTPS;
- SQLite используется для MVP: хранить файл в постоянном volume, для масштабирования использовать Postgres/PostGIS.

Репозиторий предоставляет готовый Docker-контейнер, но не создаёт внешний
аккаунт хостинга, TLS-сертификат или production-домен.

## Наблюдения и модерация

`GET /v1/hazards` публикует только подтверждённые неистёкшие риски.
`POST /v1/observations` принимает отдельные кандидаты с согласием версии 1.3
и UUID в `Idempotency-Key`; координаты округляются сервером. Полный трек не принимается.
Ожидающие проверки кандидаты удаляются через 24 часа.

Настройте `SAQGO_ADMIN_PASSWORD` (минимум 20 символов) и
`SAQGO_ADMIN_TOTP_SECRET` через секреты сервера. Панель `/admin` поддерживает
вход с TOTP, очередь, подтверждение/отклонение и журнал решений.
Сессия действует 15 минут. Без этих секретов доступ отключён.
Демо-примеры не являются подтверждёнными наблюдениями.
