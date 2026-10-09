import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/colors.dart';
import 'core/theme/radii.dart';
import 'core/theme/shadows.dart';
import 'core/theme/spacing.dart';
import 'core/theme/theme.dart';
import 'core/theme/typography.dart';
import 'core/services/location_service.dart';
import 'core/services/lifelog_store.dart';
import 'core/services/sensor_session_service.dart';
import 'core/services/trip_track_service.dart';
import 'features/map/arqalyk_map.dart';
import 'l10n/app_localizations.dart';

void main() => runApp(const SaqgoApp());

class SaqgoApp extends StatefulWidget {
  const SaqgoApp({super.key});

  @override
  State<SaqgoApp> createState() => _SaqgoAppState();
}

class _SaqgoAppState extends State<SaqgoApp> {
  Locale _locale = const Locale('ru');
  var _stage = 0;

  @override
  void initState() {
    super.initState();
    _restoreLaunchState();
    LifeLogStore.restore();
  }

  Future<void> _restoreLaunchState() async {
    final saved = (await SharedPreferences.getInstance()).getString(
      'saqgo_locale',
    );
    if (!mounted || saved == null) return;
    setState(() {
      _locale = Locale(saved);
      _stage = 2;
    });
  }

  void _setLocale(Locale locale) {
    setState(() => _locale = locale);
    SharedPreferences.getInstance().then(
      (preferences) =>
          preferences.setString('saqgo_locale', locale.languageCode),
    );
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'SAQGO',
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
    home: switch (_stage) {
      0 => LanguagePage(
        onLocaleSelected: _setLocale,
        onStarted: () => setState(() => _stage = 1),
      ),
      1 => OnboardingPage(onFinished: () => setState(() => _stage = 2)),
      _ => HomeShell(locale: _locale, onLocaleChanged: _setLocale),
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
                'SAQGO',
                style: TextStyle(fontSize: 40, fontWeight: FontWeight.w800),
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

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key, required this.onFinished});
  final VoidCallback onFinished;

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
              InfoCard(icon: 'privacy', title: l.privacy, body: l.privacyBody),
              const SizedBox(height: SaqgoSpacing.sm),
              InfoCard(
                icon: 'no_gps',
                title: l.locationPermission,
                body: l.recordingConsent,
              ),
              const Spacer(),
              FilledButton(
                onPressed: onFinished,
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
  });
  final Locale locale;
  final ValueChanged<Locale> onLocaleChanged;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  var _index = 0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final pages = [
      MapPage(onOpenRoutes: () => setState(() => _index = 1)),
      RoutePlannerPage(
        onNavigate: () => _push(context, const NavigationPage()),
      ),
      const HistoryPage(),
      SettingsPage(
        locale: widget.locale,
        onLocaleChanged: widget.onLocaleChanged,
      ),
    ];
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _index, children: pages),
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

class MapPage extends StatelessWidget {
  const MapPage({super.key, required this.onOpenRoutes});
  final VoidCallback onOpenRoutes;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Stack(
      children: [
        const Positioned.fill(child: ArqalykMap()),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(SaqgoSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlassCard(
                  child: Row(
                    children: [
                      const BrandMark(size: 36),
                      const SizedBox(width: SaqgoSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'SAQGO',
                              style: SaqgoTypography.cardTitle,
                            ),
                            Text(l.mapSource, style: SaqgoTypography.label),
                          ],
                        ),
                      ),
                      Text(l.arkalyk, style: SaqgoTypography.label),
                    ],
                  ),
                ),
                const SizedBox(height: SaqgoSpacing.sm),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _push(context, const SosPage()),
                      icon: const SaqgoIcon('sos', color: SaqgoColors.sos),
                      label: Text(l.sos),
                    ),
                    const Spacer(),
                    IconButton.filledTonal(
                      onPressed: () => _push(context, const LayersPage()),
                      icon: const SaqgoIcon('layers'),
                      tooltip: l.layers,
                    ),
                    const SizedBox(width: SaqgoSpacing.xs),
                    const LocateButton(),
                  ],
                ),
                const Spacer(),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.noVerifiedRisks, style: SaqgoTypography.cardTitle),
                      const SizedBox(height: SaqgoSpacing.xs),
                      Text(l.noVerifiedRisks, style: SaqgoTypography.body),
                      const SizedBox(height: SaqgoSpacing.md),
                      OutlinedButton.icon(
                        onPressed: () =>
                            _push(context, const RiskDetailsPage()),
                        icon: const SaqgoIcon('hazards'),
                        label: Text(l.hazards),
                      ),
                      TextButton.icon(
                        onPressed: () => _push(context, const PulsePage()),
                        icon: const SaqgoIcon('pulse'),
                        label: Text(l.livePulse),
                      ),
                      const SizedBox(height: SaqgoSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: onOpenRoutes,
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
              ],
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
  final _layers = <String, bool>{
    'roadBumps': false,
    'potentialIce': false,
    'hazards': true,
    'livePulse': false,
    'onlyVerified': true,
  };
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SaqgoScaffold(
      title: l.layers,
      child: ListView(
        children: [
          Text(l.sourceDemo, style: SaqgoTypography.body),
          const SizedBox(height: SaqgoSpacing.md),
          for (final entry in _layers.entries)
            GlassCard(
              margin: const EdgeInsets.only(bottom: SaqgoSpacing.sm),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_layerText(l, entry.key)),
                value: entry.value,
                onChanged: (value) =>
                    setState(() => _layers[entry.key] = value),
              ),
            ),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.sourceQuality, style: SaqgoTypography.cardTitle),
                const SizedBox(height: SaqgoSpacing.xs),
                Text(l.sourceDemo, style: SaqgoTypography.body),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _layerText(AppLocalizations l, String key) => switch (key) {
    'roadBumps' => l.roadBumps,
    'potentialIce' => l.potentialIce,
    'hazards' => l.hazards,
    'livePulse' => l.livePulse,
    _ => l.onlyVerified,
  };
}

class RiskDetailsPage extends StatelessWidget {
  const RiskDetailsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SaqgoScaffold(
      title: l.riskTitle,
      child: ListView(
        children: [
          const DemoMap(height: 190, showRoute: true),
          const SizedBox(height: SaqgoSpacing.md),
          RiskChip(text: l.unverified),
          const SizedBox(height: SaqgoSpacing.md),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.confidence, style: SaqgoTypography.cardTitle),
                const SizedBox(height: SaqgoSpacing.xs),
                Text(l.lastUpdated, style: SaqgoTypography.body),
                const SizedBox(height: SaqgoSpacing.md),
                FilledButton.icon(
                  onPressed: () => _push(context, const RoutePlannerPage()),
                  icon: const SaqgoIcon('route', color: SaqgoColors.navy),
                  label: Text(l.openRoute),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
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

class _RecordingPageState extends State<RecordingPage> {
  RecordingState _state = RecordingState.idle;
  final _session = SensorSessionService();
  final _track = TripTrackService();
  var _candidateCount = 0;
  StreamSubscription<LocationAvailable>? _positionSubscription;
  double? _gpsAccuracyMeters;
  DateTime? _startedAt;
  DateTime? _activeSince;
  Duration _elapsed = Duration.zero;
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    _session.candidates.listen((_) {
      if (mounted) setState(() => _candidateCount++);
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    _positionSubscription?.cancel();
    _session.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_state == RecordingState.active) {
      await _session.pause();
      await _positionSubscription?.cancel();
      _positionSubscription = null;
      _track.pause();
      _pauseClock();
      if (mounted) setState(() => _state = RecordingState.paused);
      return;
    }
    await _session.start();
    if (_state == RecordingState.paused) {
      _track.resume();
    } else {
      _track.start();
    }
    _startedAt ??= DateTime.now();
    _activeSince = DateTime.now();
    _clock ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    if (mounted) setState(() => _state = RecordingState.active);
    unawaited(_beginLocationTracking());
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
      distanceMeters: track.distanceMeters,
      trackPointCount: track.points.length,
    );
    if (mounted) _pushReplacement(context, TripResultPage(record: record));
  }

  Future<void> _beginLocationTracking() async {
    final locationService = LocationService();
    final current = await locationService.requestCurrentLocation();
    if (!mounted || _state != RecordingState.active) return;
    if (current is LocationAvailable) {
      _addLocationSample(current);
      _positionSubscription = locationService.positionUpdates().listen(
        _addLocationSample,
        onError: (_) {},
      );
    }
  }

  void _addLocationSample(LocationAvailable location) {
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
            onPressed: _toggle,
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
            onPressed: _state == RecordingState.idle ? null : _finish,
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
          const DemoMap(height: 200, showRoute: true),
          const SizedBox(height: SaqgoSpacing.md),
          GlassCard(child: Text(l.noEvents, style: SaqgoTypography.body)),
          const SizedBox(height: SaqgoSpacing.md),
          FilledButton(
            onPressed: () async {
              await LifeLogStore.add(record);
              if (context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
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

class RoutePlannerPage extends StatelessWidget {
  const RoutePlannerPage({super.key, this.onNavigate});
  final VoidCallback? onNavigate;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SaqgoScaffold(
      title: l.routePlanner,
      child: ListView(
        children: [
          PlaceField(label: l.from, value: l.testPointA, icon: 'locate'),
          const SizedBox(height: SaqgoSpacing.sm),
          PlaceField(label: l.to, value: l.testPointB, icon: 'map'),
          const SizedBox(height: SaqgoSpacing.md),
          const DemoMap(height: 180, showRoute: true),
          const SizedBox(height: SaqgoSpacing.md),
          RouteChoice(
            title: l.faster,
            duration: l.minutes12,
            distance: l.walking12,
            selected: true,
          ),
          const SizedBox(height: SaqgoSpacing.sm),
          RouteChoice(
            title: l.lessKnownRisk,
            duration: l.minutes16,
            distance: l.walking15,
          ),
          const SizedBox(height: SaqgoSpacing.md),
          Text(l.insufficientData, style: SaqgoTypography.body),
          const SizedBox(height: SaqgoSpacing.xs),
          Text(l.riskDisclaimer, style: SaqgoTypography.body),
          const SizedBox(height: SaqgoSpacing.md),
          FilledButton.icon(
            onPressed:
                onNavigate ?? () => _push(context, const NavigationPage()),
            icon: const SaqgoIcon('route', color: SaqgoColors.navy),
            label: Text(l.startNavigation),
          ),
        ],
      ),
    );
  }
}

class NavigationPage extends StatelessWidget {
  const NavigationPage({super.key});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SaqgoScaffold(
      title: l.navigation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(child: DemoMap(showRoute: true)),
          const SizedBox(height: SaqgoSpacing.md),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.nextTurn, style: SaqgoTypography.cardTitle),
                const SizedBox(height: SaqgoSpacing.xs),
                Text(l.riskDisclaimer, style: SaqgoTypography.body),
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

class PulsePage extends StatelessWidget {
  const PulsePage({super.key});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SaqgoScaffold(
      title: l.pulseTitle,
      child: ListView(
        children: [
          const PulseGrid(),
          const SizedBox(height: SaqgoSpacing.md),
          GlassCard(child: Text(l.pulseBody, style: SaqgoTypography.body)),
        ],
      ),
    );
  }
}

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SaqgoScaffold(
      title: l.lifelog,
      child: ListView(
        children: [
          Text(l.localOnly, style: SaqgoTypography.body),
          const SizedBox(height: SaqgoSpacing.md),
          CalendarCard(),
          const SizedBox(height: SaqgoSpacing.md),
          ValueListenableBuilder<List<TripRecord>>(
            valueListenable: LifeLogStore.trips,
            builder: (context, trips, _) => Column(
              children: [
                if (trips.isEmpty)
                  EmptyState(
                    icon: 'empty_data',
                    message: l.emptyHistory,
                    onAction: () => _push(context, const RecordingPage()),
                    actionLabel: l.startRecording,
                  )
                else
                  for (final trip in trips)
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
                      ? () => _confirmDelete(context)
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

  Future<void> _confirmDelete(BuildContext context) async {
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
          const DemoMap(height: 240, showRoute: true),
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
                  '${_durationLabel(record.duration)} · ${_distanceLabel(record.distanceMeters)} · ${record.candidateCount} ${l.candidates.toLowerCase()}',
                  style: SaqgoTypography.body,
                ),
              ],
            ),
          ),
          const SizedBox(height: SaqgoSpacing.md),
          Text(l.noEvents, style: SaqgoTypography.body),
        ],
      ),
    );
  }
}

class SosPage extends StatelessWidget {
  const SosPage({super.key});
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
              style: TextStyle(fontSize: 58, fontWeight: FontWeight.w800),
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
                      style: const TextStyle(color: SaqgoColors.cyan),
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

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.locale,
    required this.onLocaleChanged,
  });
  final Locale locale;
  final ValueChanged<Locale> onLocaleChanged;
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
                Text(l.privacyBody, style: SaqgoTypography.body),
              ],
            ),
          ),
          const SizedBox(height: SaqgoSpacing.md),
          SettingsTile(
            icon: 'no_gps',
            title: l.locationPermission,
            subtitle: l.off,
          ),
          SettingsTile(icon: 'alert', title: l.notifications, subtitle: l.off),
          SettingsTile(
            icon: 'sensors',
            title: l.backgroundTasks,
            subtitle: l.off,
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
                  selected: {locale},
                  onSelectionChanged: (choice) => onLocaleChanged(choice.first),
                ),
              ],
            ),
          ),
          const SizedBox(height: SaqgoSpacing.md),
          OutlinedButton.icon(
            onPressed: () => _push(context, const AdminPage()),
            icon: const SaqgoIcon('profile'),
            label: Text('S15 · ${l.admin}'),
          ),
          const SizedBox(height: SaqgoSpacing.lg),
          Text(l.version, style: SaqgoTypography.label),
        ],
      ),
    );
  }
}

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SaqgoScaffold(
      title: 'S15 · ${l.admin}',
      child: ListView(
        children: [
          Text(l.comingSoon, style: SaqgoTypography.body),
          const SizedBox(height: SaqgoSpacing.md),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.privacy, style: SaqgoTypography.cardTitle),
                const SizedBox(height: SaqgoSpacing.xs),
                Text(l.sourceDemo, style: SaqgoTypography.body),
              ],
            ),
          ),
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
  Widget build(BuildContext context) => Semantics(
    label: name,
    child: SvgPicture.asset(
      'assets/icons/$name.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    ),
  );
}

class LocateButton extends StatefulWidget {
  const LocateButton({super.key});
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
      LocationAvailable(:final accuracyMeters) =>
        '${l.demo}: GPS ${accuracyMeters.round()} m',
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
        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w500),
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
    required this.duration,
    required this.distance,
    this.selected = false,
  });
  final String title, duration, distance;
  final bool selected;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(SaqgoSpacing.md),
    decoration: BoxDecoration(
      border: Border.all(color: selected ? SaqgoColors.blue : SaqgoColors.line),
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
            ],
          ),
        ),
        Text(duration, style: SaqgoTypography.cardTitle),
      ],
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

class CalendarCard extends StatelessWidget {
  const CalendarCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.monthOctober2026, style: SaqgoTypography.cardTitle),
          const SizedBox(height: SaqgoSpacing.sm),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: List.generate(
              31,
              (i) => Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: i == 8 ? SaqgoColors.blue : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  '${i + 1}',
                  style: TextStyle(
                    color: i == 8 ? SaqgoColors.navy : SaqgoColors.text,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: SaqgoSpacing.sm),
          Text(l.demo, style: SaqgoTypography.label),
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
          MaterialLocalizations.of(context).formatMediumDate(record.startedAt),
        ),
        subtitle: Text(
          '${_durationLabel(record.duration)} · ${_distanceLabel(record.distanceMeters)} · ${record.candidateCount} ${l.candidates.toLowerCase()}',
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
  });
  final String icon, title, subtitle;
  @override
  Widget build(BuildContext context) => GlassCard(
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
      ],
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

String _distanceLabel(double meters) => meters >= 1000
    ? '${(meters / 1000).toStringAsFixed(2)} km'
    : '${meters.round()} m';
