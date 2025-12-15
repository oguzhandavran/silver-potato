# GitHub Secrets Setup for APK Signing

This guide walks you through setting up GitHub Secrets for automated APK signing in the CI/CD pipeline.

## Overview

The GitHub Actions workflow requires signing credentials to build production-ready APKs. These credentials are stored securely as GitHub Secrets.

## Required Secrets

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `KEYSTORE_BASE64` | Base64-encoded keystore file | Long base64 string |
| `KEY_STORE_PASSWORD` | Keystore password | `your-store-password` |
| `KEY_PASSWORD` | Key password | `your-key-password` |
| `KEY_ALIAS` | Key alias name | `upload` |

## Step 1: Generate a Keystore (If You Don't Have One)

If you already have a keystore, skip to Step 2.

### Using keytool (Java)

```bash
keytool -genkey -v \
  -keystore ~/upload-keystore.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias upload
```

You'll be prompted for:
- **Keystore password**: Choose a strong password
- **Key password**: Can be same as keystore password or different
- **Name, Organization, etc.**: Fill in your details

### Important Notes

⚠️ **CRITICAL**: Store your keystore file and passwords securely!
- Keep a backup in a secure location (password manager, secure cloud storage)
- If you lose your keystore, you **cannot** update your published app
- Never commit the keystore file to git

## Step 2: Convert Keystore to Base64

GitHub Secrets require the keystore as a base64-encoded string.

### On macOS/Linux:

```bash
base64 -i upload-keystore.jks | pbcopy
```

Or to save to a file:

```bash
base64 -i upload-keystore.jks > keystore-base64.txt
```

### On Windows (PowerShell):

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("upload-keystore.jks")) | Set-Clipboard
```

Or to save to a file:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("upload-keystore.jks")) | Out-File keystore-base64.txt
```

### On Windows (Git Bash):

```bash
base64 -w 0 upload-keystore.jks | clip
```

## Step 3: Add Secrets to GitHub

### Via GitHub Web Interface

1. Navigate to your repository on GitHub
2. Click **Settings** (top menu)
3. In the left sidebar, click **Secrets and variables** → **Actions**
4. Click **New repository secret**
5. Add each secret:

#### KEYSTORE_BASE64
- **Name**: `KEYSTORE_BASE64`
- **Value**: Paste the base64 string from Step 2
- Click **Add secret**

#### KEY_STORE_PASSWORD
- **Name**: `KEY_STORE_PASSWORD`
- **Value**: Your keystore password
- Click **Add secret**

#### KEY_PASSWORD
- **Name**: `KEY_PASSWORD`
- **Value**: Your key password (same as keystore password if you used the same)
- Click **Add secret**

#### KEY_ALIAS
- **Name**: `KEY_ALIAS`
- **Value**: `upload` (or whatever alias you used)
- Click **Add secret**

### Via GitHub CLI (Optional)

If you have the [GitHub CLI](https://cli.github.com/) installed:

```bash
# Set repository (replace with your username/repo)
REPO="your-username/flutter-shell"

# Add KEYSTORE_BASE64
gh secret set KEYSTORE_BASE64 --repo $REPO < keystore-base64.txt

# Add KEY_STORE_PASSWORD
gh secret set KEY_STORE_PASSWORD --repo $REPO --body "your-store-password"

# Add KEY_PASSWORD
gh secret set KEY_PASSWORD --repo $REPO --body "your-key-password"

# Add KEY_ALIAS
gh secret set KEY_ALIAS --repo $REPO --body "upload"
```

## Step 4: Verify Setup

After adding all secrets, you can verify they're configured:

1. Go to **Settings** → **Secrets and variables** → **Actions**
2. You should see all four secrets listed:
   - ✅ KEYSTORE_BASE64
   - ✅ KEY_STORE_PASSWORD
   - ✅ KEY_PASSWORD
   - ✅ KEY_ALIAS

3. Push a commit to trigger the workflow:

```bash
git commit --allow-empty -m "test: verify signing setup"
git push origin main
```

4. Check the **Actions** tab to see the workflow run

## Workflow Behavior

### With Signing Secrets

When all secrets are configured:
- ✅ Creates keystore from `KEYSTORE_BASE64`
- ✅ Generates `key.properties` file
- ✅ Builds APK with **production signing**
- ✅ APK is ready for Google Play Store
- ✅ Cleans up secrets after build

### Without Signing Secrets

If secrets are missing:
- ⚠️ Workflow still runs successfully
- ⚠️ Builds APK with **debug signing**
- ⚠️ APK can be installed for testing
- ❌ APK **cannot** be uploaded to Play Store

## Security Best Practices

### Do's ✅
- ✅ Use strong, unique passwords
- ✅ Store keystore backup securely offline
- ✅ Use GitHub Secrets for all sensitive data
- ✅ Rotate secrets if compromised
- ✅ Use different keystores for different apps
- ✅ Document who has access to keystore

### Don'ts ❌
- ❌ Never commit keystore files to git
- ❌ Never share keystore passwords in plain text
- ❌ Never use the same keystore for testing and production
- ❌ Never store keystore in unsecured locations
- ❌ Never use weak or simple passwords

## Updating Secrets

To update a secret:

1. Go to **Settings** → **Secrets and variables** → **Actions**
2. Click on the secret name
3. Click **Update secret**
4. Enter the new value
5. Click **Update secret**

## Revoking Access

If your keystore is compromised:

1. **Immediately** delete the GitHub secrets
2. Generate a new keystore
3. If the app is published, you'll need to publish as a new app
   - ⚠️ Users will need to uninstall and reinstall
   - ⚠️ You'll lose existing ratings and reviews

## Alternative: Local Signing

For development or private builds, you can sign locally:

### 1. Create `android/key.properties`:

```properties
storePassword=your-store-password
keyPassword=your-key-password
keyAlias=upload
storeFile=/path/to/upload-keystore.jks
```

### 2. Build locally:

```bash
flutter build apk --release
```

**Note:** The `key.properties` file is gitignored and won't be committed.

## Troubleshooting

### Secret Not Working

**Problem**: Workflow fails with signing errors

**Solution**:
1. Verify base64 encoding is correct
2. Check passwords are correct
3. Ensure alias matches keystore
4. Re-generate and re-add secrets

### Base64 Too Long

**Problem**: GitHub Secret value is too large

**Solution**:
- GitHub Secrets support up to 64KB
- Keystore files are typically 2-5KB (fits easily)
- If too large, you may have extra whitespace in the base64 string
- Use `base64 -w 0` on Linux to avoid line breaks

### Keystore Not Found

**Problem**: Workflow can't find keystore

**Solution**:
- Ensure `KEYSTORE_BASE64` secret is set correctly
- Check workflow logs for base64 decode errors
- Verify the secret name matches exactly

### Testing Without Publishing

To test the signing setup without publishing:

1. Comment out the "Create GitHub Release" step in `.github/workflows/flutter-build.yml`
2. Push to trigger the workflow
3. Check if build succeeds
4. Uncomment when ready to publish

## Resources

- [Android App Signing Documentation](https://developer.android.com/studio/publish/app-signing)
- [GitHub Encrypted Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [Flutter Deployment Guide](https://docs.flutter.dev/deployment/android)

## Support

If you encounter issues:
1. Check the workflow logs in the **Actions** tab
2. Review this documentation
3. Verify all secrets are set correctly
4. Test keystore locally first
