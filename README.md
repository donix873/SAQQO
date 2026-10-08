# SAQGO

Flutter MVP мобильной платформы городской мобильности для Арқалық / Аркалыка. Требования: предоставленное заказчиком ТЗ `SAQGO_Full_Technical_Specification_v1_3_RU_KK.pdf`, версия 1.3.

## Что реализовано в исходниках

- Flutter UI в единой дизайн-системе: темная карта, отдельные SVG/PNG-иконки, app icon и splash-символ.
- RU и ҚАЗ через ARB-локализацию, с выбором и сохранением языка на устройстве.
- Экраны S01–S15: язык, onboarding, карта и слои, риск, SmartRoads, результат, поиск маршрута, навигация, Live Pulse, LifeLog, детали сессии, SOS, настройки и административный прототип.
- Карта запрашивает реальный центр Арқалық у OpenStreetMap/Nominatim и показывает тайлы OpenStreetMap. Если сеть или источник недоступны, приложение честно показывает недоступность, без выдуманных координат.
- GPS запрашивается только по действию пользователя. Датчики читаются только в явной пользовательской сессии; эвристика создаёт **неподтверждённый кандидат вибрации**, а не диагноз дороги, льда или люка.
- SOS запускает системный набор `112` и не утверждает, что помощь отправлена автоматически.
- Локальная история и выбранный язык используют хранилище устройства. Backend, модерация и BLE-спасение не включены: им нужны отдельные проверенные данные, роли, сервер и полевые испытания.

## Запуск

Нужны Git, Flutter stable, Android Studio с Android SDK для Android и Xcode для iOS. На Mac для iOS запускайте команды из Terminal; сборка iOS невозможна в Windows.

```sh
git clone https://github.com/donix873/SAQQO.git
cd SAQQO
export FLUTTER_ROOT=/путь/к/flutter
bash tool/bootstrap_flutter.sh
```

`bootstrap_flutter.sh` создаст нативные Android/iOS каталоги, добавит разрешения GPS/движения, сгенерирует app icon и splash, загрузит пакеты, сгенерирует локализации и запустит анализ с тестами.

Затем подключите телефон или запустите эмулятор и выполните:

```sh
flutter devices
flutter run
```

Для Android выпускной APK:

```sh
flutter build apk --release
```

Для iPhone:

```sh
flutter build ios --release
```

Перед первой установкой настройте подпись Android/iOS в Android Studio/Xcode. Для публикации в App Store нужен Apple Developer account.

## Проверки

```sh
flutter gen-l10n
flutter analyze
flutter test
XDG_CACHE_HOME=/workspace/.cache /workspace/.saqgo-design-venv/bin/python design/generate.py
/workspace/.saqgo-design-venv/bin/python design/validate.py
```

`design/validate.py` проверяет 20 первых визуальных экспортов и оригинальные ассеты. `flutter test` проверяет консервативную эвристику сенсорного кандидата; успешный тест не доказывает качество распознавания на реальных дорогах.

## Первый результат: визуальная концепция 01

- `design/moodboard.svg` / `.png`: палитра, типографика, иконки и карта-концепт.
- `design/overview.png`: обзор пяти эталонных экранов.
- `design/gallery.html`: локальная галерея с переключением RU/ҚАЗ и iOS/Android.
- `design/exports/`: 20 самостоятельных PNG 2× и 20 редактируемых SVG (5 × 2 языка × 2 платформы).
- `assets/icons/`: оригинальные отдельные SVG и прозрачные PNG 1×/2×/3×; `assets/assets_manifest.csv` — происхождение и лицензия.
- `assets/branding/`: самостоятельные app icon 1024×1024 и splash-символ в SVG/PNG.

Открыть `design/gallery.html` браузером непосредственно с диска. Для локальной проверки через HTTP:

```sh
cd /workspace/SAQQO
python -m http.server 8080 --bind 127.0.0.1
```

## Пересборка визуалов

Python 3.12, CairoSVG 2.9.1, Pillow 12.3.0; нужны системная Cairo и Noto Sans с кириллицей/казахским.

```sh
python -m venv /workspace/.saqgo-design-venv
/workspace/.saqgo-design-venv/bin/pip install -r design/requirements.txt
XDG_CACHE_HOME=/workspace/.cache /workspace/.saqgo-design-venv/bin/python design/generate.py
```

На другой машине используйте локальный путь для виртуального окружения вместо `/workspace`.
Генератор перезаписывает только собственные ассеты и экспорты; правки исходных макетов нужно переносить в генератор, иначе они будут заменены при следующем запуске.

## Ограничения, которые нельзя имитировать

Казахский текст требует проверки редактором до публикации. Реальные риски, модерация, безопасная маршрутизация, офлайн-карты, push, BLE mesh, backend и админ-доступ не могут считаться готовыми без источников данных, серверной инфраструктуры, юридических документов, ключей поставщиков и испытаний на устройствах. Подробности: `design/REVIEW.md`.
