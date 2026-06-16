#!/bin/bash

echo "Preparing FOSS build..."

# Swap out proprietary Google/Firebase auth service with the FOSS stub
cp lib/core/services/auth_service_stub.dart lib/core/services/auth_service.dart

# Remove proprietary dependencies from pubspec.yaml
sed -i '/firebase_core:/d' pubspec.yaml
sed -i '/firebase_auth:/d' pubspec.yaml
sed -i '/cloud_firestore:/d' pubspec.yaml
sed -i '/google_sign_in:/d' pubspec.yaml

echo "FOSS preparation complete. You can now build the F-Droid version."
