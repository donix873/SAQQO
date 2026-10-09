# SAQGO

SAQGO — Flutter-приложение городской мобильности для Аркалыка по ТЗ
`SAQGO_Full_Technical_Specification_v1_3_RU_KK.pdf`. Текущая версия:
`0.2.0+2`.

## Что работает

- интерфейс S01–S15 на русском и казахском с сохранением выбранного языка;
- Yandex Maps JavaScript API в веб-версии;
- официальный Yandex MapKit на Android/iOS при передаче мобильного ключа;
- отображение GPS-позиции и геометрии маршрута;
- поиск мест и маршруты через приватный SAQGO API с Yandex Geocoder и
  Yandex Router;
- синтетические примеры карты, рисков, активности и поездки в явном деморежиме;
- добровольная SmartRoads-сессия с паузой, завершением и локальным треком;
- зашифрованный локальный LifeLog, календарь, фильтрация дней, удаление и экспорт;
- модерация наблюдений с паролем, TOTP, сроком действия и журналом решений;
- SOS открывает системный набор номера 112, но не имитирует отправку вызова;
- FastAPI gateway с rate limit, CORS, единым форматом ошибок и без логирования
  адресов, координат и ключей;
- автоматические проверки Flutter, Android APK, web, Python API и публикация
  GitHub Pages.

Риски, Live Pulse и сенсорные кандидаты остаются исследовательскими данными.
Приложение не гарантирует безопасность маршрута и не заменяет экстренные
службы.

## Быстрый запуск

Нужны Flutter stable, Git, Android Studio/Android SDK. Для iOS нужен macOS с
Xcode.

```sh
git clone https://github.com/donix873/SAQQO.git
cd SAQQO
bash tool/bootstrap_flutter.sh
flutter run
```

Скрипт устанавливает зависимости с проверкой lockfile, генерирует локализации
и запускает `flutter analyze` и тесты. Существующие нативные проекты сохраняются.

### Yandex Maps и SAQGO API

Ключи не записываются в репозиторий. Передавайте только публичные клиентские
ключи соответствующей платформы:

```sh
flutter run \
  --dart-define=YANDEX_MAPKIT_API_KEY=mobile-key \
  --dart-define=SAQGO_API_BASE_URL=https://api.example.kz
```

Для web:

```sh
flutter run -d chrome \
  --dart-define=YANDEX_JS_API_KEY=javascript-key \
  --dart-define=SAQGO_API_BASE_URL=https://api.example.kz
```

- `YANDEX_MAPKIT_API_KEY` ограничьте Android package
  `kz.saqgo.saqgo`/iOS bundle ID и подписями приложения.
- `YANDEX_JS_API_KEY` ограничьте доменом опубликованного сайта.
- приватные ключи Geocoder/Router/Distance Matrix должны находиться только на
  сервере.

Карта, поиск и маршруты используют только Яндекс. Без ключей доступен
явный презентационный режим `--dart-define=SAQGO_DEMO_MODE=true`.
Реальный поиск и построение маршрутов требуют ключей и `SAQGO_API_BASE_URL`.

## Сервер

```sh
cd server
cp .env.example .env
# заполните .env приватными серверными ключами
docker build -t saqgo-api .
docker run --env-file .env -p 8000:8000 saqgo-api
```

Проверка: `http://localhost:8000/v1/health`. Полный список endpoint и правила
production-развёртывания: [server/README.md](server/README.md).

## Сборки и проверки

```sh
flutter gen-l10n
flutter analyze
flutter test
flutter build apk --debug
flutter build web --release
cd server && pytest
```

GitHub Actions сохраняет debug APK как artifact `saqgo-android-debug` и
публикует web-сборку через GitHub Pages. Release APK/IPA перед публикацией нужно
подписать собственными production-сертификатами.

Статические дизайн-материалы находятся в `design/`: 60 SVG и 60 PNG для
15 экранов × 2 языка × 2 платформы. Их проверка:

```sh
python -m pip install -r design/requirements.txt
python design/generate.py
python design/validate.py
```

## Честные ограничения

- подтверждённого источника городских рисков и процесса модерации пока нет;
- административный экран показывает техническое состояние, но защищённый
  кабинет ролей/модерации требует отдельной авторизации, MFA и аудита;
- offline-карты, push и BLE mesh не заявлены готовыми;
- требуется редакторская проверка казахского текста и тестирование на реальных
  Android/iOS устройствах;
- серверный контейнер готов к развёртыванию, но адрес production-хостинга,
  TLS, домен и секреты задаёт владелец инфраструктуры.

Подробнее о статических макетах: [design/REVIEW.md](design/REVIEW.md).
