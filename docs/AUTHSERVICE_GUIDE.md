# Authentication Service Layer Documentation

## Prerequisite 

All developers must be added as Android Clients to the Google Cloud Auth Platform in order to access Google Auth and login to the App. To add a user, go to APIs and Services -> Google Auth Platform -> Clients

Link- https://console.cloud.google.com/auth/clients?project=homeauditapp&supportedpurview=project

To be added as an Android Client, you must provide your machine's SHA-1 fingerprint. This can be accessed using the following command:

`keytool -list -v -keystore C:\Users\{User}\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android`

Replace {User} with personal name in path

Please contact the project administrators for access to the Google Cloud Auth Platform.

## Purpose and Scope

The Authentication Service Layer provides identity verification and cross-device session continuity for the Home Energy Audit application. Unlike the development-focused local AuthService used in earlier prototypes, this implementation integrates directly with Google Identity Services to provide a lightweight, secure, token-based authentication mechanism without maintaining any credential storage or user registry internally.

---

## Service Architecture Overview

The GoogleAuthService provides the only authentication mechanism in this layer. It encapsulates Google Sign-In flows, token retrieval, and silent session restoration. All identity operations are performed externally by Google; the service merely retrieves and exposes ID tokens for upstream use.

---

## Service Responsibilities

| Service | Primary Purpose | External Dependencies |
|--------|------------------|------------------------|
| GoogleAuthService | Google token acquisition and session handling | Google Sign-In plugin, Google Identity Services |

---

## Authentication Service

The AuthService integrates with the Google Sign-In SDK to authenticate users and return an ID token, which can be passed to backend APIs for verification and user association. No user credentials, profiles, or passwords are ever stored locally by the app.

---

## Key Characteristics

### OAuth-Based Identity Provider Integration

Authentication is performed entirely by Google, ensuring secure and standards-compliant token handling.

### Token-First Design

The service returns a Google ID token (JWT), enabling backend verification and user correlation without maintaining an app-level user registry.

### Cross-Device Sign-In Durability

Silent sign-in attempts allow the app to reauthenticate users automatically across sessions and device changes.

---

## Service Implementation Details

### Initialization Flow

Upon construction, the service initializes the Google Sign-In client:

```dart
await _googleSignIn.initialize(
  clientId: '<web-client-id>',
  serverClientId: '<server-client-id>',
);
```

**Failure Handling:** Initialization issues are logged but do not crash the app.  
If initialization fails, sign-in attempts will throw descriptive errors.  

See Google Cloud Services for information on accessing the IDs and adding Android Client IDs for testing.

---

## Authentication Operations

### 1. User-Initiated Sign-In

**Method:** `signInWithGoogle()`  
**Description:** Prompts the user with the Google authentication UI and returns an ID token.  
**Return Type:** `Future<String?>`

**Flow:**
1. Display Google account picker  
2. Upon success, retrieve `GoogleSignInAuthentication`  
3. Return `idToken` for backend use  

---

### 2. Silent Sign-In

**Method:** `trySilentSignIn()`  
**Description:** Attempts lightweight Google auth without UI.  
**Return Type:** `Future<String?>`

**Use Cases:**
- Auto-login at app startup  
- Preserving sessions across devices  
- Background refresh of ID tokens  

---

### 3. Sign-Out

**Method:** `signOut()`  
**Description:** Invalidates local Google auth state and clears cached sessions.

This logs the user out only within the app; it does not affect the user’s global Google account.

---

## Token Handling & Integration

### What the AuthService Produces

- A Google ID Token (JWT)  
- Signed by Google  
- Used as the app’s primary authentication credential  

---

### How Other Layers Use It

**UserProvider**  
- Verifies ID token and requests email from Google Auth for use in Backend and Database  

**Providers (Riverpod)**  
- Store ephemeral auth state  
- Expose user identity  
- Trigger sign-in flows in the UI  

**Backend**  
- Validates the ID token using Google’s public keys  
- Associates the user with their Database records, including Retrofit tasks and personal information  

---

## Error Handling

The AuthService uses detailed error handling:

- All public methods wrap operations in `try/catch`  
- `null` is returned on recoverable failures (cancellation, silent sign-in failure)  

**Possible Errors and Causes:**
- User cancels Google sign-in  
- Network failures  
- Token retrieval issues  
- Plugin misconfiguration  
- Missing web or server client ID  

---

## Service Dependencies and Integration

### Dependency Injection

The service is initialized through Riverpod providers:

- Enables lazy initialization  
- Allows automatic rebuild when auth state changes  
- Supports test mocking and platform overrides  

---

### Cross-Service Interactions

**AuthService → Backend/login.api**  
- ID tokens are forwarded to backend requests for session validation.  

**AuthService → State Management**  
- Providers store and observe token changes to render authenticated experiences.  
