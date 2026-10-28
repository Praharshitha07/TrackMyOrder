📦 Track My Order

One Place for All Your Online Orders

Track My Order is a Flutter-based order management application that helps users organize and track purchases from multiple online shopping platforms in one place. Instead of checking different shopping applications individually, users can manage their orders through a single, clean, and responsive interface.

The application supports Firebase Authentication, cloud-based order storage, and Guest Mode with local storage.

---

🌐 Live Application

Live Website: "Track My Order" (https://trackmyorder-ab1cb.web.app)

GitHub Repository: "TrackMyOrder" (https://github.com/Praharshitha07/TrackMyOrder)

«Replace the placeholder URLs above with your actual Firebase Hosting URL and GitHub repository URL.»

---

✨ Features

🔐 Authentication

- User registration using email and password.
- Secure login through Firebase Authentication.
- Logout functionality.
- Guest Mode for exploring the application without creating an account.
- User-specific cloud order storage.

📦 Order Management

- Add new orders manually.
- View saved orders in one place.
- Edit existing order details.
- Delete individual orders.
- Organize orders by shopping platform.
- Store product names, order IDs, prices, quantities, and delivery information.

🚚 Order Tracking

- Track order statuses through the order management interface.
- Store courier names and tracking numbers.
- Save tracking links and order links when available.
- Maintain expected delivery dates.
- View delivery-related information and tracking events.

«Tracking information is based on the details entered or available in the application. Automatic live tracking from shopping platforms or courier services requires separate integrations.»

🔍 Search, Filter, and Sort

- Search for orders.
- Filter orders by status.
- Filter orders by shopping platform.
- Sort orders using the available sorting options.

☁️ Cloud Storage

- Store authenticated users' orders in Cloud Firestore.
- Retrieve saved orders after logging in again.
- Keep users' cloud orders separated by Firebase user ID.
- Update and delete cloud-stored orders.

👤 Guest Mode

- Access the application without creating an account.
- Store guest orders locally using SharedPreferences.
- Manage guest orders independently of authenticated users' cloud orders.

🎨 User Interface

- Responsive Flutter web interface.
- Midnight Navy, Electric Lime, and Cloud White color palette.
- Dashboard for viewing order information.
- Reusable components and structured application architecture.

---

🛠️ Technology Stack

Technology| Purpose
Flutter| Cross-platform application development
Dart| Application programming language
Firebase Authentication| User registration and login
Cloud Firestore| Cloud database for authenticated users' orders
SharedPreferences| Local storage for Guest Mode
Provider| Application state management
GoRouter| Application navigation
Material 3| User interface components
Git and GitHub| Version control and source code hosting
Firebase Hosting| Web application deployment

---

🎨 Application Theme

Track My Order uses a modern, minimal theme designed for a clean shopping and delivery management experience.

Color| Hex Code| Usage
Midnight Navy| "#111827"| Primary backgrounds and dark UI elements
Electric Lime| "#A3E635"| Accent elements and highlights
Cloud White| "#F8FAFC"| Light backgrounds and content surfaces

---

🏗️ Application Architecture

The application follows a repository-based architecture to separate the user interface, state management, and data storage.

TrackMyOrder/
│
├── lib/
│   ├── models/
│   │   ├── order_model.dart
│   │   ├── tracking_event_model.dart
│   │   └── user_model.dart
│   │
│   ├── providers/
│   │   ├── auth_provider.dart
│   │   └── orders_provider.dart
│   │
│   ├── repositories/
│   │   ├── auth_repository.dart
│   │   ├── firebase_auth_repository.dart
│   │   ├── order_repository.dart
│   │   ├── local_order_repository.dart
│   │   ├── firestore_order_repository.dart
│   │   └── hybrid_order_repository.dart
│   │
│   ├── screens/
│   ├── services/
│   ├── core/
│   ├── app.dart
│   ├── main.dart
│   └── firebase_options.dart
│
├── web/
├── android/
├── test/
├── build/
├── firebase.json
├── .firebaserc
├── pubspec.yaml
└── README.md

«The directory listing is illustrative. Your exact files and subdirectories may differ as development continues.»

How it works

1. The user opens the Flutter application.
2. Firebase Authentication handles registration and login.
3. The application identifies the current user's authentication state.
4. Authenticated users access their orders through Cloud Firestore.
5. Guest users use local storage.
6. Providers manage application state and notify the interface when data changes.
7. Firebase Hosting serves the compiled Flutter web application.

---

☁️ Firebase Configuration

The application uses Firebase services for authentication and cloud storage.

Firebase Authentication

Email/password authentication is used for account creation and login.

Cloud Firestore

Authenticated users' orders are stored under a user-specific collection structure:

users/
└── USER_UID/
    └── orders/
        └── ORDER_ID/
            ├── productName
            ├── platformName
            ├── platformOrderId
            ├── quantity
            ├── price
            ├── status
            └── userId

Each authenticated user's orders are stored separately using their Firebase UID.

Guest Storage

Guest orders are stored locally using SharedPreferences. Guest storage is separate from the cloud order collections.

Security

Firestore security rules restrict authenticated users to their own order data. Firebase client configuration identifies the project; it does not replace database security rules.

Never commit service-account private keys, passwords, or other private credentials to the repository.

---

⚙️ Installation and Setup

Follow these steps to run the application locally.

Prerequisites

Install the following tools:

- Flutter SDK
- Dart SDK, included with Flutter
- Git
- Visual Studio Code or another compatible editor
- A Firebase project

1. Clone the Repository

git clone YOUR_GITHUB_REPOSITORY_URL

Navigate into the project directory:

cd TrackMyOrder

Replace "YOUR_GITHUB_REPOSITORY_URL" with your actual GitHub repository URL.

2. Install Dependencies

flutter pub get

3. Configure Firebase

The project uses Firebase Authentication and Cloud Firestore.

Ensure that:

- Firebase Authentication is enabled.
- Email/password sign-in is enabled.
- Cloud Firestore has been created.
- Firestore security rules restrict access to each user's own orders.
- The Flutter application is configured for the Firebase project.

If setting up the project from scratch, configure Firebase for the platforms you intend to run.

For FlutterFire configuration, install and use the FlutterFire CLI as described in the official documentation:

"FlutterFire documentation" (https://firebase.google.com/docs/flutter/setup)

4. Run the Application

To run the application on a connected device:

flutter run

To run it in Chrome:

flutter run -d chrome

---

🌐 Deploying to Firebase Hosting

Track My Order can be deployed as a Flutter web application using Firebase Hosting.

Step 1: Build the Web Application

flutter build web

Flutter generates the production files in:

build/web/

Step 2: Configure Firebase Hosting

If Hosting has not been initialized:

firebase login
firebase init hosting

Select the existing Firebase project associated with the application.

Use the following Hosting configuration:

- Public directory: "build/web"
- Single-page application rewrites: Yes

Make sure "firebase.json" points to the correct build directory.

Step 3: Deploy

firebase deploy --only hosting

After deployment, Firebase displays the public Hosting URL.

Updating the Live Website

Whenever the application code changes, rebuild and deploy it again:

flutter build web
firebase deploy --only hosting

The website can be updated repeatedly without creating a new Firebase project or changing the Hosting URL.

---

🔄 Git and GitHub Workflow

To save your changes and push them to GitHub:

git status
git add .
git commit -m "Describe your changes"
git push origin main

Review "git status" before staging files. Do not commit private credentials, local secrets, or unnecessary generated files.

Important: A GitHub push does not automatically deploy the Firebase Hosting website unless an automatic deployment workflow has been configured. Without such a workflow, run the build and deployment commands manually.

---

🧪 Testing

The following checks are useful when testing the application:

- Register a new account.
- Log in with an existing account.
- Log out and log back in.
- Add an order and verify it appears in Firestore.
- Edit an order and verify the changes persist.
- Delete an order and verify it is removed from Firestore.
- Refresh the application and verify saved orders remain available.
- Test Guest Mode and local order storage.
- Verify that one authenticated user cannot access another user's orders.
- Test the web application in different browser window sizes.

---

🔮 Future Enhancements

Potential future improvements include:

- Automatic order synchronization from shopping platforms.
- Courier API integrations for live delivery tracking.
- Push notifications for delivery updates.
- Delivery reminders.
- More advanced analytics and order statistics.
- Improved profile management.
- Better offline support and synchronization.
- Additional shopping platform integrations.
- Android application testing and release preparation.
- Enhanced accessibility and responsive layouts.

These are potential improvements and are not necessarily implemented in the current version.

---

⚠️ Current Limitations

- Orders must be entered manually unless a relevant integration is implemented.
- Automatic courier tracking depends on external APIs or supported tracking services.
- Guest orders are stored locally rather than synchronized to the cloud.
- Existing locally stored orders are not automatically migrated to Firestore.
- Cloud operations require an internet connection.
- Notification and reminder behavior depends on the features and permissions implemented in the application.

---

🤝 Contributing

Contributions, suggestions, and improvements are welcome.

1. Fork the repository.
2. Create a feature branch.
3. Implement your changes.
4. Test the application.
5. Submit a pull request describing your changes.

---

👩‍💻 Developer

Developed by: Praharshitha Malladi

GitHub: "Praharshitha07" (https://github.com/Praharshitha07)

---

📄 License

Choose a license before distributing the project for reuse. If you want others to use, modify, and redistribute the source code, consider adding an appropriate open-source license, such as the MIT License.

Until a license is added, do not assume that the repository is licensed for unrestricted reuse.

---

⭐ Track My Order

All your online orders. One organized place.