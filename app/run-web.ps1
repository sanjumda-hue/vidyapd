# Serves the Flutter web app on a fixed port and leaves the browser to you.
#
# `flutter run -d chrome` launches its own Chrome and waits for a debug service
# to attach, which does not always succeed on this machine. -d web-server skips
# that entirely: open http://localhost:5000 in any browser yourself.
#
# The port is pinned because it has to match CORS_ORIGINS in api/.env.
$flutter = Join-Path $env:USERPROFILE "flutter\bin\flutter.bat"
& $flutter run -d web-server --web-port=5000 --web-hostname=localhost
