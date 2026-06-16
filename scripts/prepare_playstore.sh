#!/bin/bash

echo "Preparing Play Store build..."

# Restore proprietary Google/Firebase auth service
cp lib/core/services/auth_service_google.dart lib/core/services/auth_service.dart

# Restore pubspec.yaml to its original state containing the firebase dependencies
if git status &> /dev/null; then
    git checkout pubspec.yaml
    echo "Restored pubspec.yaml via git."
else
    echo "WARNING: Not a git repository. Please ensure your pubspec.yaml contains the required firebase_core, firebase_auth, cloud_firestore, and google_sign_in dependencies."
fi

echo "Play Store preparation complete."
