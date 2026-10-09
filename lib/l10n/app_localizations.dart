import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_kk.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('kk'),
    Locale('ru'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ru, this message translates to:
  /// **'SaqQo'**
  String get appTitle;

  /// No description provided for @chooseLanguage.
  ///
  /// In ru, this message translates to:
  /// **'Выберите язык'**
  String get chooseLanguage;

  /// No description provided for @languageDescription.
  ///
  /// In ru, this message translates to:
  /// **'Язык можно изменить в настройках без перезапуска.'**
  String get languageDescription;

  /// No description provided for @russian.
  ///
  /// In ru, this message translates to:
  /// **'Русский'**
  String get russian;

  /// No description provided for @kazakh.
  ///
  /// In ru, this message translates to:
  /// **'Қазақша'**
  String get kazakh;

  /// No description provided for @continueAction.
  ///
  /// In ru, this message translates to:
  /// **'Продолжить'**
  String get continueAction;

  /// No description provided for @skip.
  ///
  /// In ru, this message translates to:
  /// **'Продолжить без геолокации'**
  String get skip;

  /// No description provided for @enableLocation.
  ///
  /// In ru, this message translates to:
  /// **'Включить геолокацию'**
  String get enableLocation;

  /// No description provided for @restartFirstRun.
  ///
  /// In ru, this message translates to:
  /// **'Пройти начальную настройку заново'**
  String get restartFirstRun;

  /// No description provided for @welcomeTitle.
  ///
  /// In ru, this message translates to:
  /// **'Город рядом. Решения — осознанно.'**
  String get welcomeTitle;

  /// No description provided for @welcomeBody.
  ///
  /// In ru, this message translates to:
  /// **'SAQGO помогает замечать возможные риски городской мобильности. Приложение не гарантирует безопасность маршрута и не заменяет экстренные службы.'**
  String get welcomeBody;

  /// No description provided for @map.
  ///
  /// In ru, this message translates to:
  /// **'Карта'**
  String get map;

  /// No description provided for @routes.
  ///
  /// In ru, this message translates to:
  /// **'Маршруты'**
  String get routes;

  /// No description provided for @history.
  ///
  /// In ru, this message translates to:
  /// **'История'**
  String get history;

  /// No description provided for @settings.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get settings;

  /// No description provided for @arkalyk.
  ///
  /// In ru, this message translates to:
  /// **'Аркалык'**
  String get arkalyk;

  /// No description provided for @demo.
  ///
  /// In ru, this message translates to:
  /// **'Демо-данные'**
  String get demo;

  /// No description provided for @demoMap.
  ///
  /// In ru, this message translates to:
  /// **'Демо-схема · не геоданные'**
  String get demoMap;

  /// No description provided for @mapSource.
  ///
  /// In ru, this message translates to:
  /// **'Карта: Яндекс Карты · подписи провайдера'**
  String get mapSource;

  /// No description provided for @mapUnavailable.
  ///
  /// In ru, this message translates to:
  /// **'Карта временно недоступна'**
  String get mapUnavailable;

  /// No description provided for @layers.
  ///
  /// In ru, this message translates to:
  /// **'Слои карты'**
  String get layers;

  /// No description provided for @searchPlace.
  ///
  /// In ru, this message translates to:
  /// **'Найти место'**
  String get searchPlace;

  /// No description provided for @route.
  ///
  /// In ru, this message translates to:
  /// **'Построить маршрут'**
  String get route;

  /// No description provided for @scan.
  ///
  /// In ru, this message translates to:
  /// **'Анализ датчиков'**
  String get scan;

  /// No description provided for @lifelog.
  ///
  /// In ru, this message translates to:
  /// **'Моя история'**
  String get lifelog;

  /// No description provided for @sos.
  ///
  /// In ru, this message translates to:
  /// **'Экстренная помощь'**
  String get sos;

  /// No description provided for @noVerifiedRisks.
  ///
  /// In ru, this message translates to:
  /// **'Нет проверенных данных о рисках'**
  String get noVerifiedRisks;

  /// No description provided for @roadBumps.
  ///
  /// In ru, this message translates to:
  /// **'Неровности дороги'**
  String get roadBumps;

  /// No description provided for @potentialIce.
  ///
  /// In ru, this message translates to:
  /// **'Возможный гололёд'**
  String get potentialIce;

  /// No description provided for @hazards.
  ///
  /// In ru, this message translates to:
  /// **'Возможные риски'**
  String get hazards;

  /// No description provided for @livePulse.
  ///
  /// In ru, this message translates to:
  /// **'Активность города'**
  String get livePulse;

  /// No description provided for @onlyVerified.
  ///
  /// In ru, this message translates to:
  /// **'Только подтверждённые'**
  String get onlyVerified;

  /// No description provided for @sourceQuality.
  ///
  /// In ru, this message translates to:
  /// **'Источник и качество данных'**
  String get sourceQuality;

  /// No description provided for @sourceDemo.
  ///
  /// In ru, this message translates to:
  /// **'Все данные на этом экране синтетические.'**
  String get sourceDemo;

  /// No description provided for @riskTitle.
  ///
  /// In ru, this message translates to:
  /// **'Возможная неровность дороги'**
  String get riskTitle;

  /// No description provided for @unverified.
  ///
  /// In ru, this message translates to:
  /// **'Не подтверждено'**
  String get unverified;

  /// No description provided for @confidence.
  ///
  /// In ru, this message translates to:
  /// **'Уверенность: недостаточно данных'**
  String get confidence;

  /// No description provided for @lastUpdated.
  ///
  /// In ru, this message translates to:
  /// **'Последнее обновление: нет данных'**
  String get lastUpdated;

  /// No description provided for @openRoute.
  ///
  /// In ru, this message translates to:
  /// **'Открыть маршрут'**
  String get openRoute;

  /// No description provided for @hideMarker.
  ///
  /// In ru, this message translates to:
  /// **'Скрыть метку'**
  String get hideMarker;

  /// No description provided for @recording.
  ///
  /// In ru, this message translates to:
  /// **'Запись SmartRoads'**
  String get recording;

  /// No description provided for @recordingConsent.
  ///
  /// In ru, this message translates to:
  /// **'Запись датчиков начнётся только после явного нажатия кнопки. Путь не отправляется без вашего согласия.'**
  String get recordingConsent;

  /// No description provided for @startRecording.
  ///
  /// In ru, this message translates to:
  /// **'Начать запись'**
  String get startRecording;

  /// No description provided for @pause.
  ///
  /// In ru, this message translates to:
  /// **'Пауза'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In ru, this message translates to:
  /// **'Продолжить'**
  String get resume;

  /// No description provided for @stop.
  ///
  /// In ru, this message translates to:
  /// **'Остановить'**
  String get stop;

  /// No description provided for @duration.
  ///
  /// In ru, this message translates to:
  /// **'Длительность'**
  String get duration;

  /// No description provided for @candidates.
  ///
  /// In ru, this message translates to:
  /// **'Кандидаты'**
  String get candidates;

  /// No description provided for @gpsDisabled.
  ///
  /// In ru, this message translates to:
  /// **'GPS не подключён'**
  String get gpsDisabled;

  /// No description provided for @sensorsNotDiagnose.
  ///
  /// In ru, this message translates to:
  /// **'Датчики не определяют лёд, люки или безопасность дороги.'**
  String get sensorsNotDiagnose;

  /// No description provided for @recordingNotStarted.
  ///
  /// In ru, this message translates to:
  /// **'Запись не начата. Данные не собираются.'**
  String get recordingNotStarted;

  /// No description provided for @recordingPaused.
  ///
  /// In ru, this message translates to:
  /// **'Запись на паузе. Данные не собираются.'**
  String get recordingPaused;

  /// No description provided for @recordingActive.
  ///
  /// In ru, this message translates to:
  /// **'Запись активна. Данные хранятся на этом устройстве.'**
  String get recordingActive;

  /// No description provided for @tripResult.
  ///
  /// In ru, this message translates to:
  /// **'Результат поездки'**
  String get tripResult;

  /// No description provided for @noEvents.
  ///
  /// In ru, this message translates to:
  /// **'За эту сессию кандидаты событий не зафиксированы. Это не означает, что дорога идеальна.'**
  String get noEvents;

  /// No description provided for @saveLocal.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить локально'**
  String get saveLocal;

  /// No description provided for @delete.
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get delete;

  /// No description provided for @routePlanner.
  ///
  /// In ru, this message translates to:
  /// **'Поиск и маршрут'**
  String get routePlanner;

  /// No description provided for @useMyLocation.
  ///
  /// In ru, this message translates to:
  /// **'Моя геолокация'**
  String get useMyLocation;

  /// No description provided for @findPlace.
  ///
  /// In ru, this message translates to:
  /// **'Найти место'**
  String get findPlace;

  /// No description provided for @buildRoute.
  ///
  /// In ru, this message translates to:
  /// **'Построить маршрут'**
  String get buildRoute;

  /// No description provided for @enterStartAndEnd.
  ///
  /// In ru, this message translates to:
  /// **'Укажите начальную и конечную точки'**
  String get enterStartAndEnd;

  /// No description provided for @routeReady.
  ///
  /// In ru, this message translates to:
  /// **'Маршрут построен'**
  String get routeReady;

  /// No description provided for @alternativeRoute.
  ///
  /// In ru, this message translates to:
  /// **'Альтернативный маршрут'**
  String get alternativeRoute;

  /// No description provided for @routeUnavailable.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось построить маршрут. Проверьте точки и интернет.'**
  String get routeUnavailable;

  /// No description provided for @routeSource.
  ///
  /// In ru, this message translates to:
  /// **'Маршруты и поиск: Яндекс через SAQGO API'**
  String get routeSource;

  /// No description provided for @from.
  ///
  /// In ru, this message translates to:
  /// **'Откуда'**
  String get from;

  /// No description provided for @to.
  ///
  /// In ru, this message translates to:
  /// **'Куда'**
  String get to;

  /// No description provided for @testPointA.
  ///
  /// In ru, this message translates to:
  /// **'Тестовая точка А'**
  String get testPointA;

  /// No description provided for @testPointB.
  ///
  /// In ru, this message translates to:
  /// **'Тестовая точка Б'**
  String get testPointB;

  /// No description provided for @faster.
  ///
  /// In ru, this message translates to:
  /// **'Более быстрый'**
  String get faster;

  /// No description provided for @lessKnownRisk.
  ///
  /// In ru, this message translates to:
  /// **'Меньше известных рисков'**
  String get lessKnownRisk;

  /// No description provided for @minutes12.
  ///
  /// In ru, this message translates to:
  /// **'12 мин'**
  String get minutes12;

  /// No description provided for @minutes16.
  ///
  /// In ru, this message translates to:
  /// **'16 мин'**
  String get minutes16;

  /// No description provided for @walking12.
  ///
  /// In ru, this message translates to:
  /// **'1,2 км · пешком'**
  String get walking12;

  /// No description provided for @walking15.
  ///
  /// In ru, this message translates to:
  /// **'1,5 км · пешком'**
  String get walking15;

  /// No description provided for @insufficientData.
  ///
  /// In ru, this message translates to:
  /// **'Недостаточно данных для оценки рисков'**
  String get insufficientData;

  /// No description provided for @riskDisclaimer.
  ///
  /// In ru, this message translates to:
  /// **'Маршрут не гарантирует безопасность'**
  String get riskDisclaimer;

  /// No description provided for @startNavigation.
  ///
  /// In ru, this message translates to:
  /// **'Начать навигацию'**
  String get startNavigation;

  /// No description provided for @navigation.
  ///
  /// In ru, this message translates to:
  /// **'Навигация'**
  String get navigation;

  /// No description provided for @nextTurn.
  ///
  /// In ru, this message translates to:
  /// **'Следуйте линии маршрута на карте'**
  String get nextTurn;

  /// No description provided for @endNavigation.
  ///
  /// In ru, this message translates to:
  /// **'Завершить'**
  String get endNavigation;

  /// No description provided for @pulseTitle.
  ///
  /// In ru, this message translates to:
  /// **'Активность города'**
  String get pulseTitle;

  /// No description provided for @pulseBody.
  ///
  /// In ru, this message translates to:
  /// **'В MVP это только концепция с синтетической сеткой. Здесь не показываются отдельные люди, дома или маршруты.'**
  String get pulseBody;

  /// No description provided for @localOnly.
  ///
  /// In ru, this message translates to:
  /// **'Данные хранятся на устройстве'**
  String get localOnly;

  /// No description provided for @emptyHistory.
  ///
  /// In ru, this message translates to:
  /// **'Пока нет сохранённых поездок'**
  String get emptyHistory;

  /// No description provided for @demoWalk.
  ///
  /// In ru, this message translates to:
  /// **'Демо-прогулка'**
  String get demoWalk;

  /// No description provided for @sessionDetails.
  ///
  /// In ru, this message translates to:
  /// **'Детали сессии'**
  String get sessionDetails;

  /// No description provided for @syntheticTrack.
  ///
  /// In ru, this message translates to:
  /// **'12 мин · 1,2 км · синтетический трек'**
  String get syntheticTrack;

  /// No description provided for @deleteHistory.
  ///
  /// In ru, this message translates to:
  /// **'Удалить всю историю'**
  String get deleteHistory;

  /// No description provided for @deleteHistoryBody.
  ///
  /// In ru, this message translates to:
  /// **'Это действие удалит локальные записи с этого устройства.'**
  String get deleteHistoryBody;

  /// No description provided for @cancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get cancel;

  /// No description provided for @confirmDelete.
  ///
  /// In ru, this message translates to:
  /// **'Удалить историю'**
  String get confirmDelete;

  /// No description provided for @sosSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Когда помощь нужна сейчас'**
  String get sosSubtitle;

  /// No description provided for @call112.
  ///
  /// In ru, this message translates to:
  /// **'Позвонить 112'**
  String get call112;

  /// No description provided for @opensDialer.
  ///
  /// In ru, this message translates to:
  /// **'Откроет системный набор номера'**
  String get opensDialer;

  /// No description provided for @networkNeeded.
  ///
  /// In ru, this message translates to:
  /// **'Для звонка нужна доступная мобильная сеть.'**
  String get networkNeeded;

  /// No description provided for @notAutoSent.
  ///
  /// In ru, this message translates to:
  /// **'SAQGO не связывается со спасателями автоматически.'**
  String get notAutoSent;

  /// No description provided for @currentCoordinates.
  ///
  /// In ru, this message translates to:
  /// **'Текущие координаты'**
  String get currentCoordinates;

  /// No description provided for @coordinatesUnavailable.
  ///
  /// In ru, this message translates to:
  /// **'Координаты пока недоступны'**
  String get coordinatesUnavailable;

  /// No description provided for @copyCoordinates.
  ///
  /// In ru, this message translates to:
  /// **'Скопировать координаты'**
  String get copyCoordinates;

  /// No description provided for @coordinatesCopied.
  ///
  /// In ru, this message translates to:
  /// **'Координаты скопированы'**
  String get coordinatesCopied;

  /// No description provided for @accuracy.
  ///
  /// In ru, this message translates to:
  /// **'Точность'**
  String get accuracy;

  /// No description provided for @refreshLocation.
  ///
  /// In ru, this message translates to:
  /// **'Обновить геолокацию'**
  String get refreshLocation;

  /// No description provided for @duringCall.
  ///
  /// In ru, this message translates to:
  /// **'Во время звонка'**
  String get duringCall;

  /// No description provided for @callStep1.
  ///
  /// In ru, this message translates to:
  /// **'Назовите место и что произошло.'**
  String get callStep1;

  /// No description provided for @callStep2.
  ///
  /// In ru, this message translates to:
  /// **'Следуйте указаниям диспетчера.'**
  String get callStep2;

  /// No description provided for @callStep3.
  ///
  /// In ru, this message translates to:
  /// **'Оставайтесь на связи, если это возможно.'**
  String get callStep3;

  /// No description provided for @bluetoothResearch.
  ///
  /// In ru, this message translates to:
  /// **'Bluetooth: исследовательский режим'**
  String get bluetoothResearch;

  /// No description provided for @bluetoothNote.
  ///
  /// In ru, this message translates to:
  /// **'Не отправляет сигнал спасателям'**
  String get bluetoothNote;

  /// No description provided for @dialerUnavailable.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось открыть системный набор номера.'**
  String get dialerUnavailable;

  /// No description provided for @privacy.
  ///
  /// In ru, this message translates to:
  /// **'Конфиденциальность'**
  String get privacy;

  /// No description provided for @permissions.
  ///
  /// In ru, this message translates to:
  /// **'Разрешения'**
  String get permissions;

  /// No description provided for @locationPermission.
  ///
  /// In ru, this message translates to:
  /// **'Геолокация'**
  String get locationPermission;

  /// No description provided for @notifications.
  ///
  /// In ru, this message translates to:
  /// **'Уведомления'**
  String get notifications;

  /// No description provided for @backgroundTasks.
  ///
  /// In ru, this message translates to:
  /// **'Фоновые задачи'**
  String get backgroundTasks;

  /// No description provided for @off.
  ///
  /// In ru, this message translates to:
  /// **'Выключено'**
  String get off;

  /// No description provided for @enabled.
  ///
  /// In ru, this message translates to:
  /// **'Включено'**
  String get enabled;

  /// No description provided for @privacyBody.
  ///
  /// In ru, this message translates to:
  /// **'Сбор датчиков выключен по умолчанию. Маршруты и история не отправляются без отдельного согласия.'**
  String get privacyBody;

  /// No description provided for @changeLanguage.
  ///
  /// In ru, this message translates to:
  /// **'Изменить язык'**
  String get changeLanguage;

  /// No description provided for @version.
  ///
  /// In ru, this message translates to:
  /// **'Версия 0.2.0 · MVP'**
  String get version;

  /// No description provided for @admin.
  ///
  /// In ru, this message translates to:
  /// **'Админ-панель'**
  String get admin;

  /// No description provided for @monthOctober2026.
  ///
  /// In ru, this message translates to:
  /// **'Октябрь 2026'**
  String get monthOctober2026;

  /// No description provided for @comingSoon.
  ///
  /// In ru, this message translates to:
  /// **'Функция пока недоступна'**
  String get comingSoon;

  /// No description provided for @close.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть'**
  String get close;

  /// No description provided for @yandexKeyRequired.
  ///
  /// In ru, this message translates to:
  /// **'Для карты нужен ключ Яндекс MapKit. Без сети доступны история и памятка SOS.'**
  String get yandexKeyRequired;

  /// No description provided for @networkUnavailable.
  ///
  /// In ru, this message translates to:
  /// **'Нет связи с сервером. Данные могут быть недоступны или устаревшими.'**
  String get networkUnavailable;

  /// No description provided for @retry.
  ///
  /// In ru, this message translates to:
  /// **'Повторить'**
  String get retry;

  /// No description provided for @walking.
  ///
  /// In ru, this message translates to:
  /// **'Пешком'**
  String get walking;

  /// No description provided for @driving.
  ///
  /// In ru, this message translates to:
  /// **'На автомобиле'**
  String get driving;

  /// No description provided for @exportTrip.
  ///
  /// In ru, this message translates to:
  /// **'Экспортировать поездку'**
  String get exportTrip;

  /// No description provided for @exportWarning.
  ///
  /// In ru, this message translates to:
  /// **'Файл содержит ваши координаты. Передавайте его только осознанно.'**
  String get exportWarning;

  /// No description provided for @deleteTrip.
  ///
  /// In ru, this message translates to:
  /// **'Удалить поездку'**
  String get deleteTrip;

  /// No description provided for @deleteDay.
  ///
  /// In ru, this message translates to:
  /// **'Удалить выбранный день'**
  String get deleteDay;

  /// No description provided for @eventSource.
  ///
  /// In ru, this message translates to:
  /// **'Источник'**
  String get eventSource;

  /// No description provided for @verified.
  ///
  /// In ru, this message translates to:
  /// **'Подтверждено'**
  String get verified;

  /// No description provided for @eventTime.
  ///
  /// In ru, this message translates to:
  /// **'Время события'**
  String get eventTime;

  /// No description provided for @confidenceValue.
  ///
  /// In ru, this message translates to:
  /// **'Уверенность'**
  String get confidenceValue;

  /// No description provided for @privacyPolicy.
  ///
  /// In ru, this message translates to:
  /// **'Путь хранится локально в зашифрованном виде. Карты, поиск и маршрутизация передают необходимые координаты и запросы Яндексу. Наблюдения отправляются только отдельным действием и округляются сервером до сетки. Отозвать запись можно в настройках; историю можно удалить. Политика для production требует правовой проверки.'**
  String get privacyPolicy;

  /// No description provided for @consentConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Согласиться и начать'**
  String get consentConfirm;

  /// No description provided for @recordingPermission.
  ///
  /// In ru, this message translates to:
  /// **'Разрешить добровольную запись GPS и датчиков'**
  String get recordingPermission;

  /// No description provided for @recordingInterrupted.
  ///
  /// In ru, this message translates to:
  /// **'Запись остановлена: доступ, датчик или состояние приложения изменились. Сохраните результат.'**
  String get recordingInterrupted;

  /// No description provided for @lowBattery.
  ///
  /// In ru, this message translates to:
  /// **'Низкий заряд: запись поставлена на паузу.'**
  String get lowBattery;

  /// No description provided for @alertNearby.
  ///
  /// In ru, this message translates to:
  /// **'Впереди подтверждённый риск. Проверьте источник и время.'**
  String get alertNearby;

  /// No description provided for @privacyUpload.
  ///
  /// In ru, this message translates to:
  /// **'Отправить кандидаты на проверку'**
  String get privacyUpload;

  /// No description provided for @privacyUploadWarning.
  ///
  /// In ru, this message translates to:
  /// **'Отправятся только отдельные геометки кандидатов, время, точность и уверенность. Полный трек не отправляется.'**
  String get privacyUploadWarning;

  /// No description provided for @uploadDone.
  ///
  /// In ru, this message translates to:
  /// **'Наблюдения приняты на проверку. Они ещё не подтверждены.'**
  String get uploadDone;

  /// No description provided for @previousMonth.
  ///
  /// In ru, this message translates to:
  /// **'Предыдущий месяц'**
  String get previousMonth;

  /// No description provided for @nextMonth.
  ///
  /// In ru, this message translates to:
  /// **'Следующий месяц'**
  String get nextMonth;

  /// No description provided for @meters.
  ///
  /// In ru, this message translates to:
  /// **'м'**
  String get meters;

  /// No description provided for @kilometers.
  ///
  /// In ru, this message translates to:
  /// **'км'**
  String get kilometers;

  /// No description provided for @distanceMatrix.
  ///
  /// In ru, this message translates to:
  /// **'Матрица расстояний'**
  String get distanceMatrix;

  /// No description provided for @moderationLogin.
  ///
  /// In ru, this message translates to:
  /// **'Вход модератора: пароль и код 2FA'**
  String get moderationLogin;

  /// No description provided for @password.
  ///
  /// In ru, this message translates to:
  /// **'Пароль'**
  String get password;

  /// No description provided for @otpCode.
  ///
  /// In ru, this message translates to:
  /// **'Код 2FA'**
  String get otpCode;

  /// No description provided for @login.
  ///
  /// In ru, this message translates to:
  /// **'Войти'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In ru, this message translates to:
  /// **'Выйти'**
  String get logout;

  /// No description provided for @approve.
  ///
  /// In ru, this message translates to:
  /// **'Подтвердить'**
  String get approve;

  /// No description provided for @reject.
  ///
  /// In ru, this message translates to:
  /// **'Отклонить'**
  String get reject;

  /// No description provided for @decisionReason.
  ///
  /// In ru, this message translates to:
  /// **'Основание решения (минимум 10 символов)'**
  String get decisionReason;

  /// No description provided for @moderationUnavailable.
  ///
  /// In ru, this message translates to:
  /// **'Модерация недоступна. Нужны настроенные сервером пароль, 2FA и HTTPS.'**
  String get moderationUnavailable;

  /// No description provided for @auditTrail.
  ///
  /// In ru, this message translates to:
  /// **'Журнал решений'**
  String get auditTrail;

  /// No description provided for @sessionSaveFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось открыть или сохранить защищённую историю. Данные не удалены.'**
  String get sessionSaveFailed;

  /// No description provided for @recalculate.
  ///
  /// In ru, this message translates to:
  /// **'Перестроить маршрут'**
  String get recalculate;

  /// No description provided for @showAllDays.
  ///
  /// In ru, this message translates to:
  /// **'Все дни'**
  String get showAllDays;

  /// No description provided for @hiddenRisk.
  ///
  /// In ru, this message translates to:
  /// **'Метка скрыта на этом устройстве'**
  String get hiddenRisk;

  /// No description provided for @knownRisks.
  ///
  /// In ru, this message translates to:
  /// **'Известные риски'**
  String get knownRisks;

  /// No description provided for @createDemoTrip.
  ///
  /// In ru, this message translates to:
  /// **'Добавить демо-поездку'**
  String get createDemoTrip;

  /// No description provided for @demoRoute.
  ///
  /// In ru, this message translates to:
  /// **'Показать пример маршрута'**
  String get demoRoute;

  /// No description provided for @roadClosure.
  ///
  /// In ru, this message translates to:
  /// **'Ограничение прохода'**
  String get roadClosure;

  /// No description provided for @sidewalk.
  ///
  /// In ru, this message translates to:
  /// **'Тротуар'**
  String get sidewalk;

  /// No description provided for @pulseMorning.
  ///
  /// In ru, this message translates to:
  /// **'Утро'**
  String get pulseMorning;

  /// No description provided for @pulseAfternoon.
  ///
  /// In ru, this message translates to:
  /// **'День'**
  String get pulseAfternoon;

  /// No description provided for @pulseEvening.
  ///
  /// In ru, this message translates to:
  /// **'Вечер'**
  String get pulseEvening;

  /// No description provided for @syntheticZone.
  ///
  /// In ru, this message translates to:
  /// **'Демонстрационная ячейка'**
  String get syntheticZone;

  /// No description provided for @syntheticDensity.
  ///
  /// In ru, this message translates to:
  /// **'синтетическая активность, не люди'**
  String get syntheticDensity;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['kk', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'kk':
      return AppLocalizationsKk();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
