# Deployment Setup Guide

This guide explains how to configure the GitHub secrets required for automated deployment to Google Play Store and Apple App Store.

## Table of Contents

- [Android Setup](#android-setup)
  - [1. Generate Upload Keystore](#1-generate-upload-keystore)
  - [2. Create Google Play Service Account](#2-create-google-play-service-account)
  - [3. Configure Android Secrets](#3-configure-android-secrets)
- [iOS Setup](#ios-setup)
  - [1. Create Match Certificate Repository](#1-create-match-certificate-repository)
  - [2. Initialize Fastlane Match](#2-initialize-fastlane-match)
  - [3. Create App Store Connect API Key](#3-create-app-store-connect-api-key)
  - [4. Configure iOS Secrets](#4-configure-ios-secrets)
- [Running the Deployment](#running-the-deployment)
- [Troubleshooting](#troubleshooting)

---

## Android Setup

### 1. Generate Upload Keystore

The upload keystore is used to sign your Android app for Play Store submission.

```bash
# Generate a new keystore
keytool -genkey -v \
  -keystore upload-keystore.jks \
  -storetype JKS \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias upload

# You will be prompted for:
# - Keystore password (save this!)
# - Key password (can be same as keystore password)
# - Your name, organization, location info
```

**Important:** Store the keystore file and passwords securely. If you lose them, you cannot update your app on the Play Store.

```bash
# Convert keystore to base64 for GitHub secret
base64 -i upload-keystore.jks | pbcopy  # macOS (copies to clipboard)
# OR
base64 -i upload-keystore.jks > keystore-base64.txt  # Save to file
```

### 2. Create Google Play Service Account

The service account allows automated uploads to Google Play Console.

#### Step 1: Create Service Account in Google Cloud Console

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Select or create a project linked to your Play Console
3. Navigate to **IAM & Admin** → **Service Accounts**
4. Click **Create Service Account**
   - Name: `play-store-deploy` (or similar)
   - Role: No role needed (permissions granted in Play Console)
5. Click **Done**

#### Step 2: Generate JSON Key

1. Click on the newly created service account
2. Go to **Keys** tab
3. Click **Add Key** → **Create new key**
4. Choose **JSON** format
5. Download the file (e.g., `play-store-key.json`)

#### Step 3: Link Service Account to Play Console

1. Go to [Google Play Console](https://play.google.com/console)
2. Navigate to **Settings** → **API access**
3. Find your service account and click **Manage Play Console permissions**
4. Grant these permissions:
   - **Releases** → Manage production releases, Manage testing track releases
   - Or simply grant **Admin** for full access
5. Click **Invite user** → **Send invite**

#### Step 4: Encode the JSON Key

```bash
# Convert to base64 for GitHub secret
base64 -i play-store-key.json | pbcopy  # macOS
# OR
base64 -i play-store-key.json > play-store-key-base64.txt
```

### 3. Configure Android Secrets

Go to your GitHub repository → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

| Secret Name | Value |
|-------------|-------|
| `ANDROID_KEYSTORE_BASE64` | Base64-encoded keystore file |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore password you set |
| `ANDROID_KEY_PASSWORD` | Key password you set |
| `ANDROID_KEY_ALIAS` | `upload` (or your chosen alias) |
| `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` | Base64-encoded service account JSON |

---

## iOS Setup

### 1. Create Match Certificate Repository

Fastlane Match stores your certificates and provisioning profiles in a private git repository.

1. Create a **private** repository on GitHub (e.g., `ios-certificates`)
   - Go to GitHub → New repository
   - Name: `ios-certificates` (or similar)
   - **Important:** Set to **Private**
   - Don't initialize with README

2. Create a Personal Access Token (PAT) for this repository:
   - Go to GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
   - Click **Generate new token (classic)**
   - Name: `fastlane-match`
   - Scopes: Select `repo` (full control of private repositories)
   - Click **Generate token**
   - **Copy the token immediately** (you won't see it again)

### 2. Initialize Fastlane Match

Run these commands locally (one-time setup):

```bash
cd ios

# Install dependencies
bundle install

# Initialize Match
bundle exec fastlane match init
```

When prompted:
- Storage mode: Select **git**
- Git URL: Enter your private repo URL (e.g., `https://github.com/your-org/ios-certificates.git`)

```bash
# Generate App Store certificates and profiles
bundle exec fastlane match appstore
```

When prompted:
- Apple ID: Your Apple Developer account email
- Password: Your Apple ID password (or app-specific password if 2FA enabled)
- Match passphrase: Create a strong password to encrypt certificates

**Save the Match passphrase** - you'll need it for the GitHub secret.

### 3. Create App Store Connect API Key

The API key allows automated uploads to App Store Connect without Apple ID login.

#### Step 1: Generate API Key

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Navigate to **Users and Access** → **Integrations** → **App Store Connect API**
3. Click the **+** button to create a new key
4. Name: `Fastlane CI` (or similar)
5. Access: **App Manager** (or Admin for full access)
6. Click **Generate**

#### Step 2: Download and Note Details

1. **Download the .p8 file** immediately (you can only download it once!)
2. Note the **Key ID** (shown in the table)
3. Note the **Issuer ID** (shown at the top of the Keys section)

#### Step 3: Encode the API Key

```bash
# Convert to base64 for GitHub secret
base64 -i AuthKey_XXXXXXXXXX.p8 | pbcopy  # macOS
# OR
base64 -i AuthKey_XXXXXXXXXX.p8 > api-key-base64.txt
```

#### Step 4: Get Team IDs

**Apple Developer Team ID:**
- Go to [Apple Developer Portal](https://developer.apple.com/account)
- Your Team ID is shown in the membership details
- It's also in `ios/fastlane/Appfile` as `team_id`

**App Store Connect Team ID (ITC_TEAM_ID):**
- Go to App Store Connect → Users and Access
- Look at the URL: `https://appstoreconnect.apple.com/access/users/itc_XXXXXXXX`
- The number after `itc_` is your ITC Team ID
- OR run `bundle exec fastlane spaceship` and it will show your teams

### 4. Configure iOS Secrets

Go to your GitHub repository → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

| Secret Name | Value | Example |
|-------------|-------|---------|
| `MATCH_GIT_URL` | Private certificates repo URL | `https://github.com/your-org/ios-certificates.git` |
| `MATCH_GIT_BASIC_AUTH` | `username:personal_access_token` | `myusername:ghp_xxxxxxxxxxxx` |
| `MATCH_PASSWORD` | Passphrase you set during `match init` | (your passphrase) |
| `KEYCHAIN_PASSWORD` | Any secure password for CI keychain | (generate a random password) |
| `APP_STORE_CONNECT_KEY_ID` | Key ID from App Store Connect | `ABC123XYZ` |
| `APP_STORE_CONNECT_ISSUER_ID` | Issuer ID from App Store Connect | `12345678-1234-1234-1234-123456789012` |
| `APP_STORE_CONNECT_KEY_CONTENT` | Base64-encoded .p8 key file | (base64 string) |
| `APPLE_ID` | Your Apple Developer email | `developer@example.com` |
| `ITC_TEAM_ID` | App Store Connect Team ID | `123456789` |

---

## Running the Deployment

Once all secrets are configured:

1. Go to your GitHub repository
2. Click **Actions** tab
3. Select **Deploy to Stores** workflow
4. Click **Run workflow**
5. Fill in:
   - **Platform:** android, ios, or both
   - **Version name:** e.g., `1.0.0`
   - **Build number:** e.g., `1` (must be unique and incrementing)
6. Click **Run workflow**

### Version Numbers

- **Version name** (build-name): User-visible version string (e.g., `1.2.3`)
- **Build number** (build-number): Internal integer that must increment with each upload
  - Google Play: Each upload must have a higher `versionCode`
  - App Store: Each upload must have a higher `CFBundleVersion`

---

## Troubleshooting

### Android Issues

**"Version code already exists"**
- Increase the build number to a higher value than any previous upload

**"APK/AAB signed with wrong key"**
- Ensure you're using the same keystore that was used for the first upload
- If this is a new app, you may need to use Play App Signing

**"Service account doesn't have permission"**
- Verify the service account has release permissions in Play Console
- Wait a few minutes after granting permissions

### iOS Issues

**"Match: Could not decrypt"**
- Verify `MATCH_PASSWORD` matches the passphrase used during `match init`

**"Could not find a matching code signing identity"**
- Run `bundle exec fastlane match appstore --force` locally to regenerate certificates
- Ensure the bundle ID matches your app

**"Invalid App Store Connect API Key"**
- Verify Key ID and Issuer ID are correct
- Ensure the .p8 file was base64-encoded correctly
- Check that the API key has App Manager or Admin access

**"Keychain not found"**
- The `KEYCHAIN_PASSWORD` can be any password - it's used to create a temporary keychain on CI

### General Issues

**"Bundle install failed"**
- Ensure `Gemfile` exists in the platform directory
- Try running `bundle install` locally first

**"Flutter build failed"**
- Run `melos run prepare` locally to ensure the project builds
- Check for any missing dependencies

---

## Security Best Practices

1. **Never commit secrets** to the repository
2. **Use repository secrets** instead of organization secrets for sensitive keys
3. **Rotate keys periodically** - generate new API keys and service accounts annually
4. **Limit permissions** - grant only necessary permissions to service accounts
5. **Back up your keystore** - losing the Android keystore means you cannot update your app
6. **Use a private repo** for Match certificates - never make it public

---

## Quick Reference: All Required Secrets

### Android (5 secrets)
```
ANDROID_KEYSTORE_BASE64
ANDROID_KEYSTORE_PASSWORD
ANDROID_KEY_PASSWORD
ANDROID_KEY_ALIAS
GOOGLE_PLAY_SERVICE_ACCOUNT_JSON
```

### iOS (9 secrets)
```
MATCH_GIT_URL
MATCH_GIT_BASIC_AUTH
MATCH_PASSWORD
KEYCHAIN_PASSWORD
APP_STORE_CONNECT_KEY_ID
APP_STORE_CONNECT_ISSUER_ID
APP_STORE_CONNECT_KEY_CONTENT
APPLE_ID
ITC_TEAM_ID
```
