# 🚀 DEV AGENT: Complete Authentication Implementation Prompt

## 📋 MISSION: Implement User Authentication with Data Isolation

You are tasked with implementing **4 comprehensive authentication stories** for the ExpenseTracker Flutter app using **Context7 Supabase patterns**. Each user must get **ONLY their own data** through proper authentication and RLS policies.

---

## 🎯 IMPLEMENTATION OBJECTIVE

**Primary Goal:** Add Supabase authentication so every user (anonymous or authenticated) gets isolated access to their own expense data only.

**Key Requirements:**
- ✅ Anonymous authentication with unique user IDs for data isolation
- ✅ Email/password authentication with account upgrade capabilities  
- ✅ Seamless UI integration without disrupting existing workflows
- ✅ Comprehensive testing and error handling
- ✅ All Context7 /supabase/supabase-flutter modern patterns

---

## 📚 STORY IMPLEMENTATION ORDER & STATUS TRACKING

### **STORY 2.6: Anonymous Authentication Implementation**
**Status: 🔴 NOT STARTED**  
**File:** `docs/stories/2.6.anonymous-auth-implementation.md`

**IMPLEMENTATION CHECKLIST:**
- [ ] **Task 1: Implement Anonymous Authentication Service** (AC: 1, 2, 4)
  - [ ] Create `AuthenticationService` class in `lib/core/services/authentication_service.dart`
  - [ ] Implement `signInAnonymously()` method using `supabase.auth.signInAnonymously()`
  - [ ] Add session persistence using Supabase's automatic session management
  - [ ] Implement `getCurrentUser()` method to get anonymous user ID
  - [ ] Add `signOut()` method for clearing anonymous sessions

- [ ] **Task 2: Integrate with Startup Guard System** (AC: 6, 7)
  - [ ] Modify `StartupGuard` in `lib/core/startup/startup_guard.dart`
  - [ ] Add anonymous authentication step after Supabase configuration validation
  - [ ] Implement fallback to offline-only mode on authentication failure
  - [ ] Add authentication state to startup validation flow

- [ ] **Task 3: Update Authentication State Management** (AC: 1, 4)
  - [ ] Create `AuthenticationNotifier` provider using Riverpod AsyncNotifier pattern
  - [ ] Listen to `supabase.auth.onAuthStateChange` for auth events
  - [ ] Implement authentication state enum: `unauthenticated`, `anonymous`, `authenticated`
  - [ ] Handle authentication persistence across app restarts

- [ ] **Task 4: Modify Data Sources for User Context** (AC: 2, 5)  
  - [ ] Update all remote data sources to include user context from auth.uid()
  - [ ] Modify expense sync operations to associate data with authenticated user ID
  - [ ] Update sync metadata to track user-specific sync states
  - [ ] Ensure RLS policies work correctly with anonymous user IDs

- [ ] **Task 5: Data Migration for Existing Users** (AC: 3, 5)
  - [ ] Create migration service to associate existing local data with new anonymous user
  - [ ] Implement one-time migration flag in local storage
  - [ ] Update sync orchestrator to handle initial data sync for new anonymous users
  - [ ] Add migration status tracking and error handling

- [ ] **Task 6: Testing and Integration** (AC: 1-7)
  - [ ] Write unit tests for `AuthenticationService`
  - [ ] Test startup flow with and without network connectivity  
  - [ ] Test authentication state transitions and persistence
  - [ ] Test data isolation between different anonymous users
  - [ ] Integration tests for auth failure fallback scenarios

**CONTEXT7 PATTERNS FOR STORY 2.6:**
```dart
// Anonymous authentication
final response = await supabase.auth.signInAnonymously();

// Session management (automatic persistence)
await Supabase.initialize(
  url: 'SUPABASE_URL',
  anonKey: 'SUPABASE_ANON_KEY',
);

// Authentication state listening
final subscription = supabase.auth.onAuthStateChange.listen((data) {
  final AuthChangeEvent event = data.event;
  final Session? session = data.session;
});
```

---

### **STORY 2.7: User Account Management System**
**Status: 🔴 NOT STARTED** (Depends on Story 2.6)  
**File:** `docs/stories/2.7.user-account-management.md`

**IMPLEMENTATION CHECKLIST:**
- [ ] **Task 1: Extend Authentication Service** (AC: 1, 2, 3, 4)
  - [ ] Add `signUpWithEmail()` method to `AuthenticationService`
  - [ ] Implement `signInWithPassword()` using Context7 patterns
  - [ ] Add `sendPasswordReset()` method for password recovery
  - [ ] Implement account upgrade from anonymous to email/password
  - [ ] Add user account information retrieval methods

- [ ] **Task 2: Data Migration and Account Linking** (AC: 1, 2, 5)
  - [ ] Create `AccountMigrationService` for anonymous-to-authenticated transitions
  - [ ] Implement data ownership transfer preserving all user data
  - [ ] Update sync metadata during account upgrades
  - [ ] Handle user ID transitions in local and remote data sources
  - [ ] Add rollback mechanism for failed account migrations

- [ ] **Task 3: Authentication State Management Updates** (AC: 1-4)
  - [ ] Extend `AuthenticationNotifier` for email/password states
  - [ ] Add authentication method tracking (`anonymous`, `email`)
  - [ ] Implement user profile information management
  - [ ] Handle authentication method transitions and state persistence
  - [ ] Add authentication error state management

- [ ] **Task 4: Account Management UI** (AC: 7, 8)
  - [ ] Create `AccountManagementScreen` in `lib/features/settings/presentation/views/`
  - [ ] Design sign-up/sign-in forms with validation
  - [ ] Add password reset request UI
  - [ ] Implement account upgrade flow with confirmation dialogs
  - [ ] Add authentication status display in settings
  - [ ] Design error handling UI with user-friendly messages

- [ ] **Task 5: Settings Integration** (AC: 7)
  - [ ] Add account management section to existing settings screen
  - [ ] Create navigation to account management features
  - [ ] Add user authentication status display
  - [ ] Implement sign-out functionality from settings
  - [ ] Add account type indicator (Anonymous vs Email)

- [ ] **Task 6: Password Reset Flow** (AC: 6, 8)
  - [ ] Implement password reset request screen
  - [ ] Add email input validation and sending confirmation
  - [ ] Handle password reset deep links (if applicable)
  - [ ] Create password reset success/error feedback
  - [ ] Add password reset option to sign-in screen

- [ ] **Task 7: Comprehensive Testing** (AC: 1-8)
  - [ ] Unit tests for extended authentication service methods
  - [ ] Test account migration scenarios and data preservation
  - [ ] Test authentication state transitions and edge cases
  - [ ] Widget tests for all new UI components
  - [ ] Integration tests for complete authentication flows
  - [ ] Test error handling and recovery scenarios

**CONTEXT7 PATTERNS FOR STORY 2.7:**
```dart
// Email/password signup
await supabase.auth.signUp(email: email, password: password);

// Email/password signin
await supabase.auth.signInWithPassword(email: email, password: password);

// Password reset
await supabase.auth.signInWithOtp(email: 'user@example.com');

// User profile management
final res = await supabase.auth.updateUser(
  UserAttributes(
    email: 'new@email.com',
    data: {'username': 'new_username'},
  ),
);
```

---

### **STORY 2.8: Authentication UI Integration and User Experience**
**Status: 🔴 NOT STARTED** (Depends on Stories 2.6 & 2.7)  
**File:** `docs/stories/2.8.auth-ui-integration.md`

**IMPLEMENTATION CHECKLIST:**
- [ ] **Task 1: Main App Authentication Indicators** (AC: 1, 2)
  - [ ] Add authentication status widget to main navigation bar
  - [ ] Create sync status indicator that shows auth state (anonymous/authenticated)
  - [ ] Design subtle visual indicators for account type
  - [ ] Add optional account upgrade prompt in header for anonymous users
  - [ ] Implement tap handlers for quick access to authentication features

- [ ] **Task 2: First-Time User Onboarding** (AC: 3)
  - [ ] Create optional authentication onboarding screens
  - [ ] Design progressive disclosure for authentication benefits
  - [ ] Add "Skip for now" option to continue with anonymous authentication  
  - [ ] Create onboarding preference storage to avoid repeated prompts
  - [ ] Implement onboarding completion tracking

- [ ] **Task 3: Enhanced Settings Authentication Section** (AC: 4, 5)
  - [ ] Redesign settings screen with prominent authentication section
  - [ ] Add visual account type indicators with clear benefits
  - [ ] Create contextual upgrade prompts for anonymous users
  - [ ] Add quick authentication actions (sign out, account settings)
  - [ ] Design account information display for authenticated users

- [ ] **Task 4: Authentication Loading and Progress States** (AC: 6)
  - [ ] Create reusable loading indicators for auth operations
  - [ ] Design progress indicators for account migration processes
  - [ ] Add loading overlays for authentication screens
  - [ ] Implement timeout handling with user feedback
  - [ ] Create success/error animation feedback

- [ ] **Task 5: Consistent Authentication UI System** (AC: 7)
  - [ ] Create authentication UI component library  
  - [ ] Design consistent form styling and validation patterns
  - [ ] Implement reusable authentication error display components
  - [ ] Create standardized button styles for auth actions
  - [ ] Add authentication-specific color schemes and iconography

- [ ] **Task 6: Accessibility Implementation** (AC: 8)
  - [ ] Add semantic labels to all authentication UI elements
  - [ ] Implement proper focus management for authentication forms
  - [ ] Add screen reader support for authentication status indicators
  - [ ] Create high contrast alternatives for authentication UI
  - [ ] Test keyboard navigation for all authentication flows

- [ ] **Task 7: Integration Testing and Polish** (AC: 1-8)
  - [ ] Test authentication UI across different screen sizes
  - [ ] Verify consistent behavior across authentication states
  - [ ] Test accessibility features with screen readers
  - [ ] Performance testing for authentication UI components
  - [ ] User experience testing for onboarding and upgrade flows

---

### **STORY 2.9: Authentication Testing and Comprehensive Error Handling**
**Status: 🔴 NOT STARTED** (Depends on Stories 2.6, 2.7 & 2.8)  
**File:** `docs/stories/2.9.auth-testing-error-handling.md`

**IMPLEMENTATION CHECKLIST:**
- [ ] **Task 1: Comprehensive Unit Testing** (AC: 1)
  - [ ] Unit tests for `AuthenticationService` covering all methods and edge cases
  - [ ] Unit tests for `AccountMigrationService` with data integrity verification
  - [ ] Provider tests for all authentication Riverpod providers
  - [ ] Mock Supabase client responses for consistent testing
  - [ ] Error scenario testing for all authentication operations
  - [ ] Code coverage analysis and reporting setup

- [ ] **Task 2: Integration and End-to-End Testing** (AC: 2, 5)
  - [ ] Complete authentication workflow integration tests
  - [ ] Cross-session persistence testing with app restart simulation
  - [ ] Authentication state synchronization testing across multiple screens
  - [ ] Data migration integration tests with real local database
  - [ ] Network connectivity change testing during authentication
  - [ ] Authentication service degradation and recovery testing

- [ ] **Task 3: Robust Error Handling System** (AC: 3, 4)
  - [ ] Create comprehensive authentication error taxonomy
  - [ ] Implement user-friendly error message mapping
  - [ ] Add error recovery suggestions and automatic retry mechanisms
  - [ ] Create error logging and reporting system for authentication failures
  - [ ] Implement graceful degradation for authentication service outages
  - [ ] Add connectivity-aware error handling

- [ ] **Task 4: Performance and Load Testing** (AC: 6)
  - [ ] Authentication operation performance benchmarking
  - [ ] UI responsiveness testing during authentication operations
  - [ ] Memory usage profiling for authentication state management
  - [ ] Concurrent authentication operation testing
  - [ ] Large dataset migration performance testing
  - [ ] Authentication provider state change performance analysis

- [ ] **Task 5: Security Testing and Validation** (AC: 7)
  - [ ] Authentication token security validation
  - [ ] Session hijacking prevention testing
  - [ ] Unauthorized access attempt handling
  - [ ] Data isolation validation between users
  - [ ] Authentication state tampering prevention
  - [ ] Secure credential storage verification

- [ ] **Task 6: Documentation and Maintenance Guides** (AC: 8)
  - [ ] Authentication architecture documentation
  - [ ] Troubleshooting guide for common authentication issues
  - [ ] Developer guide for extending authentication functionality
  - [ ] User guide for authentication features and benefits
  - [ ] Monitoring and alerting setup documentation
  - [ ] Authentication system maintenance procedures

---

## 🔧 DEVELOPMENT SETUP & ENVIRONMENT

### **Required Configuration**
```bash
# Run with Supabase authentication support
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your_anon_key_here
```

### **Context7 Integration Requirements**
- **Primary Documentation Source:** `/supabase/supabase-flutter` with 158 code snippets
- **Authentication Patterns:** Modern v1.0.0+ API patterns
- **State Management:** Stream-based authentication state management
- **Error Handling:** Comprehensive error taxonomy and recovery

### **Quality Commands (Run After Each Task)**
```bash
# Run comprehensive tests
flutter test

# Run with coverage (must achieve targets)
flutter test --coverage

# Code analysis (must pass)  
flutter analyze

# Quality check script
./scripts/quality_check.sh
```

---

## 📊 SUCCESS CRITERIA & VALIDATION

### **Functional Validation**
- [ ] Anonymous authentication works on first app launch
- [ ] Each user sees ONLY their own data (complete isolation)
- [ ] Account upgrade preserves all existing data
- [ ] Email/password authentication with password reset
- [ ] Authentication UI enhances rather than complicates UX
- [ ] Comprehensive error handling with user-friendly messages

### **Performance Benchmarks**
- [ ] Anonymous authentication: < 500ms
- [ ] Email/password authentication: < 2000ms
- [ ] Account migration: < 5000ms for typical datasets
- [ ] No UI blocking during authentication operations

### **Testing Coverage Requirements**
- [ ] 95%+ code coverage for authentication services
- [ ] 90%+ coverage for authentication providers  
- [ ] 80%+ coverage for authentication UI components
- [ ] Complete integration test coverage for all flows

---

## 🚨 CRITICAL IMPLEMENTATION NOTES

### **Data Isolation Security (HIGHEST PRIORITY)**
Every authentication implementation MUST ensure:
```sql
-- RLS Policy Pattern (already exists - your code must work with this)
CREATE POLICY "Users can only access their own data" 
ON expenses FOR ALL 
USING (user_id = auth.uid());
```

**This means:**
- Anonymous users get unique `auth.uid()` values
- Each user can ONLY see their own expense data
- Account upgrades preserve the same user identity
- Zero cross-user data access is possible

### **Context7 Authentication Patterns (MANDATORY)**
All authentication code MUST use these modern patterns:

```dart
// ✅ CORRECT: Modern anonymous authentication
final response = await supabase.auth.signInAnonymously();

// ✅ CORRECT: Modern email/password (v1.0.0+)
await supabase.auth.signInWithPassword(email: email, password: password);

// ✅ CORRECT: Stream-based state management
final subscription = supabase.auth.onAuthStateChange.listen((data) {
  final AuthChangeEvent event = data.event;
  final Session? session = data.session;
});
```

### **Clean Architecture Integration**
- Follow existing expense feature patterns
- Use Riverpod AsyncNotifier for state management
- Maintain separation of concerns (Domain/Data/Presentation)
- Integrate with existing startup guard and configuration systems

---

## 📋 PROGRESS TRACKING SYSTEM

### **Story Status Updates**
Update each story status as you progress:
- 🔴 **NOT STARTED** → 🟡 **IN PROGRESS** → 🟢 **COMPLETED**

### **Task Completion Tracking**
Mark each task checkbox `[ ]` → `[x]` as completed and update the story files.

### **Quality Gates**
Each story must pass these gates before marking complete:
1. ✅ All tasks completed with checkboxes marked
2. ✅ Tests passing with required coverage
3. ✅ Code analysis passing (`flutter analyze`)
4. ✅ Data isolation verified through testing
5. ✅ Context7 patterns correctly implemented

---

## 🎯 FINAL DELIVERABLE

Upon completion, you will have implemented:
- ✅ **Secure user authentication** with complete data isolation
- ✅ **Anonymous and email/password authentication** options
- ✅ **Seamless account upgrade** with data preservation
- ✅ **Modern Context7 Supabase patterns** throughout
- ✅ **Comprehensive testing and error handling**
- ✅ **Production-ready authentication system**

**START WITH STORY 2.6** and follow the dependency order. Each story builds upon the previous ones and contains complete implementation specifications.

---

**Bob (Scrum Master) 🏃 has prepared everything you need. All technical details, Context7 patterns, and implementation requirements are specified in the story files. Focus on delivering secure, isolated user authentication that enhances the existing ExpenseTracker experience.**