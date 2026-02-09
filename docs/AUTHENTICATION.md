# Authentication Implementation

## Overview
The authentication system has been updated to allow users to input their custom server URL and password. The credentials are validated against the server and stored locally for automatic login on subsequent app launches.

## Features

### 1. **Custom Server URL Input**
- Users can enter their server URL (e.g., `192.168.1.100:8080`)
- The system automatically adds `http://` protocol if not provided
- Trailing slashes are automatically removed for consistency

### 2. **Password Authentication**
- Password field with visibility toggle
- Secure password input with obscure text option

### 3. **Connection Validation**
- Before saving credentials, the app validates the connection by calling `/login` endpoint
- Only successful connections (HTTP 200 response) are saved
- Clear error messages if connection fails

### 4. **Local Storage**
- Server URL and password are saved to `SharedPreferences`
- Automatic login on app restart if credentials exist
- Users don't need to re-enter credentials after successful connection

### 5. **Error Handling**
- Input validation for empty fields
- Network error handling with user-friendly messages
- Visual error display with icon and colored container

## Architecture

### Files Modified/Created

1. **`lib/core/storage/storage_service.dart`** (NEW)
   - Manages local storage using SharedPreferences
   - Methods: `saveServerUrl()`, `getServerUrl()`, `savePassword()`, `getPassword()`, `clearAll()`, `hasCredentials()`

2. **`lib/core/network/api_client.dart`** (MODIFIED)
   - Now accepts dynamic `baseUrl` parameter
   - Added `setBaseUrl()` method to update URL at runtime
   - Removed hardcoded localhost URLs

3. **`lib/features/auth/providers/auth_provider.dart`** (MODIFIED)
   - Changed from `StateNotifier<String?>` to `StateNotifier<AuthState>`
   - Added `AuthState` model with `serverUrl`, `password`, and `isAuthenticated`
   - Implements auto-login from stored credentials
   - URL formatting and validation logic
   - Integration with `StorageService`

4. **`lib/features/auth/presentation/login_screen.dart`** (MODIFIED)
   - Added Server URL input field
   - Added password visibility toggle
   - Improved UI matching the design mockup
   - Better error handling and display
   - Form validation

5. **`lib/core/router/app_router.dart`** (MODIFIED)
   - Updated to work with new `AuthState` model
   - Uses `authState.isAuthenticated` instead of null check

## Usage Flow

### First Time Login
1. User opens the app
2. Login screen is displayed
3. User enters server URL (e.g., `192.168.1.100:8080`)
4. User enters password
5. User clicks "Connect"
6. App validates connection with server
7. If successful:
   - Credentials are saved to local storage
   - User is redirected to home screen
8. If failed:
   - Error message is displayed
   - User can retry

### Subsequent Launches
1. User opens the app
2. App checks for stored credentials
3. If credentials exist:
   - Auto-login is attempted
   - If successful, user goes directly to home screen
   - If failed, login screen is shown
4. If no credentials exist:
   - Login screen is shown

### Logout
When user logs out:
- All stored credentials are cleared
- User is redirected to login screen
- Must re-enter server URL and password

## API Integration

The authentication validates against the backend `/login` endpoint:

**Request:**
```json
POST /login
{
  "password": "user_password"
}
```

**Expected Response:**
```json
HTTP 200 OK
```

Any other response code is treated as authentication failure.

## Security Considerations

1. **Password Storage**: Passwords are stored in SharedPreferences. For production, consider using `flutter_secure_storage` for encrypted storage.
2. **HTTPS**: The system supports both HTTP and HTTPS. For production, enforce HTTPS only.
3. **Token Management**: Currently using password as token. Consider implementing proper JWT tokens in production.

## UI Design

The login screen follows the design mockup with:
- Clean, modern interface
- Primary color (#4A6FA5) for branding
- Rounded input fields with proper borders
- Error messages in red with icon
- Loading state with spinner
- Responsive layout with SafeArea and SingleChildScrollView

## Dependencies Added

```yaml
shared_preferences: ^2.5.4
```

This package is used for local storage of credentials.

## Future Enhancements

1. **Secure Storage**: Migrate to `flutter_secure_storage` for encrypted credential storage
2. **Biometric Auth**: Add fingerprint/face recognition for quick login
3. **Multiple Servers**: Allow users to save and switch between multiple server configurations
4. **Remember Me**: Add option to not save credentials
5. **Token Refresh**: Implement token refresh mechanism for better security
