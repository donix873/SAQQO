// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'SAQGO';

  @override
  String get chooseLanguage => 'Выберите язык';

  @override
  String get languageDescription =>
      'Язык можно изменить в настройках без перезапуска.';

  @override
  String get russian => 'Русский';

  @override
  String get kazakh => 'Қазақша';

  @override
  String get continueAction => 'Продолжить';

  @override
  String get skip => 'Продолжить без геолокации';

  @override
  String get welcomeTitle => 'Город рядом. Решения — осознанно.';

  @override
  String get welcomeBody =>
      'SAQGO помогает замечать возможные риски городской мобильности. Приложение не гарантирует безопасность маршрута и не заменяет экстренные службы.';

  @override
  String get map => 'Карта';

  @override
  String get routes => 'Маршруты';

  @override
  String get history => 'История';

  @override
  String get settings => 'Настройки';

  @override
  String get arkalyk => 'Аркалык';

  @override
  String get demo => 'Демо-данные';

  @override
  String get demoMap => 'Демо-карта · геоданные не подключены';

  @override
  String get mapSource => 'Карта: OpenStreetMap';

  @override
  String get mapUnavailable => 'Картографический источник ещё не подключён';

  @override
  String get layers => 'Слои карты';

  @override
  String get searchPlace => 'Найти место';

  @override
  String get route => 'Построить маршрут';

  @override
  String get scan => 'Анализ датчиков';

  @override
  String get lifelog => 'Моя история';

  @override
  String get sos => 'Экстренная помощь';

  @override
  String get noVerifiedRisks => 'Нет проверенных данных о рисках';

  @override
  String get roadBumps => 'Неровности дороги';

  @override
  String get potentialIce => 'Возможный гололёд';

  @override
  String get hazards => 'Возможные риски';

  @override
  String get livePulse => 'Активность города';

  @override
  String get onlyVerified => 'Только подтверждённые';

  @override
  String get sourceQuality => 'Источник и качество данных';

  @override
  String get sourceDemo => 'Все данные на этом экране синтетические.';

  @override
  String get riskTitle => 'Возможная неровность дороги';

  @override
  String get unverified => 'Не подтверждено';

  @override
  String get confidence => 'Уверенность: недостаточно данных';

  @override
  String get lastUpdated => 'Последнее обновление: нет данных';

  @override
  String get openRoute => 'Открыть маршрут';

  @override
  String get hideMarker => 'Скрыть метку';

  @override
  String get recording => 'Запись SmartRoads';

  @override
  String get recordingConsent =>
      'Запись датчиков начнётся только после явного нажатия кнопки. Путь не отправляется без вашего согласия.';

  @override
  String get startRecording => 'Начать запись';

  @override
  String get pause => 'Пауза';

  @override
  String get resume => 'Продолжить';

  @override
  String get stop => 'Остановить';

  @override
  String get duration => 'Длительность';

  @override
  String get candidates => 'Кандидаты';

  @override
  String get gpsDisabled => 'GPS не подключён';

  @override
  String get sensorsNotDiagnose =>
      'Датчики не определяют лёд, люки или безопасность дороги.';

  @override
  String get recordingNotStarted => 'Запись не начата. Данные не собираются.';

  @override
  String get recordingPaused => 'Запись на паузе. Данные не собираются.';

  @override
  String get recordingActive =>
      'Запись активна. Данные хранятся на этом устройстве.';

  @override
  String get tripResult => 'Результат поездки';

  @override
  String get noEvents =>
      'В этой демонстрационной сессии нет кандидатов. Это не означает, что дорога идеальна.';

  @override
  String get saveLocal => 'Сохранить локально';

  @override
  String get delete => 'Удалить';

  @override
  String get routePlanner => 'Поиск и маршрут';

  @override
  String get from => 'Откуда';

  @override
  String get to => 'Куда';

  @override
  String get testPointA => 'Тестовая точка А';

  @override
  String get testPointB => 'Тестовая точка Б';

  @override
  String get faster => 'Более быстрый';

  @override
  String get lessKnownRisk => 'Меньше известных рисков';

  @override
  String get minutes12 => '12 мин';

  @override
  String get minutes16 => '16 мин';

  @override
  String get walking12 => '1,2 км · пешком';

  @override
  String get walking15 => '1,5 км · пешком';

  @override
  String get insufficientData => 'Недостаточно данных для оценки рисков';

  @override
  String get riskDisclaimer => 'Маршрут не гарантирует безопасность';

  @override
  String get startNavigation => 'Начать демо-навигацию';

  @override
  String get navigation => 'Навигация';

  @override
  String get nextTurn => 'Следующий поворот неизвестен: карта не подключена';

  @override
  String get endNavigation => 'Завершить';

  @override
  String get pulseTitle => 'Активность города';

  @override
  String get pulseBody =>
      'В MVP это только концепция с синтетической сеткой. Здесь не показываются отдельные люди, дома или маршруты.';

  @override
  String get localOnly => 'Данные хранятся на устройстве';

  @override
  String get emptyHistory => 'Пока нет сохранённых поездок';

  @override
  String get demoWalk => 'Демо-прогулка';

  @override
  String get sessionDetails => 'Детали сессии';

  @override
  String get syntheticTrack => '12 мин · 1,2 км · синтетический трек';

  @override
  String get deleteHistory => 'Удалить всю историю';

  @override
  String get deleteHistoryBody =>
      'Это действие удалит локальные записи с этого устройства.';

  @override
  String get cancel => 'Отмена';

  @override
  String get confirmDelete => 'Удалить историю';

  @override
  String get sosSubtitle => 'Когда помощь нужна сейчас';

  @override
  String get call112 => 'Позвонить 112';

  @override
  String get opensDialer => 'Откроет системный набор номера';

  @override
  String get networkNeeded => 'Для звонка нужна доступная мобильная сеть.';

  @override
  String get notAutoSent =>
      'SAQGO не связывается со спасателями автоматически.';

  @override
  String get currentCoordinates => 'Текущие координаты';

  @override
  String get coordinatesUnavailable => 'Координаты пока недоступны';

  @override
  String get copyCoordinates => 'Скопировать координаты';

  @override
  String get coordinatesCopied => 'Координаты скопированы';

  @override
  String get accuracy => 'Точность';

  @override
  String get refreshLocation => 'Обновить геолокацию';

  @override
  String get duringCall => 'Во время звонка';

  @override
  String get callStep1 => 'Назовите место и что произошло.';

  @override
  String get callStep2 => 'Следуйте указаниям диспетчера.';

  @override
  String get callStep3 => 'Оставайтесь на связи, если это возможно.';

  @override
  String get bluetoothResearch => 'Bluetooth: исследовательский режим';

  @override
  String get bluetoothNote => 'Не отправляет сигнал спасателям';

  @override
  String get dialerUnavailable => 'Не удалось открыть системный набор номера.';

  @override
  String get privacy => 'Конфиденциальность';

  @override
  String get permissions => 'Разрешения';

  @override
  String get locationPermission => 'Геолокация';

  @override
  String get notifications => 'Уведомления';

  @override
  String get backgroundTasks => 'Фоновые задачи';

  @override
  String get off => 'Выключено';

  @override
  String get privacyBody =>
      'Сбор датчиков выключен по умолчанию. Маршруты и история не отправляются без отдельного согласия.';

  @override
  String get changeLanguage => 'Изменить язык';

  @override
  String get version => 'Версия 0.1.0 · MVP';

  @override
  String get admin => 'Админ-панель';

  @override
  String get monthOctober2026 => 'Октябрь 2026';

  @override
  String get comingSoon => 'Функция пока недоступна';

  @override
  String get close => 'Закрыть';
}
