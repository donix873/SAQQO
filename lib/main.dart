import 'dart:async';
import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:share_plus/share_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'core/services/consent_service.dart';
import 'core/services/hazard_service.dart';
import 'core/services/route_risk_service.dart';

import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latlong2/latlong.dart' show LatLng;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/colors.dart';
import 'core/theme/radii.dart';
import 'core/theme/shadows.dart';
import 'core/theme/spacing.dart';
import 'core/theme/theme.dart';
import 'core/theme/typography.dart';
import 'core/services/backend_status_service.dart';
import 'core/services/location_service.dart';
import 'core/services/mapkit_initializer.dart';
import 'core/services/lifelog_store.dart';
import 'core/services/routing_service.dart';
import 'core/services/sensor_session_service.dart';
import 'core/services/sensor_candidate_service.dart';
import 'core/services/trip_track_service.dart';
import 'features/map/arqalyk_map.dart';
import 'l10n/app_localizations.dart';

final _homeRouteObserver = RouteObserver<PageRoute<dynamic>>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeMapkit();
  runApp(const SaqgoApp());
}

class SaqgoApp extends StatefulWidget {
  const SaqgoApp({super.key});

  @override
  State<SaqgoApp> createState() => _SaqgoAppState();
}

class _SaqgoAppState extends State<SaqgoApp> {
  Locale _locale = const Locale('ru');
  var _stage = 0;
  var _storageError = false;

  @override
  void initState() {
    super.initState();
    _restoreLaunchState();
    LifeLogStore.restore().catchError((Object _) {
      if (mounted) setState(() => _storageError = true);
    });
    ConsentService.restore();
    HazardService.restorePreferences();
  }

  Future<void> _restoreLaunchState() async {
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getString('saqgo_locale');
    if (!mounted || saved == null) return;
    setState(() {
      _locale = Locale(saved);
      _stage = preferences.getBool('saqgo_onboarding_complete') == true ? 2 : 0;
    });
  }

  void _setLocale(Locale locale) {
    setState(() => _locale = locale);
    SharedPreferences.getInstance().then(
      (preferences) =>
          preferences.setString('saqgo_locale', locale.languageCode),
    );
  }

  Future<void> _restartFirstRun() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove('saqgo_locale');
    await preferences.remove('saqgo_onboarding_complete');
    if (mounted) setState(() => _stage = 0);
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'SaqQo',
    navigatorObservers: [_homeRouteObserver],
    debugShowCheckedModeBanner: false,
    theme: saqgoTheme(),
    locale: _locale,
    supportedLocales: const [Locale('ru'), Locale('kk')],
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    builder: (ctx, child) => _storageError
        ? Column(
            children: [
              SafeArea(
                bottom: false,
                child: Material(
                  color: SaqgoColors.surface,
                  child: ListTile(
                    title: Text(AppLocalizations.of(ctx)!.sessionSaveFailed),
                    trailing: IconButton(
                      tooltip: AppLocalizations.of(ctx)!.retry,
                      onPressed: () async {
                        try {
                          await LifeLogStore.restore();
                          if (mounted) setState(() => _storageError = false);
                        } catch (_) {}
                      },
                      icon: const Icon(Icons.refresh),
                    ),
                  ),
                ),
              ),
              Expanded(child: child ?? const SizedBox()),
            ],
          )
        : child ?? const SizedBox(),
    home: switch (_stage) {
      0 => LanguagePage(
        onLocaleSelected: _setLocale,
        onStarted: () => setState(() => _stage = 1),
      ),
      1 => OnboardingPage(
        onFinished: () async {
          final preferences = await SharedPreferences.getInstance();
          await preferences.setString('saqgo_locale', _locale.languageCode);
          await preferences.setBool('saqgo_onboarding_complete', true);
          if (mounted) setState(() => _stage = 2);
        },
      ),
      _ => HomeShell(
        locale: _locale,
        onLocaleChanged: _setLocale,
        onRestartFirstRun: _restartFirstRun,
      ),
    },
  );
}

class LanguagePage extends StatelessWidget {
  const LanguagePage({
    super.key,
    required this.onLocaleSelected,
    required this.onStarted,
  });
  final ValueChanged<Locale> onLocaleSelected;
  final VoidCallback onStarted;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(SaqgoSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              const BrandMark(size: 72),
              const SizedBox(height: SaqgoSpacing.lg),
              const Text(
                'SaqQo',
                style: TextStyle(
                  fontFamily: "SaqgoSans",
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: SaqgoSpacing.sm),
              Text(l.chooseLanguage, style: SaqgoTypography.title),
              const SizedBox(height: SaqgoSpacing.sm),
              Text(l.languageDescription, style: SaqgoTypography.body),
              const SizedBox(height: SaqgoSpacing.xl),
              FilledButton.tonalIcon(
                onPressed: () => onLocaleSelected(const Locale('kk')),
                icon: const Icon(Icons.language_rounded),
                label: Text(l.kazakh),
                style: _buttonStyle(),
              ),
              const SizedBox(height: SaqgoSpacing.sm),
              FilledButton.tonalIcon(
                onPressed: () => onLocaleSelected(const Locale('ru')),
                icon: const Icon(Icons.language_rounded),
                label: Text(l.russian),
                style: _buttonStyle(),
              ),
              const Spacer(),
              FilledButton(
                onPressed: onStarted,
                style: _buttonStyle(),
                child: Text(l.continueAction),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, required this.onFinished});
  final VoidCallback onFinished;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  var _requestingLocation = false;
  String? _locationMessage;

  Future<void> _enableLocation() async {
    setState(() {
      _requestingLocation = true;
      _locationMessage = null;
    });
    final result = await LocationService().requestCurrentLocation();
    if (!mounted) return;
    setState(() => _requestingLocation = false);
    if (result is LocationAvailable) {
      widget.onFinished();
      return;
    }
    setState(
      () => _locationMessage = AppLocalizations.of(context)!.gpsDisabled,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(SaqgoSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const BrandMark(size: 48),
                      const SizedBox(height: SaqgoSpacing.lg),
                      Text(l.welcomeTitle, style: SaqgoTypography.title),
                      const SizedBox(height: SaqgoSpacing.sm),
                      Text(l.welcomeBody, style: SaqgoTypography.body),
                      const SizedBox(height: SaqgoSpacing.lg),
                      InfoCard(
                        icon: 'hazards',
                        title: l.hazards,
                        body: l.riskDisclaimer,
                      ),
                      const SizedBox(height: SaqgoSpacing.sm),
                      InfoCard(
                        icon: 'privacy',
                        title: l.privacy,
                        body: l.privacyBody,
                      ),
                      const SizedBox(height: SaqgoSpacing.sm),
                      InfoCard(
                        icon: 'no_gps',
                        title: l.locationPermission,
                        body: l.recordingConsent,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: SaqgoSpacing.md),
              FilledButton.icon(
                onPressed: _requestingLocation ? null : _enableLocation,
                style: _buttonStyle(),
                icon: _requestingLocation
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const SaqgoIcon('locate', color: SaqgoColors.navy),
                label: Text(l.enableLocation),
              ),
              if (_locationMessage != null) ...[
                const SizedBox(height: SaqgoSpacing.sm),
                Text(_locationMessage!, style: SaqgoTypography.body),
              ],
              const SizedBox(height: SaqgoSpacing.sm),
              FilledButton(
                onPressed: widget.onFinished,
                style: _buttonStyle(),
                child: Text(l.skip),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.locale,
    required this.onLocaleChanged,
    required this.onRestartFirstRun,
  });
  final Locale locale;
  final ValueChanged<Locale> onLocaleChanged;
  final Future<void> Function() onRestartFirstRun;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with RouteAware {
  var _index = 0;
  var _covered = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute<dynamic>) _homeRouteObserver.subscribe(this, route);
  }

  @override
  void didPushNext() {
    if (mounted) setState(() => _covered = true);
  }

  @override
  void didPopNext() {
    if (mounted) setState(() => _covered = false);
  }

  @override
  void dispose() {
    _homeRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final pages = [
      MapPage(
        active: !_covered && _index == 0,
        onOpenRoutes: () => setState(() => _index = 1),
      ),
      RoutePlannerPage(
        active: !_covered && _index == 1,
        onNavigate: (route) => _push(context, NavigationPage(route: route)),
      ),
      const HistoryPage(),
      SettingsPage(
        locale: widget.locale,
        onLocaleChanged: widget.onLocaleChanged,
        onRestartFirstRun: widget.onRestartFirstRun,
      ),
    ];
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _index, children: pages),
      ),
      floatingActionButton: _index == 0
          ? null
          : FloatingActionButton.small(
              heroTag: 'global-sos',
              tooltip: l.sos,
              onPressed: () => _push(context, const SosPage()),
              backgroundColor: SaqgoColors.sos,
              child: const SaqgoIcon('sos', color: SaqgoColors.navy),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: [
          NavigationDestination(icon: const SaqgoIcon('map'), label: l.map),
          NavigationDestination(
            icon: const SaqgoIcon('route'),
            label: l.routes,
          ),
          NavigationDestination(
            icon: const SaqgoIcon('lifelog'),
            label: l.history,
          ),
          NavigationDestination(
            icon: const SaqgoIcon('settings'),
            label: l.settings,
          ),
        ],
      ),
    );
  }
}

class MapPage extends StatefulWidget {
  const MapPage({super.key, required this.onOpenRoutes, this.active = true});
  final bool active;
  final VoidCallback onOpenRoutes;

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  StreamSubscription<LocationAvailable>? _locationSubscription;
  bool _trackingEnabled = false;
  bool _locationErrorShown = false;
  @override
  void didUpdateWidget(covariant MapPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.active) {
      _locationSubscription?.cancel();
      _locationSubscription = null;
    } else if (!oldWidget.active && _trackingEnabled) {
      _startLocationUpdates();
    }
  }

  void _startLocationUpdates() {
    if (_locationSubscription != null || !widget.active) return;
    _locationSubscription = LocationService().positionUpdates().listen(
      (location) {
        _locationErrorShown = false;
        if (mounted) {
          setState(
            () => _userLocation = LatLng(location.latitude, location.longitude),
          );
        }
      },
      onError: (_) {
        // A temporary provider outage must not stop subsequent GPS updates.
        if (mounted && !_locationErrorShown) {
          _locationErrorShown = true;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.gpsDisabled)),
          );
        }
      },
    );
  }

  @override
  void initState() {
    super.initState();
    final current = LocationService.latest.value;
    if (current != null) {
      _userLocation = LatLng(current.latitude, current.longitude);
      _trackingEnabled = true;
      _startLocationUpdates();
    }
    HazardService.items.addListener(_refresh);
    HazardService.layers.addListener(_refresh);
    HazardService.hidden.addListener(_refresh);
    HazardService.unavailable.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    HazardService.items.removeListener(_refresh);
    HazardService.layers.removeListener(_refresh);
    HazardService.hidden.removeListener(_refresh);
    HazardService.unavailable.removeListener(_refresh);
    super.dispose();
  }

  bool get _presentationScene =>
      HazardService.layers.value['demo'] == true &&
      (kIsWeb
          ? const String.fromEnvironment('YANDEX_JS_API_KEY').isEmpty
          : !isMapkitReady);
  LatLng? _userLocation;

  void _setUserLocation(LocationAvailable location) {
    _trackingEnabled = true;
    _startLocationUpdates();
    setState(
      () => _userLocation = LatLng(location.latitude, location.longitude),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Stack(
      children: [
        Positioned.fill(
          child: widget.active
              ? ArqalykMap(
                  userLocation: _userLocation,
                  hazards: HazardService.visible,
                  onHazardSelected: (hazard) =>
                      _push(context, RiskDetailsPage(hazard: hazard)),
                )
              : const SizedBox.expand(),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(SaqgoSpacing.md),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PointerInterceptor(
                    child: GlassCard(
                      child: Row(
                        children: [
                          const BrandMark(size: 36),
                          const SizedBox(width: SaqgoSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'SaqQo',
                                  style: SaqgoTypography.cardTitle,
                                ),
                                Text(
                                  _presentationScene ? l.demoMap : l.mapSource,
                                  style: SaqgoTypography.label,
                                ),
                              ],
                            ),
                          ),
                          Text(l.arkalyk, style: SaqgoTypography.label),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: SaqgoSpacing.sm),
                  PointerInterceptor(
                    child: Row(
                      children: [
                        IconButton.filledTonal(
                          onPressed: () => _push(context, const SosPage()),
                          icon: const SaqgoIcon('sos', color: SaqgoColors.sos),
                          tooltip: l.sos,
                        ),
                        const Spacer(),
                        IconButton.filledTonal(
                          onPressed: () => _push(context, const LayersPage()),
                          icon: const SaqgoIcon('layers'),
                          tooltip: l.layers,
                        ),
                        const SizedBox(width: SaqgoSpacing.xs),
                        LocateButton(onLocated: _setUserLocation),
                      ],
                    ),
                  ),
                  const Spacer(),
                  PointerInterceptor(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.sizeOf(context).height * 0.42,
                      ),
                      child: SingleChildScrollView(
                        child: GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                HazardService.visible.isEmpty
                                    ? l.noVerifiedRisks
                                    : l.hazards,
                                style: SaqgoTypography.cardTitle,
                              ),
                              const SizedBox(height: SaqgoSpacing.xs),
                              if (HazardService.unavailable.value &&
                                  HazardService.layers.value['demo'] != true)
                                Text(
                                  l.networkUnavailable,
                                  style: SaqgoTypography.body,
                                ),
                              if (HazardService.layers.value['demo'] == true)
                                Text(l.demo, style: SaqgoTypography.label),
                              for (final hazard in HazardService.visible.take(
                                2,
                              ))
                                ListTile(
                                  dense: true,
                                  title: Text(
                                    hazard.demo
                                        ? '${l.demo} · ${_hazardTitle(l, hazard.category)}'
                                        : l.hazards,
                                  ),
                                  onTap: () => _push(
                                    context,
                                    RiskDetailsPage(hazard: hazard),
                                  ),
                                ),
                              TextButton(
                                onPressed: HazardService.refresh,
                                child: Text(l.retry),
                              ),
                              const SizedBox(height: SaqgoSpacing.md),
                              OutlinedButton.icon(
                                onPressed: () => _push(
                                  context,
                                  RiskDetailsPage(
                                    hazard: HazardService.visible.isEmpty
                                        ? null
                                        : HazardService.visible.first,
                                  ),
                                ),
                                icon: const SaqgoIcon('hazards'),
                                label: Text(l.hazards),
                              ),
                              TextButton.icon(
                                onPressed: () =>
                                    _push(context, const PulsePage()),
                                icon: const SaqgoIcon('pulse'),
                                label: Text(l.livePulse),
                              ),
                              const SizedBox(height: SaqgoSpacing.sm),
                              Row(
                                children: [
                                  Expanded(
                                    child: FilledButton.icon(
                                      onPressed: widget.onOpenRoutes,
                                      icon: const SaqgoIcon(
                                        'route',
                                        color: SaqgoColors.navy,
                                      ),
                                      label: Text(l.route),
                                    ),
                                  ),
                                  const SizedBox(width: SaqgoSpacing.sm),
                                  IconButton.filled(
                                    onPressed: () =>
                                        _push(context, const RecordingPage()),
                                    icon: const SaqgoIcon(
                                      'sensors',
                                      color: SaqgoColors.navy,
                                    ),
                                    tooltip: l.scan,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class LayersPage extends StatefulWidget {
  const LayersPage({super.key});
  @override
  State<LayersPage> createState() => _LayersPageState();
}

class _LayersPageState extends State<LayersPage> {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SaqgoScaffold(
      title: l.layers,
      child: ListView(
        children: [
          Text(
            HazardService.layers.value['demo'] == true
                ? l.sourceDemo
                : l.eventSource,
            style: SaqgoTypography.body,
          ),
          const SizedBox(height: SaqgoSpacing.md),
          for (final entry in HazardService.layers.value.entries)
            GlassCard(
              margin: const EdgeInsets.only(bottom: SaqgoSpacing.sm),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_layerText(l, entry.key)),
                value: entry.value,
                onChanged: (value) =>
                    setState(() => HazardService.toggle(entry.key, value)),
              ),
            ),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.sourceQuality, style: SaqgoTypography.cardTitle),
                const SizedBox(height: SaqgoSpacing.xs),
                Text(
                  HazardService.layers.value['demo'] == true
                      ? l.sourceDemo
                      : l.eventSource,
                  style: SaqgoTypography.body,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _layerText(AppLocalizations l, String key) => switch (key) {
    'road_bump' => l.roadBumps,
    'ice' => l.potentialIce,
    'closure' => l.hazards,
    'sidewalk' => l.walking,
    'demo' => l.demo,
    _ => l.onlyVerified,
  };
}

class RiskDetailsPage extends StatelessWidget {
  const RiskDetailsPage({super.key, this.hazard});
  final Hazard? hazard;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SaqgoScaffold(
      title: hazard == null ? l.hazards : _hazardTitle(l, hazard!.category),
      child: ListView(
        children: [
          SizedBox(
            height: 190,
            child: ArqalykMap(hazards: hazard == null ? const [] : [hazard!]),
          ),
          if (hazard?.demo == true)
            Text(l.demo, style: SaqgoTypography.cardTitle),
          const SizedBox(height: SaqgoSpacing.md),
          RiskChip(
            text: hazard?.status == 'verified' ? l.verified : l.unverified,
          ),
          const SizedBox(height: SaqgoSpacing.md),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hazard == null
                      ? l.insufficientData
                      : '${l.confidenceValue}: ${(hazard!.confidence * 100).round()}%',
                  style: SaqgoTypography.cardTitle,
                ),
                const SizedBox(height: SaqgoSpacing.xs),
                Text(
                  '${l.eventSource}: ${hazard?.demo == true ? l.demo : hazard?.source ?? l.insufficientData}',
                ),
                Text(
                  hazard?.updatedAt == null
                      ? l.lastUpdated
                      : '${l.eventTime}: ${MaterialLocalizations.of(context).formatMediumDate(hazard!.updatedAt!.toLocal())}',
                ),
                if (hazard != null)
                  Text(
                    '${l.accuracy}: ${hazard!.accuracyMeters.round()} ${l.meters}',
                  ),
                const SizedBox(height: SaqgoSpacing.md),
                FilledButton.icon(
                  onPressed: () => _push(context, const RoutePlannerPage()),
                  icon: const SaqgoIcon('route', color: SaqgoColors.navy),
                  label: Text(l.openRoute),
                ),
                TextButton(
                  onPressed: () {
                    if (hazard != null) HazardService.hide(hazard!.id);
                    Navigator.of(context).pop();
                  },
                  child: Text(l.hideMarker),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RecordingPage extends StatefulWidget {
  const RecordingPage({super.key});
  @override
  State<RecordingPage> createState() => _RecordingPageState();
}

enum RecordingState { idle, active, paused }

class _RecordingPageState extends State<RecordingPage>
    with WidgetsBindingObserver {
  RecordingState _state = RecordingState.idle;
  final _session = SensorSessionService();
  final _track = TripTrackService();
  var _candidateCount = 0;
  final _recordedCandidates = <StoredCandidate>[];
  LocationAvailable? _latestLocation;
  DateTime? _latestLocationAt;
  StreamSubscription<VibrationCandidate>? _candidateSubscription;
  Timer? _batteryCheck;
  StreamSubscription<ServiceStatus>? _serviceSubscription;
  bool _transitioning = false;
  StreamSubscription<LocationAvailable>? _positionSubscription;
  double? _gpsAccuracyMeters;
  DateTime? _startedAt;
  DateTime? _activeSince;
  Duration _elapsed = Duration.zero;
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ConsentService.recording.addListener(_consentChanged);
    _candidateSubscription = _session.candidates.listen((candidate) {
      final location = _latestLocation;
      if (_state != RecordingState.active ||
          location == null ||
          location.accuracyMeters > 65 ||
          _latestLocationAt == null ||
          DateTime.now().difference(_latestLocationAt!).inSeconds > 15 ||
          _recordedCandidates.length >= 1000) {
        return;
      }
      _recordedCandidates.add(
        StoredCandidate(
          timestamp: candidate.timestamp,
          confidence: candidate.confidence,
          accuracyMeters: location.accuracyMeters,
          latitude: location.latitude,
          longitude: location.longitude,
        ),
      );
      if (mounted) setState(() => _candidateCount++);
    }, onError: (Object _) => _interrupt());
    try {
      _serviceSubscription = Geolocator.getServiceStatusStream().listen((
        status,
      ) {
        if (status == ServiceStatus.disabled) _interrupt();
      }, onError: (Object _) => _interrupt());
    } catch (_) {}
    _batteryCheck = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (_state != RecordingState.active) return;
      try {
        if (await Battery().batteryLevel <= 15) _interrupt(lowBattery: true);
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ConsentService.recording.removeListener(_consentChanged);
    _candidateSubscription?.cancel();
    _batteryCheck?.cancel();
    _serviceSubscription?.cancel();
    _clock?.cancel();
    _positionSubscription?.cancel();
    _session.dispose();
    super.dispose();
  }

  void _consentChanged() {
    if (!ConsentService.recording.value) _interrupt();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _interrupt();
  }

  Future<void> _interrupt({bool lowBattery = false}) async {
    if (_state != RecordingState.active) return;
    await _session.pause();
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _track.pause();
    _pauseClock();
    if (mounted) {
      setState(() => _state = RecordingState.paused);
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(lowBattery ? l.lowBattery : l.recordingInterrupted),
        ),
      );
    }
  }

  Future<void> _toggle() async {
    if (_transitioning) return;
    setState(() => _transitioning = true);
    try {
      if (_state == RecordingState.active) {
        await _interrupt();
        return;
      }
      final l = AppLocalizations.of(context)!;
      if (!ConsentService.recording.value) {
        final accepted = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l.recordingPermission),
            content: Text(l.recordingConsent),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l.consentConfirm),
              ),
            ],
          ),
        );
        if (accepted != true) return;
        await ConsentService.setRecording(true);
      }
      final location = await LocationService().requestCurrentLocation();
      if (!mounted) return;
      if (location is! LocationAvailable || location.accuracyMeters > 65) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.gpsDisabled)));
        return;
      }
      if (_state == RecordingState.paused) {
        _track.resume();
      } else {
        _track.start();
      }
      _startedAt ??= DateTime.now();
      _activeSince = DateTime.now();
      setState(() => _state = RecordingState.active);
      _addLocationSample(location);
      _positionSubscription = LocationService().positionUpdates().listen(
        _addLocationSample,
        onError: (Object _) => _interrupt(),
      );
      await _session.start();
      _clock = Timer.periodic(const Duration(seconds: 1), (_) async {
        if (!mounted) return;
        setState(() {});
        if (!await LocationService().hasLocationPermission()) _interrupt();
      });
    } catch (_) {
      await _interrupt();
    } finally {
      if (mounted) setState(() => _transitioning = false);
    }
  }

  Future<void> _finish() async {
    await _session.stop();
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _pauseClock();
    final track = _track.stop();
    final record = TripRecord(
      id: '${_startedAt!.microsecondsSinceEpoch}',
      startedAt: _startedAt!,
      duration: _elapsed,
      candidateCount: _candidateCount,
      candidates: List.unmodifiable(_recordedCandidates),
      distanceMeters: track.distanceMeters,
      trackPointCount: track.points.length,
      trackPoints: track.points
          .map(
            (point) => StoredTrackPoint(
              latitude: point.latitude,
              longitude: point.longitude,
              accuracyMeters: point.accuracyMeters,
              recordedAt: point.recordedAt,
              segmentStart: point.segmentStart,
            ),
          )
          .toList(growable: false),
    );
    if (mounted) _pushReplacement(context, TripResultPage(record: record));
  }

  void _addLocationSample(LocationAvailable location) {
    if (_track.isFull) {
      _interrupt();
      return;
    }
    _latestLocation = location;
    _latestLocationAt = DateTime.now();
    _track.addSample(
      latitude: location.latitude,
      longitude: location.longitude,
      accuracyMeters: location.accuracyMeters,
      recordedAt: DateTime.now(),
    );
    if (mounted) {
      setState(() => _gpsAccuracyMeters = location.accuracyMeters);
    }
  }

  void _pauseClock() {
    if (_activeSince != null) {
      _elapsed += DateTime.now().difference(_activeSince!);
    }
    _activeSince = null;
    _clock?.cancel();
    _clock = null;
  }

  Duration get _displayedDuration => _activeSince == null
      ? _elapsed
      : _elapsed + DateTime.now().difference(_activeSince!);

  String get _durationText {
    final value = _displayedDuration;
    final minutes = value.inMinutes.toString().padLeft(2, '0');
    final seconds = (value.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final status = switch (_state) {
      RecordingState.idle => l.recordingNotStarted,
      RecordingState.active => l.recordingActive,
      RecordingState.paused => l.recordingPaused,
    };
    return SaqgoScaffold(
      title: l.recording,
      child: ListView(
        children: [
          Text(l.recordingConsent, style: SaqgoTypography.body),
          const SizedBox(height: SaqgoSpacing.md),
          GlassCard(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Metric(label: l.duration, value: _durationText),
                    Metric(label: l.candidates, value: '$_candidateCount'),
                  ],
                ),
                const SizedBox(height: SaqgoSpacing.lg),
                const SignalLine(),
                const SizedBox(height: SaqgoSpacing.sm),
                Text(l.demo, style: SaqgoTypography.label),
              ],
            ),
          ),
          const SizedBox(height: SaqgoSpacing.md),
          GlassCard(
            child: Row(
              children: [
                SaqgoIcon(
                  _gpsAccuracyMeters == null ? 'no_gps' : 'locate',
                  color: SaqgoColors.cyan,
                ),
                const SizedBox(width: SaqgoSpacing.sm),
                Text(
                  _gpsAccuracyMeters == null
                      ? l.gpsDisabled
                      : '${l.locationPermission}: ${_gpsAccuracyMeters!.round()} m',
                  style: SaqgoTypography.cardTitle,
                ),
              ],
            ),
          ),
          const SizedBox(height: SaqgoSpacing.md),
          Text(status, style: SaqgoTypography.body),
          const SizedBox(height: SaqgoSpacing.md),
          FilledButton.icon(
            onPressed: _transitioning ? null : _toggle,
            icon: SaqgoIcon(
              _state == RecordingState.active ? 'pause' : 'play',
              color: SaqgoColors.navy,
            ),
            label: Text(
              _state == RecordingState.active
                  ? l.pause
                  : _state == RecordingState.paused
                  ? l.resume
                  : l.startRecording,
            ),
          ),
          const SizedBox(height: SaqgoSpacing.sm),
          OutlinedButton.icon(
            onPressed: _state == RecordingState.idle || _transitioning
                ? null
                : _finish,
            icon: const SaqgoIcon('stop'),
            label: Text(l.stop),
          ),
          const SizedBox(height: SaqgoSpacing.lg),
          Text(l.sensorsNotDiagnose, style: SaqgoTypography.body),
        ],
      ),
    );
  }
}

class TripResultPage extends StatelessWidget {
  const TripResultPage({super.key, required this.record});
  final TripRecord record;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SaqgoScaffold(
      title: l.tripResult,
      child: ListView(
        children: [
          SizedBox(
            height: 200,
            child: ArqalykMap(
              routePoints: record.routePoints,
              routeSegments: record.routeSegments,
            ),
          ),
          const SizedBox(height: SaqgoSpacing.md),
          CandidateSummary(record: record),
          const SizedBox(height: SaqgoSpacing.md),
          FilledButton(
            onPressed: () async {
              try {
                await LifeLogStore.add(record);
                if (context.mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(l.sessionSaveFailed)));
                }
              }
            },
            child: Text(l.saveLocal),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            child: Text(l.delete),
          ),
        ],
      ),
    );
  }
}

class RoutePlannerPage extends StatefulWidget {
  const RoutePlannerPage({super.key, this.onNavigate, this.active = true});
  final bool active;
  final ValueChanged<RouteResult>? onNavigate;

  @override
  State<RoutePlannerPage> createState() => _RoutePlannerPageState();
}

class _RoutePlannerPageState extends State<RoutePlannerPage> {
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final _routing = RoutingService();
  String _mode = "walking";
  bool _demoRoute = false;
  PlaceResult? _from;
  PlaceResult? _to;
  List<RouteResult> _routes = const [];
  var _selectedRoute = 0;
  var _loading = false;

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  Future<void> _useMyLocation() async {
    setState(() => _loading = true);
    final location = await LocationService().requestCurrentLocation();
    if (!mounted) return;
    if (location is LocationAvailable) {
      setState(() {
        _from = PlaceResult(
          name:
              'GPS ${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)}',
          position: LatLng(location.latitude, location.longitude),
        );
        _fromController.text = _from!.name;
        _routes = const [];
      });
    } else {
      _showMessage(AppLocalizations.of(context)!.gpsDisabled);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _findPlace({required bool from}) async {
    final controller = from ? _fromController : _toController;
    setState(() => _loading = true);
    final place = await _routing.searchPlace(controller.text);
    if (!mounted) return;
    if (place == null) {
      _showMessage(AppLocalizations.of(context)!.routeUnavailable);
    } else {
      setState(() {
        if (from) {
          _from = place;
        } else {
          _to = place;
        }
        controller.text = place.name;
        _routes = const [];
      });
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _buildRoute() async {
    final l = AppLocalizations.of(context)!;
    if (_loading) return;
    if (_fromController.text.trim().isEmpty ||
        _toController.text.trim().isEmpty) {
      _showMessage(l.enterStartAndEnd);
      return;
    }
    setState(() => _loading = true);
    final places = await Future.wait([
      _from != null
          ? Future.value(_from)
          : _routing.searchPlace(_fromController.text),
      _to != null
          ? Future.value(_to)
          : _routing.searchPlace(_toController.text),
    ]);
    if (!mounted) return;
    if (places.any((place) => place == null)) {
      setState(() => _loading = false);
      _showMessage(l.routeUnavailable);
      return;
    }
    setState(() {
      _from = places[0];
      _to = places[1];
      _fromController.text = _from!.name;
      _toController.text = _to!.name;
    });
    final routes = List<RouteResult>.of(
      await _routing.buildRoutes(
        from: _from!.position,
        to: _to!.position,
        mode: _mode,
      ),
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _demoRoute = false;
      routes.sort((a, b) => a.duration.compareTo(b.duration));
      _routes = routes;
      _selectedRoute = 0;
    });
    _showMessage(routes.isEmpty ? l.routeUnavailable : l.routeReady);
  }

  void _showMessage(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SaqgoScaffold(
      title: l.routePlanner,
      child: ListView(
        children: [
          SegmentedButton<String>(
            segments: [
              ButtonSegment(
                value: 'walking',
                label: Text(l.walking),
                icon: const Icon(Icons.directions_walk),
              ),
              ButtonSegment(
                value: 'driving',
                label: Text(l.driving),
                icon: const Icon(Icons.directions_car),
              ),
            ],
            selected: {_mode},
            onSelectionChanged: _loading
                ? null
                : (values) => setState(() {
                    _mode = values.first;
                    _routes = [];
                  }),
          ),
          if (HazardService.layers.value['demo'] == true)
            TextButton(
              onPressed: () => setState(() {
                _demoRoute = true;
                _fromController.text = l.testPointA;
                _toController.text = l.testPointB;
                _selectedRoute = 0;
                _routes = [
                  const RouteResult(
                    points: [
                      LatLng(50.2486, 66.9203),
                      LatLng(50.250, 66.922),
                      LatLng(50.252, 66.924),
                    ],
                    distanceMeters: 1200,
                    duration: Duration(minutes: 12),
                    demo: true,
                  ),
                ];
              }),
              child: Text(l.demoRoute),
            ),
          if (_demoRoute) Text(l.demoMap, style: SaqgoTypography.label),
          const SizedBox(height: SaqgoSpacing.md),
          TextField(
            controller: _fromController,
            decoration: InputDecoration(
              labelText: l.from,
              suffixIcon: IconButton(
                tooltip: l.findPlace,
                onPressed: _loading ? null : () => _findPlace(from: true),
                icon: const Icon(Icons.search),
              ),
            ),
            onChanged: (_) => _from = null,
          ),
          const SizedBox(height: SaqgoSpacing.sm),
          TextField(
            controller: _toController,
            decoration: InputDecoration(
              labelText: l.to,
              suffixIcon: IconButton(
                tooltip: l.findPlace,
                onPressed: _loading ? null : () => _findPlace(from: false),
                icon: const Icon(Icons.search),
              ),
            ),
            onChanged: (_) => _to = null,
          ),
          const SizedBox(height: SaqgoSpacing.sm),
          Wrap(
            spacing: SaqgoSpacing.sm,
            runSpacing: SaqgoSpacing.sm,
            children: [
              OutlinedButton.icon(
                onPressed: _loading ? null : _useMyLocation,
                icon: const SaqgoIcon('locate'),
                label: Text(l.useMyLocation),
              ),
              FilledButton.icon(
                onPressed: _loading ? null : _buildRoute,
                icon: _loading
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const SaqgoIcon('route', color: SaqgoColors.navy),
                label: Text(l.buildRoute),
              ),
            ],
          ),
          const SizedBox(height: SaqgoSpacing.md),
          SizedBox(
            height: 220,
            child: widget.active
                ? ArqalykMap(
                    routePoints: _routes.isEmpty
                        ? const []
                        : _routes[_selectedRoute].points,
                  )
                : const SizedBox.expand(),
          ),
          const SizedBox(height: SaqgoSpacing.md),
          for (var index = 0; index < _routes.length; index++)
            Padding(
              padding: const EdgeInsets.only(bottom: SaqgoSpacing.sm),
              child: RouteChoice(
                title: index == 0
                    ? l.faster
                    : RouteRiskService.knownRisks(
                            _routes[index].points,
                            HazardService.items.value,
                          ) <
                          RouteRiskService.knownRisks(
                            _routes.first.points,
                            HazardService.items.value,
                          )
                    ? l.lessKnownRisk
                    : l.alternativeRoute,
                riskCount: RouteRiskService.knownRisks(
                  _routes[index].points,
                  HazardService.items.value,
                ),
                duration: _durationLabel(_routes[index].duration),
                distance: _distanceLabel(_routes[index].distanceMeters, l),
                selected: _selectedRoute == index,
                onTap: () => setState(() => _selectedRoute = index),
              ),
            ),
          const SizedBox(height: SaqgoSpacing.md),
          Text(l.insufficientData, style: SaqgoTypography.label),
          const SizedBox(height: SaqgoSpacing.md),
          FilledButton.icon(
            onPressed: _routes.isEmpty
                ? null
                : () {
                    final route = _routes[_selectedRoute];
                    if (widget.onNavigate != null) {
                      widget.onNavigate!(route);
                    } else {
                      _push(context, NavigationPage(route: route));
                    }
                  },
            icon: const SaqgoIcon('route', color: SaqgoColors.navy),
            label: Text(l.startNavigation),
          ),
        ],
      ),
    );
  }
}

class NavigationPage extends StatefulWidget {
  const NavigationPage({super.key, required this.route});
  final RouteResult route;

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  final _hazardAlerts = HazardAlertService();
  StreamSubscription<LocationAvailable>? _locationSubscription;
  LatLng? _userLocation;

  @override
  void initState() {
    super.initState();
    if (!widget.route.demo) unawaited(_startPositionTracking());
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _startPositionTracking() async {
    final service = LocationService();
    final current = await service.requestCurrentLocation();
    if (!mounted) return;
    if (current is LocationAvailable) {
      _setPosition(current);
      _locationSubscription = service.positionUpdates().listen(
        _setPosition,
        onError: (_) {},
      );
    }
  }

  void _setPosition(LocationAvailable location) {
    if (mounted && ConsentService.alerts.value) {
      final alerts = _hazardAlerts.update(
        LatLng(location.latitude, location.longitude),
        location.accuracyMeters,
        DateTime.now(),
        HazardService.visible,
      );
      if (alerts.isNotEmpty) {
        final l = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l.alertNearby} ${alerts.first.source}'),
            action: SnackBarAction(
              label: l.hazards,
              onPressed: () =>
                  _push(context, RiskDetailsPage(hazard: alerts.first)),
            ),
          ),
        );
      }
    }
    if (mounted) {
      setState(
        () => _userLocation = LatLng(location.latitude, location.longitude),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SaqgoScaffold(
      title: l.navigation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ArqalykMap(
              routePoints: widget.route.points,
              userLocation: _userLocation,
              hazards: HazardService.visible,
            ),
          ),
          const SizedBox(height: SaqgoSpacing.md),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.route.demo ? l.demoMap : l.nextTurn,
                  style: SaqgoTypography.cardTitle,
                ),
                const SizedBox(height: SaqgoSpacing.xs),
                Text(l.insufficientData, style: SaqgoTypography.label),
              ],
            ),
          ),
          const SizedBox(height: SaqgoSpacing.md),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l.endNavigation),
          ),
        ],
      ),
    );
  }
}

class PulsePage extends StatefulWidget {
  const PulsePage({super.key});
  @override
  State<PulsePage> createState() => _PulsePageState();
}

class _PulsePageState extends State<PulsePage> {
  int _period = 1;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SaqgoScaffold(
      title: l.pulseTitle,
      child: ListView(
        children: [
          Chip(label: Text(l.demo), avatar: const Icon(Icons.science_outlined)),
          const SizedBox(height: SaqgoSpacing.sm),
          const PulseGrid(),
          const SizedBox(height: SaqgoSpacing.md),
          SegmentedButton<int>(
            segments: [
              ButtonSegment(value: 0, label: Text(l.pulseMorning)),
              ButtonSegment(value: 1, label: Text(l.pulseAfternoon)),
              ButtonSegment(value: 2, label: Text(l.pulseEvening)),
            ],
            selected: {_period},
            onSelectionChanged: (values) =>
                setState(() => _period = values.first),
          ),
          const SizedBox(height: SaqgoSpacing.md),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.syntheticZone, style: SaqgoTypography.cardTitle),
                const SizedBox(height: 8),
                Text(
                  '${l.demo}: ${[12, 24, 18][_period]} · ${l.syntheticDensity}',
                  style: SaqgoTypography.body,
                ),
              ],
            ),
          ),
          const SizedBox(height: SaqgoSpacing.md),
          GlassCard(child: Text(l.pulseBody, style: SaqgoTypography.body)),
        ],
      ),
    );
  }
}

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});
  Future<void> _confirmDelete(BuildContext context) =>
      _HistoryPageState.confirmDelete(context);
  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  DateTime? _selectedDay;
  @override
  void initState() {
    super.initState();
    HazardService.layers.addListener(_changed);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    HazardService.layers.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SaqgoScaffold(
      title: l.lifelog,
      child: ListView(
        children: [
          Text(l.localOnly, style: SaqgoTypography.body),
          if (HazardService.layers.value['demo'] == true)
            TextButton.icon(
              onPressed: () async {
                final now = DateTime.now();
                final sample = TripRecord(
                  id: 'demo-${now.microsecondsSinceEpoch}',
                  startedAt: now,
                  duration: const Duration(minutes: 12),
                  candidateCount: 1,
                  distanceMeters: 1200,
                  trackPointCount: 3,
                  demo: true,
                  trackPoints: const [
                    StoredTrackPoint(latitude: 50.2486, longitude: 66.9203),
                    StoredTrackPoint(latitude: 50.250, longitude: 66.922),
                    StoredTrackPoint(latitude: 50.252, longitude: 66.924),
                  ],
                  candidates: [
                    StoredCandidate(
                      timestamp: now,
                      confidence: .4,
                      accuracyMeters: 20,
                      latitude: 50.250,
                      longitude: 66.922,
                    ),
                  ],
                );
                try {
                  await LifeLogStore.add(sample);
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l.sessionSaveFailed)),
                    );
                  }
                }
              },
              icon: const Icon(Icons.add),
              label: Text(l.createDemoTrip),
            ),
          const SizedBox(height: SaqgoSpacing.md),
          ValueListenableBuilder<List<TripRecord>>(
            valueListenable: LifeLogStore.trips,
            builder: (context, trips, _) => Column(
              children: [
                CalendarCard(
                  trips: trips,
                  onDaySelected: (date) => setState(() => _selectedDay = date),
                ),
                if (_selectedDay != null)
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton(
                        onPressed: () => setState(() => _selectedDay = null),
                        child: Text(l.showAllDays),
                      ),
                      TextButton(
                        onPressed: () async {
                          if (await _confirmAction(
                            context,
                            l.deleteDay,
                            l.deleteHistoryBody,
                          )) {
                            await LifeLogStore.removeDay(_selectedDay!);
                            if (mounted) setState(() => _selectedDay = null);
                          }
                        },
                        child: Text(l.deleteDay),
                      ),
                    ],
                  ),
                const SizedBox(height: SaqgoSpacing.md),
                if (trips.isEmpty)
                  EmptyState(
                    icon: 'empty_data',
                    message: l.emptyHistory,
                    onAction: () => _push(context, const RecordingPage()),
                    actionLabel: l.startRecording,
                  )
                else
                  for (final trip in trips.where(
                    (trip) =>
                        _selectedDay == null ||
                        DateUtils.isSameDay(trip.startedAt, _selectedDay),
                  ))
                    Padding(
                      padding: const EdgeInsets.only(bottom: SaqgoSpacing.sm),
                      child: TripCard(
                        record: trip,
                        onOpen: () =>
                            _push(context, SessionDetailsPage(record: trip)),
                      ),
                    ),
                const SizedBox(height: SaqgoSpacing.md),
                OutlinedButton.icon(
                  onPressed: trips.isNotEmpty
                      ? () => confirmDelete(context)
                      : null,
                  icon: const SaqgoIcon('delete', color: SaqgoColors.sos),
                  label: Text(l.deleteHistory),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> confirmDelete(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.deleteHistory),
        content: Text(l.deleteHistoryBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () async {
              await LifeLogStore.clear();
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: Text(l.confirmDelete),
          ),
        ],
      ),
    );
  }
}

class SessionDetailsPage extends StatelessWidget {
  const SessionDetailsPage({super.key, required this.record});
  final TripRecord record;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SaqgoScaffold(
      title: l.sessionDetails,
      child: ListView(
        children: [
          if (record.demo) Text(l.demo, style: SaqgoTypography.cardTitle),
          SizedBox(
            height: 240,
            child: ArqalykMap(
              routePoints: record.routePoints,
              routeSegments: record.routeSegments,
            ),
          ),
          const SizedBox(height: SaqgoSpacing.md),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  MaterialLocalizations.of(
                    context,
                  ).formatMediumDate(record.startedAt),
                  style: SaqgoTypography.cardTitle,
                ),
                const SizedBox(height: SaqgoSpacing.xs),
                Text(
                  '${_durationLabel(record.duration)} · ${_distanceLabel(record.distanceMeters, l)} · ${record.candidateCount} ${l.candidates.toLowerCase()}',
                  style: SaqgoTypography.body,
                ),
              ],
            ),
          ),
          const SizedBox(height: SaqgoSpacing.md),
          CandidateSummary(record: record),
          const SizedBox(height: SaqgoSpacing.md),
          FilledButton.icon(
            onPressed: () => _exportTrip(context, record),
            icon: const Icon(Icons.ios_share),
            label: Text(l.exportTrip),
          ),
          TextButton.icon(
            onPressed: () async {
              final accepted = await _confirmAction(
                context,
                l.deleteTrip,
                l.deleteHistoryBody,
              );
              if (accepted) {
                await LifeLogStore.remove(record.id);
                if (context.mounted) Navigator.pop(context);
              }
            },
            icon: const SaqgoIcon('delete'),
            label: Text(l.deleteTrip),
          ),
        ],
      ),
    );
  }
}

class SosPage extends StatefulWidget {
  const SosPage({super.key});

  @override
  State<SosPage> createState() => _SosPageState();
}

class _SosPageState extends State<SosPage> {
  LocationAvailable? _location;
  var _loadingLocation = false;
  DateTime? _locationAt;

  @override
  void initState() {
    super.initState();
    LocationService().hasLocationPermission().then((enabled) {
      if (enabled && mounted) _refreshLocation();
    });
  }

  Future<void> _refreshLocation() async {
    setState(() => _loadingLocation = true);
    final result = await LocationService().requestCurrentLocation();
    if (!mounted) return;
    setState(() {
      _loadingLocation = false;
      _location = result is LocationAvailable ? result : null;
      _locationAt = _location == null ? null : DateTime.now();
    });
  }

  Future<void> _copyCoordinates() async {
    final location = _location;
    if (location == null) return;
    await Clipboard.setData(
      ClipboardData(
        text:
            '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
      ),
    );
    if (mounted) {
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.coordinatesCopied)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SaqgoScaffold(
      title: l.sos,
      child: ListView(
        children: [
          const Center(child: BrandMark(size: 76, sos: true)),
          const SizedBox(height: SaqgoSpacing.md),
          const Center(
            child: Text(
              '112',
              style: TextStyle(
                fontFamily: "SaqgoSans",
                fontSize: 58,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: SaqgoSpacing.md),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.currentCoordinates, style: SaqgoTypography.cardTitle),
                const SizedBox(height: SaqgoSpacing.xs),
                Text(
                  _location == null
                      ? l.coordinatesUnavailable
                      : '${_location!.latitude.toStringAsFixed(6)}, ${_location!.longitude.toStringAsFixed(6)}',
                  style: SaqgoTypography.body,
                ),
                if (_locationAt != null)
                  Text(
                    '${l.eventTime}: ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(_locationAt!))}',
                  ),
                if (_location != null) ...[
                  const SizedBox(height: SaqgoSpacing.xs),
                  Text(
                    '${l.accuracy}: ${_location!.accuracyMeters.round()} ${l.meters}',
                    style: SaqgoTypography.label,
                  ),
                ],
                const SizedBox(height: SaqgoSpacing.sm),
                Wrap(
                  spacing: SaqgoSpacing.sm,
                  runSpacing: SaqgoSpacing.sm,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _loadingLocation ? null : _refreshLocation,
                      icon: _loadingLocation
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const SaqgoIcon('locate'),
                      label: Text(l.refreshLocation),
                    ),
                    OutlinedButton.icon(
                      onPressed: _location == null ? null : _copyCoordinates,
                      icon: const Icon(Icons.copy_outlined),
                      label: Text(l.copyCoordinates),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: SaqgoSpacing.md),
          FilledButton.icon(
            onPressed: () => _call112(context),
            icon: const SaqgoIcon('phone', color: SaqgoColors.navy),
            label: Text(l.call112),
            style: _buttonStyle(
              background: SaqgoColors.sos,
              foreground: SaqgoColors.navy,
            ),
          ),
          const SizedBox(height: SaqgoSpacing.sm),
          Center(child: Text(l.opensDialer, style: SaqgoTypography.label)),
          const SizedBox(height: SaqgoSpacing.md),
          GlassCard(
            child: Row(
              children: [
                const SaqgoIcon('no_internet'),
                const SizedBox(width: SaqgoSpacing.sm),
                Expanded(
                  child: Text(l.networkNeeded, style: SaqgoTypography.body),
                ),
              ],
            ),
          ),
          const SizedBox(height: SaqgoSpacing.lg),
          Text(l.duringCall, style: SaqgoTypography.title),
          const SizedBox(height: SaqgoSpacing.md),
          for (final step in [l.callStep1, l.callStep2, l.callStep3])
            Padding(
              padding: const EdgeInsets.only(bottom: SaqgoSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: SaqgoColors.surfaceMuted,
                    child: Text(
                      '${[l.callStep1, l.callStep2, l.callStep3].indexOf(step) + 1}',
                      style: const TextStyle(
                        fontFamily: "SaqgoSans",
                        color: SaqgoColors.cyan,
                      ),
                    ),
                  ),
                  const SizedBox(width: SaqgoSpacing.sm),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(step),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: SaqgoSpacing.md),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.bluetoothResearch, style: SaqgoTypography.cardTitle),
                const SizedBox(height: SaqgoSpacing.xs),
                Text(l.bluetoothNote, style: SaqgoTypography.body),
              ],
            ),
          ),
          const SizedBox(height: SaqgoSpacing.md),
          Text(l.notAutoSent, style: SaqgoTypography.body),
        ],
      ),
    );
  }

  Future<void> _call112(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    final opened = await launchUrl(Uri(scheme: 'tel', path: '112'));
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.dialerUnavailable)));
    }
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.locale,
    required this.onLocaleChanged,
    required this.onRestartFirstRun,
  });
  final Locale locale;
  final ValueChanged<Locale> onLocaleChanged;
  final Future<void> Function() onRestartFirstRun;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  var _locationEnabled = false;
  var _checkingLocation = true;

  @override
  void initState() {
    super.initState();
    unawaited(_refreshLocationPermission());
  }

  Future<void> _refreshLocationPermission() async {
    final enabled = await LocationService().hasLocationPermission();
    if (mounted) {
      setState(() {
        _locationEnabled = enabled;
        _checkingLocation = false;
      });
    }
  }

  Future<void> _enableLocation() async {
    setState(() => _checkingLocation = true);
    await LocationService().requestCurrentLocation();
    await _refreshLocationPermission();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SaqgoScaffold(
      title: l.settings,
      child: ListView(
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.privacy, style: SaqgoTypography.cardTitle),
                const SizedBox(height: SaqgoSpacing.xs),
                Text(l.privacyPolicy, style: SaqgoTypography.body),
              ],
            ),
          ),
          const SizedBox(height: SaqgoSpacing.md),
          SettingsTile(
            icon: 'no_gps',
            title: l.locationPermission,
            subtitle: _checkingLocation
                ? l.comingSoon
                : _locationEnabled
                ? l.enabled
                : l.off,
            onTap: _checkingLocation ? null : _enableLocation,
          ),
          ValueListenableBuilder<bool>(
            valueListenable: ConsentService.alerts,
            builder: (ctx, enabled, _) => SwitchListTile(
              title: Text(l.notifications),
              subtitle: Text(l.alertNearby),
              value: enabled,
              onChanged: ConsentService.setAlerts,
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: ConsentService.recording,
            builder: (ctx, enabled, _) => SwitchListTile(
              title: Text(l.recordingPermission),
              value: enabled,
              onChanged: (value) async {
                if (!value) {
                  await ConsentService.setRecording(false);
                  return;
                }
                final accepted = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(l.recordingPermission),
                    content: Text(l.recordingConsent),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(l.cancel),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(l.consentConfirm),
                      ),
                    ],
                  ),
                );
                if (accepted == true) await ConsentService.setRecording(true);
              },
            ),
          ),
          ValueListenableBuilder<Map<String, bool>>(
            valueListenable: HazardService.layers,
            builder: (ctx, layers, _) => SwitchListTile(
              title: Text(l.demo),
              subtitle: Text(l.sourceDemo),
              value: layers['demo'] ?? false,
              onChanged: (value) => HazardService.toggle('demo', value),
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => const HistoryPage()._confirmDelete(context),
            icon: const SaqgoIcon('delete'),
            label: Text(l.deleteHistory),
          ),
          SettingsTile(
            icon: 'sensors',
            title: l.backgroundTasks,
            subtitle: l.comingSoon,
          ),
          const SizedBox(height: SaqgoSpacing.md),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.changeLanguage, style: SaqgoTypography.cardTitle),
                const SizedBox(height: SaqgoSpacing.xs),
                SegmentedButton<Locale>(
                  segments: [
                    ButtonSegment(
                      value: const Locale('kk'),
                      label: Text(l.kazakh),
                    ),
                    ButtonSegment(
                      value: const Locale('ru'),
                      label: Text(l.russian),
                    ),
                  ],
                  selected: {widget.locale},
                  onSelectionChanged: (choice) =>
                      widget.onLocaleChanged(choice.first),
                ),
              ],
            ),
          ),
          const SizedBox(height: SaqgoSpacing.md),
          OutlinedButton.icon(
            onPressed: () async {
              await widget.onRestartFirstRun();
            },
            icon: const Icon(Icons.restart_alt_rounded),
            label: Text(l.restartFirstRun),
          ),
          const SizedBox(height: SaqgoSpacing.md),
          const SizedBox(height: SaqgoSpacing.lg),
          Text(l.version, style: SaqgoTypography.label),
        ],
      ),
    );
  }
}

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  late final Future<BackendStatus> _status = BackendStatusService().check();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SaqgoScaffold(
      title: 'S15 · ${l.admin}',
      child: FutureBuilder<BackendStatus>(
        future: _status,
        builder: (context, snapshot) {
          final status = snapshot.data;
          return ListView(
            children: [
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SAQGO API', style: SaqgoTypography.cardTitle),
                    const SizedBox(height: SaqgoSpacing.sm),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const LinearProgressIndicator()
                    else ...[
                      _StatusRow(
                        label: 'API',
                        enabled: status?.reachable ?? false,
                      ),
                      _StatusRow(
                        label: l.findPlace,
                        enabled: status?.geocoding ?? false,
                      ),
                      _StatusRow(
                        label: l.routes,
                        enabled: status?.routing ?? false,
                      ),
                      _StatusRow(
                        label: l.distanceMatrix,
                        enabled: status?.distanceMatrix ?? false,
                      ),
                      const SizedBox(height: SaqgoSpacing.xs),
                      Text(
                        status?.configured == true
                            ? l.privacyBody
                            : 'SAQGO_API_BASE_URL · ${l.off}',
                        style: SaqgoTypography.body,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: SaqgoSpacing.md),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.sourceQuality, style: SaqgoTypography.cardTitle),
                    const SizedBox(height: SaqgoSpacing.xs),
                    Text(l.mapSource, style: SaqgoTypography.body),
                    const SizedBox(height: SaqgoSpacing.xs),
                    Text(l.routeSource, style: SaqgoTypography.body),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.enabled});

  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final color = enabled ? SaqgoColors.cyan : SaqgoColors.muted;
    return Padding(
      padding: const EdgeInsets.only(bottom: SaqgoSpacing.xs),
      child: Row(
        children: [
          Icon(Icons.circle, size: 10, color: color),
          const SizedBox(width: SaqgoSpacing.sm),
          Expanded(child: Text(label, style: SaqgoTypography.body)),
          Text(enabled ? l.enabled : l.off, style: SaqgoTypography.label),
        ],
      ),
    );
  }
}

class SaqgoScaffold extends StatelessWidget {
  const SaqgoScaffold({super.key, required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              SaqgoSpacing.md,
              0,
              SaqgoSpacing.md,
              SaqgoSpacing.md,
            ),
            child: child,
          ),
        ),
      ),
    ),
  );
}

class GlassCard extends StatelessWidget {
  const GlassCard({super.key, required this.child, this.margin});
  final Widget child;
  final EdgeInsetsGeometry? margin;
  @override
  Widget build(BuildContext context) => Container(
    margin: margin,
    padding: const EdgeInsets.all(SaqgoSpacing.md),
    decoration: BoxDecoration(
      color: SaqgoColors.surface.withValues(alpha: .92),
      borderRadius: BorderRadius.circular(SaqgoRadii.card),
      border: Border.all(color: SaqgoColors.line),
      boxShadow: SaqgoShadows.card,
    ),
    child: child,
  );
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, required this.size, this.sos = false});
  final double size;
  final bool sos;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    padding: EdgeInsets.all(size * .2),
    decoration: BoxDecoration(
      color: sos ? const Color(0xFF54313B) : SaqgoColors.surfaceMuted,
      borderRadius: BorderRadius.circular(size * .28),
    ),
    child: SaqgoIcon(
      sos ? 'sos' : 'logo',
      color: sos ? SaqgoColors.sos : SaqgoColors.cyan,
    ),
  );
}

class SaqgoIcon extends StatelessWidget {
  const SaqgoIcon(
    this.name, {
    super.key,
    this.color = SaqgoColors.muted,
    this.size = 24,
  });
  final String name;
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SvgPicture.asset(
      'assets/icons/$name.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    ),
  );
}

class LocateButton extends StatefulWidget {
  const LocateButton({super.key, this.onLocated});
  final ValueChanged<LocationAvailable>? onLocated;
  @override
  State<LocateButton> createState() => _LocateButtonState();
}

class _LocateButtonState extends State<LocateButton> {
  var _loading = false;
  Future<void> _locate() async {
    setState(() => _loading = true);
    final result = await LocationService().requestCurrentLocation();
    if (!mounted) return;
    setState(() => _loading = false);
    final l = AppLocalizations.of(context)!;
    final message = switch (result) {
      LocationAvailable(:final accuracyMeters) => () {
        widget.onLocated?.call(result);
        return 'GPS ${accuracyMeters.round()} ${l.meters}';
      }(),
      LocationDisabled() || LocationDenied() => l.gpsDisabled,
      LocationUnavailable() => l.mapUnavailable,
    };
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => IconButton.filledTonal(
    onPressed: _loading ? null : _locate,
    tooltip: AppLocalizations.of(context)!.useMyLocation,
    icon: _loading
        ? const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const SaqgoIcon('locate'),
  );
}

class DemoMap extends StatelessWidget {
  const DemoMap({super.key, this.height, this.showRoute = false});
  final double? height;
  final bool showRoute;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(SaqgoRadii.card),
    child: SizedBox(
      height: height,
      child: CustomPaint(
        painter: DemoMapPainter(showRoute: showRoute),
        child: const SizedBox.expand(),
      ),
    ),
  );
}

class DemoMapPainter extends CustomPainter {
  DemoMapPainter({required this.showRoute});
  final bool showRoute;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF0F1C2A),
    );
    final block = Paint()..color = const Color(0xFF182839);
    for (var x = -20.0; x < size.width; x += 74) {
      for (var y = 0.0; y < size.height; y += 64) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x + (y / 64 % 2) * 16, y, 50, 38),
            const Radius.circular(5),
          ),
          block,
        );
      }
    }
    final road = Paint()
      ..color = const Color(0xFF45546A)
      ..strokeWidth = 9
      ..style = PaintingStyle.stroke;
    for (var i = -1; i < 5; i++) {
      canvas.drawLine(
        Offset(i * 100.0, 0),
        Offset(i * 100.0 + 120, size.height),
        road,
      );
    }
    canvas.drawLine(
      Offset(0, size.height * .68),
      Offset(size.width, size.height * .35),
      road..strokeWidth = 13,
    );
    if (showRoute) {
      final route = Paint()
        ..color = SaqgoColors.blue
        ..strokeWidth = 6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final path = Path()
        ..moveTo(size.width * .18, size.height * .75)
        ..lineTo(size.width * .42, size.height * .6)
        ..lineTo(size.width * .35, size.height * .35)
        ..lineTo(size.width * .78, size.height * .2);
      canvas.drawPath(path, route);
    }
  }

  @override
  bool shouldRepaint(covariant DemoMapPainter oldDelegate) =>
      oldDelegate.showRoute != showRoute;
}

class SignalLine extends StatelessWidget {
  const SignalLine({super.key});
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 44,
    width: double.infinity,
    child: CustomPaint(painter: SignalPainter()),
  );
}

class SignalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = SaqgoColors.cyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    final path = Path()..moveTo(0, size.height / 2);
    for (var i = 1; i < 32; i++) {
      final y =
          size.height / 2 +
          ((i % 5 == 0
              ? -8
              : i % 3 == 0
              ? 5
              : -2));
      path.lineTo(i * size.width / 31, y);
    }
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PulseGrid extends StatelessWidget {
  const PulseGrid({super.key});
  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 1.15,
    child: CustomPaint(painter: PulseGridPainter()),
  );
}

class PulseGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size,
        const Radius.circular(SaqgoRadii.card),
      ),
      Paint()..color = const Color(0xFF0F1C2A),
    );
    final empty = Paint()..color = SaqgoColors.surface;
    final active = Paint()..color = SaqgoColors.cyan.withValues(alpha: .38);
    final gap = 8.0;
    final cellWidth = (size.width - gap * 5) / 4;
    final cellHeight = (size.height - gap * 4) / 3;
    for (var row = 0; row < 3; row++) {
      for (var column = 0; column < 4; column++) {
        final paint = (row + column) % 3 == 0 ? active : empty;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              gap + column * (cellWidth + gap),
              gap + row * (cellHeight + gap),
              cellWidth,
              cellHeight,
            ),
            const Radius.circular(12),
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class Metric extends StatelessWidget {
  const Metric({super.key, required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: SaqgoTypography.label),
      Text(
        value,
        style: const TextStyle(
          fontFamily: "SaqgoSans",
          fontSize: 36,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}

class InfoCard extends StatelessWidget {
  const InfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
  });
  final String icon, title, body;
  @override
  Widget build(BuildContext context) => GlassCard(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SaqgoIcon(icon, color: SaqgoColors.cyan),
        const SizedBox(width: SaqgoSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: SaqgoTypography.cardTitle),
              const SizedBox(height: 4),
              Text(body, style: SaqgoTypography.body),
            ],
          ),
        ),
      ],
    ),
  );
}

class RiskChip extends StatelessWidget {
  const RiskChip({super.key, required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Chip(
    label: Text(text),
    backgroundColor: SaqgoColors.surfaceMuted,
    labelStyle: const TextStyle(color: SaqgoColors.cyan),
  );
}

class PlaceField extends StatelessWidget {
  const PlaceField({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label, value, icon;
  @override
  Widget build(BuildContext context) => GlassCard(
    child: Row(
      children: [
        SaqgoIcon(icon, color: SaqgoColors.blue),
        const SizedBox(width: SaqgoSpacing.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: SaqgoTypography.label),
            Text(value, style: SaqgoTypography.cardTitle),
          ],
        ),
      ],
    ),
  );
}

class RouteChoice extends StatelessWidget {
  const RouteChoice({
    super.key,
    required this.title,
    this.riskCount = 0,
    required this.duration,
    required this.distance,
    this.selected = false,
    this.onTap,
  });
  final String title, duration, distance;
  final int riskCount;
  final bool selected;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(SaqgoSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(
          color: selected ? SaqgoColors.blue : SaqgoColors.line,
        ),
        borderRadius: BorderRadius.circular(SaqgoRadii.control),
        color: SaqgoColors.surface,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: SaqgoTypography.cardTitle),
                Text(distance, style: SaqgoTypography.label),
                Text(
                  '${AppLocalizations.of(context)!.knownRisks}: $riskCount',
                  style: SaqgoTypography.label,
                ),
              ],
            ),
          ),
          Text(duration, style: SaqgoTypography.cardTitle),
        ],
      ),
    ),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    required this.onAction,
    required this.actionLabel,
  });
  final String icon, message, actionLabel;
  final VoidCallback onAction;
  @override
  Widget build(BuildContext context) => GlassCard(
    child: Column(
      children: [
        SaqgoIcon(icon, size: 42),
        const SizedBox(height: SaqgoSpacing.sm),
        Text(message, style: SaqgoTypography.body, textAlign: TextAlign.center),
        const SizedBox(height: SaqgoSpacing.sm),
        TextButton(onPressed: onAction, child: Text(actionLabel)),
      ],
    ),
  );
}

class CalendarCard extends StatefulWidget {
  const CalendarCard({super.key, required this.trips, this.onDaySelected});
  final List<TripRecord> trips;
  final ValueChanged<DateTime>? onDaySelected;
  @override
  State<CalendarCard> createState() => _CalendarCardState();
}

class _CalendarCardState extends State<CalendarCard> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _selected;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final local = MaterialLocalizations.of(context);
    final days = DateUtils.getDaysInMonth(_month.year, _month.month);
    final offset = (_month.weekday - local.firstDayOfWeekIndex - 1 + 7) % 7;
    final marked = widget.trips
        .where(
          (t) =>
              t.startedAt.year == _month.year &&
              t.startedAt.month == _month.month,
        )
        .map((t) => t.startedAt.day)
        .toSet();
    return GlassCard(
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: l.previousMonth,
                onPressed: () => setState(
                  () => _month = DateTime(_month.year, _month.month - 1),
                ),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  local.formatMonthYear(_month),
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                tooltip: l.nextMonth,
                onPressed: () => setState(
                  () => _month = DateTime(_month.year, _month.month + 1),
                ),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          Row(
            children: List.generate(
              7,
              (i) => Expanded(
                child: Text(
                  local.narrowWeekdays[(local.firstDayOfWeekIndex + i) % 7],
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisExtent: 48,
            ),
            itemCount: ((offset + days + 6) ~/ 7) * 7,
            itemBuilder: (ctx, index) {
              final day = index - offset + 1;
              if (day < 1 || day > days) return const SizedBox();
              final date = DateTime(_month.year, _month.month, day);
              return TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: DateUtils.isSameDay(date, _selected)
                      ? SaqgoColors.blue
                      : marked.contains(day)
                      ? SaqgoColors.surface
                      : Colors.transparent,
                ),
                onPressed: () {
                  setState(() => _selected = date);
                  widget.onDaySelected?.call(date);
                },
                child: Text('$day'),
              );
            },
          ),
        ],
      ),
    );
  }
}

class TripCard extends StatelessWidget {
  const TripCard({super.key, required this.record, required this.onOpen});
  final TripRecord record;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return GlassCard(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const SaqgoIcon('route', color: SaqgoColors.blue),
        title: Text(
          '${record.demo ? '${l.demo} · ' : ''}${MaterialLocalizations.of(context).formatMediumDate(record.startedAt)}',
        ),
        subtitle: Text(
          '${_durationLabel(record.duration)} · ${_distanceLabel(record.distanceMeters, l)} · ${record.candidateCount} ${l.candidates.toLowerCase()}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onOpen,
      ),
    );
  }
}

class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });
  final String icon, title, subtitle;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: GlassCard(
      margin: const EdgeInsets.only(bottom: SaqgoSpacing.sm),
      child: Row(
        children: [
          SaqgoIcon(icon),
          const SizedBox(width: SaqgoSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: SaqgoTypography.cardTitle),
                Text(subtitle, style: SaqgoTypography.label),
              ],
            ),
          ),
          if (onTap != null) const Icon(Icons.chevron_right),
        ],
      ),
    ),
  );
}

ButtonStyle _buttonStyle({Color? background, Color? foreground}) =>
    FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(52),
      backgroundColor: background,
      foregroundColor: foreground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SaqgoRadii.control),
      ),
    );
void _push(BuildContext context, Widget page) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
void _pushReplacement(BuildContext context, Widget page) => Navigator.of(
  context,
).pushReplacement(MaterialPageRoute(builder: (_) => page));

String _durationLabel(Duration duration) {
  final hours = duration.inHours;
  final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
  final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
  return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
}

String _distanceLabel(double meters, AppLocalizations l) => meters >= 1000
    ? '${(meters / 1000).toStringAsFixed(2)} ${l.kilometers}'
    : '${meters.round()} ${l.meters}';

Future<bool> _confirmAction(
  BuildContext context,
  String title,
  String body,
) async {
  final l = AppLocalizations.of(context)!;
  return await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l.continueAction),
            ),
          ],
        ),
      ) ??
      false;
}

Future<void> _exportTrip(BuildContext context, TripRecord record) async {
  final l = AppLocalizations.of(context)!;
  if (!await _confirmAction(context, l.exportTrip, l.exportWarning)) return;
  final geojson = {
    'type': 'FeatureCollection',
    'features': [
      {
        'type': 'Feature',
        'properties': {
          'demo': record.demo,
          'started_at': record.startedAt.toUtc().toIso8601String(),
          'duration_seconds': record.duration.inSeconds,
        },
        'geometry': {
          'type': 'MultiLineString',
          'coordinates': record.routeSegments
              .where((segment) => segment.length > 1)
              .map(
                (segment) =>
                    segment.map((p) => [p.longitude, p.latitude]).toList(),
              )
              .toList(),
        },
      },
    ],
  };
  final bytes = utf8.encode(jsonEncode(geojson));
  if (!context.mounted) return;
  final renderBox = context.findRenderObject() as RenderBox?;
  await SharePlus.instance.share(
    ShareParams(
      files: [
        XFile.fromData(
          Uint8List.fromList(bytes),
          mimeType: 'application/geo+json',
          name: 'saqgo-trip.geojson',
        ),
      ],
      fileNameOverrides: ['saqgo-trip.geojson'],
      sharePositionOrigin: renderBox == null
          ? null
          : renderBox.localToGlobal(Offset.zero) & renderBox.size,
    ),
  );
}

class CandidateSummary extends StatelessWidget {
  const CandidateSummary({super.key, required this.record});
  final TripRecord record;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (record.demo) Text(l.demo, style: SaqgoTypography.cardTitle),
          Text(
            record.candidateCount == 0
                ? l.noEvents
                : '${l.candidates}: ${record.candidateCount}',
            style: SaqgoTypography.body,
          ),
          for (final candidate in record.candidates)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '${l.unverified} · ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(candidate.timestamp.toLocal()))} · ${l.confidenceValue}: ${(candidate.confidence * 100).round()}% · ${l.accuracy}: ${candidate.accuracyMeters.round()} ${l.meters}',
              ),
            ),
          if (record.candidates.isNotEmpty && !record.demo)
            TextButton(
              onPressed: () => _sendObservations(context, record),
              child: Text(l.privacyUpload),
            ),
        ],
      ),
    );
  }
}

Future<void> _sendObservations(BuildContext context, TripRecord record) async {
  final l = AppLocalizations.of(context)!;
  if (!await _confirmAction(context, l.privacyUpload, l.privacyUploadWarning)) {
    return;
  }
  final endpoint = HazardService.uri('/v1/observations');
  try {
    if (endpoint == null) throw StateError('API unavailable');
    for (final candidate in record.candidates) {
      final digest = await Sha256().hash(
        utf8.encode(
          '${record.id}:${candidate.timestamp.toUtc().toIso8601String()}',
        ),
      );
      final hex = digest.bytes
          .take(16)
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();
      final eventId =
          '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
      final response = await http
          .post(
            endpoint,
            headers: {
              'Content-Type': 'application/json',
              'Idempotency-Key': eventId,
            },
            body: jsonEncode({
              'point': {
                'latitude': candidate.latitude,
                'longitude': candidate.longitude,
              },
              'category': 'road_bump',
              'confidence': candidate.confidence,
              'accuracy_meters': candidate.accuracyMeters,
              'observed_at': candidate.timestamp.toUtc().toIso8601String(),
              'consent_version': ConsentService.version,
            }),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw StateError('Upload failed');
      }
    }
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.uploadDone)));
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.networkUnavailable)));
    }
  }
}

String _hazardTitle(AppLocalizations l, String category) => switch (category) {
  'road_bump' => l.riskTitle,
  'ice' => l.potentialIce,
  'closure' => l.roadClosure,
  'sidewalk' => l.sidewalk,
  _ => l.hazards,
};
