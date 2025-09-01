# Deep Link Testing Guide

## Test the Email Verification Deep Link

After implementing the deep linking configuration for both Android and iOS, follow these steps to test the email verification flow:

### Android Testing

1. **Install the debug APK**:
   ```bash
   flutter install
   ```

2. **Test the deep link manually**:
   ```bash
   # Test the deep link using ADB
   adb shell am start \
     -W -a android.intent.action.VIEW \
     -d "io.expensetracker://auth/callback?token=test&type=signup" \
     com.example.expense_tracker
   ```

3. **Sign up with a new user** and check your email for the verification link

4. **Click the verification link** in your email - the app should now open automatically

### iOS Testing

1. **Run on iOS simulator or device**:
   ```bash
   flutter run -d ios
   ```

2. **Test the deep link**:
   ```bash
   # For iOS Simulator
   xcrun simctl openurl booted "io.expensetracker://auth/callback?token=test&type=signup"
   ```

3. **Sign up with a new user** and check your email

4. **Click the verification link** - the app should open automatically

### Verification Steps

When the deep link works correctly, you should see:

1. The app opens when clicking the email verification link
2. The user is automatically signed in (if verification is successful)
3. No browser tab is left hanging
4. The auth state updates properly in your app

### What Was Fixed

The issue was missing deep link configuration:

#### Android (`android/app/src/main/AndroidManifest.xml`)
- Added intent filter for `io.expensetracker://auth` URLs
- Configured `android:autoVerify="true"` for automatic verification

#### iOS (`ios/Runner/Info.plist`)
- Added `CFBundleURLTypes` configuration
- Registered `io.expensetracker` URL scheme

#### Existing Supabase Configuration
- Your `main.dart` already has PKCE flow enabled (`AuthFlowType.pkce`)
- Your `authentication_service.dart` already uses correct redirect URLs
- Deep links will now be handled automatically by Supabase Flutter

### Troubleshooting

If deep linking doesn't work:

1. **Check if the app is installed**: Deep links only work if the app is installed
2. **Verify URL format**: Ensure the email contains `io.expensetracker://auth/callback`
3. **Check Supabase configuration**: Verify the redirect URL in your Supabase dashboard
4. **Test on real device**: Some simulators may have limitations with deep links

### Next Steps

1. Test the flow end-to-end
2. Consider adding deep link handling for password reset flows
3. Add error handling for malformed deep links
4. Test on both development and production Supabase instances