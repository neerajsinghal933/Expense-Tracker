#!/bin/bash
# Pulse Money - Production Build Setup Guide
# This script helps set up signing credentials for production release builds

set -e

echo "=========================================="
echo "Pulse Money - Production Build Setup"
echo "=========================================="
echo ""

# Check if flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed. Please install Flutter first."
    exit 1
fi

# Create keystore directory
mkdir -p android/keystore

# Function to generate keystore
generate_keystore() {
    echo ""
    echo "Generating signing keystore..."
    echo ""

    read -p "Enter keystore password (min 6 chars): " -s keystore_password
    echo ""
    read -p "Confirm keystore password: " -s keystore_password_confirm
    echo ""

    if [ "$keystore_password" != "$keystore_password_confirm" ]; then
        echo "❌ Passwords don't match!"
        exit 1
    fi

    read -p "Enter key alias [pulse-money-key]: " key_alias
    key_alias=${key_alias:-pulse-money-key}

    read -p "Enter key password (can be same as keystore): " -s key_password
    echo ""

    read -p "Enter your full name: " full_name
    read -p "Enter your organization: " organization
    read -p "Enter your country code (2 letters, e.g., US): " country_code

    # Generate keystore
    keytool -genkey -v -keystore android/keystore/release.jks \
        -keyalg RSA -keysize 4096 -validity 10950 \
        -alias "$key_alias" \
        -storepass "$keystore_password" \
        -keypass "$key_password" \
        -dname "CN=$full_name, O=$organization, C=$country_code"

    echo ""
    echo "✅ Keystore generated successfully!"
    echo ""
    echo "Save these credentials:"
    echo "  Keystore Password: $keystore_password"
    echo "  Key Alias: $key_alias"
    echo "  Key Password: $key_password"
    echo ""
}

# Function to setup environment
setup_environment() {
    echo ""
    echo "Setting up environment variables for signing..."
    echo ""

    if [ ! -f android/keystore/release.jks ]; then
        read -p "Do you want to generate a new keystore? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            generate_keystore
        else
            echo "❌ Keystore not found. Please place release.jks in android/keystore/"
            exit 1
        fi
    fi

    read -p "Enter keystore password: " -s keystore_password
    echo ""
    read -p "Enter key alias: " key_alias
    read -p "Enter key password: " -s key_password
    echo ""

    # Create .env.production file
    cat > .env.production << EOF
# Production Build Environment Variables
KEYSTORE_PATH=android/keystore/release.jks
KEYSTORE_PASSWORD=$keystore_password
KEY_ALIAS=$key_alias
KEY_PASSWORD=$key_password
EOF

    chmod 600 .env.production

    echo "✅ Environment file created: .env.production"
    echo ""
    echo "⚠️  Important: Add .env.production to .gitignore!"
    echo ""
}

# Main menu
show_menu() {
    echo ""
    echo "What would you like to do?"
    echo "1. Generate new signing keystore"
    echo "2. Setup environment for existing keystore"
    echo "3. Build release APK"
    echo "4. Build release App Bundle"
    echo "5. Build obfuscated split APKs"
    echo "6. Exit"
    echo ""
}

# Build functions
build_release_apk() {
    echo ""
    echo "Building release APK..."
    source .env.production 2>/dev/null || echo "⚠️  Warning: .env.production not found"

    flutter build apk --release \
        -v \
        --split-per-abi

    echo ""
    echo "✅ Release APK built successfully!"
    echo "📁 Location: build/app/outputs/flutter-apk/"
    echo ""
}

build_release_bundle() {
    echo ""
    echo "Building release App Bundle..."
    source .env.production 2>/dev/null || echo "⚠️  Warning: .env.production not found"

    flutter build appbundle --release -v

    echo ""
    echo "✅ Release App Bundle built successfully!"
    echo "📁 Location: build/app/outputs/bundle/release/"
    echo ""
}

build_split_apks() {
    echo ""
    echo "Building split APKs with obfuscation..."
    source .env.production 2>/dev/null || echo "⚠️  Warning: .env.production not found"

    flutter build apk --release \
        -v \
        --split-per-abi \
        --target-platform android-arm64,android-arm

    echo ""
    echo "✅ Split APKs built successfully!"
    echo "📁 Locations:"
    echo "   - arm64-v8a: build/app/outputs/flutter-apk/app-arm64-v8a-release.apk"
    echo "   - armeabi-v7a: build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk"
    echo ""
}

# Main loop
while true; do
    show_menu
    read -p "Enter your choice (1-6): " choice

    case $choice in
        1) generate_keystore ;;
        2) setup_environment ;;
        3) build_release_apk ;;
        4) build_release_bundle ;;
        5) build_split_apks ;;
        6) echo "Goodbye!"; exit 0 ;;
        *) echo "❌ Invalid choice. Please try again." ;;
    esac
done

