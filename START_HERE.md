# SAQGO — с чего начать

Проект уже содержит Flutter-приложение, FastAPI-сервер, RU/KK локализацию,
Yandex Maps интеграцию, тесты и GitHub Actions.

## 1. Запустить приложение

```sh
git clone https://github.com/donix873/SAQQO.git
cd SAQQO
bash tool/bootstrap_flutter.sh
flutter devices
flutter run
```

При первом запуске выберите язык. Геолокация запрашивается только после
действия пользователя, запись SmartRoads запускается отдельной кнопкой, а SOS
лишь открывает системный набор номера 112.

## 2. Включить Yandex Maps

Для Android/iOS передайте ограниченный ключ MapKit:

```sh
flutter run --dart-define=YANDEX_MAPKIT_API_KEY=mobile-key
```

Для браузера:

```sh
flutter run -d chrome --dart-define=YANDEX_JS_API_KEY=javascript-key
```

Без ключа мобильная сборка использует OpenStreetMap fallback. Приватные ключи
Yandex Geocoder и Router в клиент передавать нельзя.

## 3. Запустить сервер

```sh
cd server
cp .env.example .env
# заполните .env
docker build -t saqgo-api .
docker run --env-file .env -p 8000:8000 saqgo-api
```

Затем запустите клиент так:

```sh
flutter run \
  --dart-define=YANDEX_MAPKIT_API_KEY=mobile-key \
  --dart-define=SAQGO_API_BASE_URL=http://10.0.2.2:8000
```

`10.0.2.2` — адрес компьютера из Android Emulator. Для физического телефона
используйте доступный HTTPS-домен или IP компьютера в локальной сети.

## 4. Проверить результат

```sh
flutter analyze
flutter test
flutter build apk --debug
cd server && pytest
```

В GitHub Actions workflow **Flutter checks** прикладывает готовый debug APK
`saqgo-android-debug`. Workflow **Publish SAQGO web** публикует web-версию.

## 5. Посмотреть дизайн

Откройте `design/gallery.html`. В галерее 60 статических макетов:
15 экранов × RU/KK × iOS/Android. Это материалы дизайн-проверки; живое
поведение проверяйте в Flutter-приложении.

Перед production-публикацией остаются инфраструктурные решения: HTTPS-домен
API, серверные и клиентские Yandex-ключи, production signing Android/iOS,
реальный источник подтверждённых рисков, модерация и редакторская проверка
казахского текста. Эти ограничения не маскируются демонстрационными данными.
