#!/bin/bash
echo "🏗️  Compilando aplicación para release..."

# Limpiar
flutter clean
flutter pub get

# Compilar APK
echo "📱 Generando APK..."
flutter build apk --release

# Compilar App Bundle
echo "📦 Generando App Bundle..."
flutter build appbundle --release

echo "✅ Compilación completada"
echo "📁 APK: build/app/outputs/flutter-apk/app-release.apk"
echo "📁 AAB: build/app/outputs/bundle/release/app-release.aab"