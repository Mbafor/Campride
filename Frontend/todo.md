Create a Flutter mobile application for the KNUST Shuttle Route Finder. This phase is strictly frontend only. Do not implement any backend logic, API calls, Firebase, Supabase, databases, or server communication. Use hardcoded mock data and mock loading states. Build the application in a way that allows backend integration later without major refactoring.

## Architecture and Project Structure

Follow Clean Architecture principles and Flutter best practices.

Organize the project as follows:

lib/

* screens/

  * splash/
  * welcome/
  * auth/
  * student/

    * dashboard/
    * live_map/
    * search/
    * profile/
    * notifications/
  * driver/

    * dashboard/
    * start_trip/
    * trip_history/
    * profile/
* widgets/

  * buttons/
  * cards/
  * inputs/
  * dialogs/
* models/
* providers/
* services/
* constants/
* routes/
* theme/
* utils/

Assets structure:

assets/

* images/
* icons/
* animations/
* fonts/

Use snake_case for files, PascalCase for classes, camelCase for variables, and use const widgets wherever possible.

Enable flutter_lints and follow Flutter best practices.

## Dependencies

Configure pubspec.yaml with:

* google_fonts
* flutter_svg
* go_router
* provider
* google_sign_in
* shared_preferences
* intl
* flutter_lints

## Theme

Create:

theme/

* app_theme.dart
* light_theme.dart
* dark_theme.dart
* app_colors.dart
* text_styles.dart

Use KNUST colors:

Primary Green: #1B5E20
Accent Gold: #FFC107

Support both light mode and dark mode.

Use Google Fonts consistently throughout the application.

## State Management

Use Provider with separate ChangeNotifiers for:

* AuthenticationProvider
* ThemeProvider
* UserRoleProvider

Although data is mocked, structure the providers so they can later connect to Firebase or Supabase without major changes.

## Mock Services

Create:

* mock_auth_service.dart
* mock_route_service.dart
* mock_shuttle_service.dart

These services should contain hardcoded mock data only.

## Models

Create:

* UserModel
* RouteModel
* ShuttleModel
* NotificationModel

Populate them with mock data.

## Navigation

Use go_router with named routes.

Implement smooth custom page transitions:

* Fade transition
* Slide transition
* Duration: 300ms

Implement mock route guards:

If the user is not authenticated, redirect to the login screen.

After login:

* Students navigate to Student Dashboard.
* Drivers navigate to Driver Dashboard.

## Responsive Design

Ensure every screen works correctly on Android and iOS.

Use:

* MediaQuery
* LayoutBuilder

Avoid fixed widths and heights.

Support different phone sizes and tablets.

## Reusable Components

Create reusable widgets:

* AppLogo
* CustomButton
* CustomTextField
* LoadingOverlay
* ErrorBanner
* EmptyStateWidget
* SectionHeader

Use these widgets consistently throughout the project.

## Splash Screen

Dark green background.

Centered KNUST Shuttle logo built entirely using Flutter widgets.

No external images.

Display:

"KNUST Shuttle Finder"

Below the title, show a subtle loading animation.

Automatically navigate to the Welcome Screen after three seconds.

## Welcome Screen

Modern UI using KNUST green and gold colors.

Hero illustration area at the top showing a campus shuttle concept built entirely with Flutter widgets and shapes.

No external images.

Headline:

"Get to class on time, every time"

Subtitle:

"Track KNUST shuttles in real time"

Buttons:

* I am a Student
* I am a Driver

Each button passes a role parameter and navigates to the shared login screen.

Bottom text:

"Powered by KNUST"

## Shared Login Screen

Accept a role parameter.

Show dynamic title:

* Student Login
* Driver Login

Google Sign-In section:

Create the complete UI with Google colors and logo.

No real authentication.

On tap:

* Show loading spinner for two seconds.
* Navigate to the appropriate dashboard.

Below Google Sign-In show:

"Sign in with Google for faster access"

Add an "OR" divider.

Email field:

* Frontend validation.
* Must be a valid email format.

Password field:

* Show/Hide password toggle.
* Minimum eight characters.

Login button:

* Validate inputs.
* Show loading spinner.
* Navigate after two seconds.

Display error widgets when validation fails.

Include a back button to return to the Welcome Screen.

Use a clean professional UI.

## Student Dashboard

AppBar:

"KNUST Shuttle Finder"

Notification bell icon.

Bottom Navigation Bar containing:

1. Live Map
2. Search Route
3. Profile

Each tab should be a separate screen, not placeholders inside one widget.

### Live Map Screen

Centered map icon.

Text:

"Live Map"

Beautiful placeholder card.

### Search Route Screen

Centered search icon.

Text:

"Search Route"

Placeholder design.

### Profile Screen

Centered profile icon.

Display mock user information.

### Notifications Screen

Bell icon.

List of mock notifications.

Use NotificationModel data.

Maintain KNUST colors throughout.

## Driver Dashboard

AppBar:

"Driver Dashboard"

Bottom navigation with:

1. Home
2. Trip History
3. Profile

### Home Screen

Large Start Trip button.

Display current route:

"Brunei Hall → KSB → Unity Hall"

Use hardcoded data.

### Trip History Screen

Display a list of mock trips.

### Profile Screen

Display mock driver information.

## Loading and Error States

Create reusable widgets for:

* Loading state
* Empty state
* Error state
* Mock No Internet state

All states should use hardcoded behavior.

## Animations

Use smooth transitions and animations throughout the application.

Animate:

* Page navigation
* Button loading states
* Fade-ins
* Cards

Keep animations subtle and professional.

## Code Quality

Write clean and maintainable code.

Avoid duplicated code.

Separate UI from business logic.

Use reusable widgets whenever possible.

Prepare the project structure so Firebase or Supabase and real-time shuttle tracking can be integrated later with minimal changes.

The application must run without errors on Android and iOS and should have zero backend dependency.
