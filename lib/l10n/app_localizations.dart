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
  /// **'SAQGO'**
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
  /// **'Демо-карта · геоданные не подключены'**
  String get demoMap;

  /// No description provided for @mapSource.
  ///
  /// In ru, this message translates to:
  /// **'Карта: OpenStreetMap'**
  String get mapSource;

  /// No description provided for @mapUnavailable.
  ///
  /// In ru, this message translates to:
  /// **'Картографический источник ещё не подключён'**
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
  /// **'В этой демонстрационной сессии нет кандидатов. Это не означает, что дорога идеальна.'**
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
  /// **'Начать демо-навигацию'**
  String get startNavigation;

  /// No description provided for @navigation.
  ///
  /// In ru, this message translates to:
  /// **'Навигация'**
  String get navigation;

  /// No description provided for @nextTurn.
  ///
  /// In ru, this message translates to:
  /// **'Следующий поворот неизвестен: карта не подключена'**
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
  /// **'Версия 0.1.0 · MVP'**
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
