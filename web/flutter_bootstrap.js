{{flutter_js}}
{{flutter_build_config}}
// Ship the renderer with the application so local UI does not need a CDN.
_flutter.loader.load({config: {canvasKitBaseUrl: 'canvaskit/'}});
