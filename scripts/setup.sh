#!/bin/bash
echo "🚀 Configurando proyecto Flutter Alarm App..."

# Verificar Flutter
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter no está instalado"
    exit 1
fi

echo "✅ Flutter encontrado"

# Limpiar proyecto
echo "🧹 Limpiando proyecto..."
flutter clean

# Instalar dependencias
echo "📦 Instalando dependencias..."
flutter pub get

# Verificar configuración
echo "🔍 Verificando configuración..."
flutter doctor

# Verificar google-services.json
if [ ! -f "android/app/google-services.json" ]; then
    echo "⚠️  ADVERTENCIA: google-services.json no encontrado"
    echo "   Descárgalo desde Firebase Console y colócalo en android/app/"
fi

echo "✅ Configuración completada"
echo "🎯 Ejecutar: flutter run"