# 📦 Track My Order

**One Place for All Your Online Orders**

Track My Order is a Flutter-based application designed to help users manage and monitor their online shopping orders from different platforms in one place. It provides a centralized interface to organize orders, view tracking timelines, and explore delivery progress.

🌐 **Live Website:** https://trackmyorder-ab1cb.web.app

💻 **GitHub Repository:** https://github.com/Praharshitha07/TrackMyOrder

## ✨ Features

- **User Authentication:** Secure login and registration using Firebase Authentication.
- **Order Management:** Add, edit, view, and delete orders.
- **Centralized Order Tracking:** Manage orders from multiple shopping platforms in one application.
- **Order Timeline:** View order progress through different tracking stages.
- **Demo Tracking:** Explore simulated tracking updates for demonstration purposes.
- **Map View:** View a sample delivery route when demo tracking is enabled.
- **Analytics:** Get an overview of order information.
- **Cloud Storage:** Store user orders using Cloud Firestore.
- **Responsive Interface:** Supports Android and web platforms.

## 🛠️ Technologies Used

| Technology | Purpose |
|---|---|
| Flutter | Frontend development |
| Dart | Programming language |
| Provider | State management |
| GoRouter | Application navigation |
| Firebase Authentication | User authentication |
| Cloud Firestore | Cloud database |
| Firebase Hosting | Web application deployment |
| Git & GitHub | Version control |

## 🏗️ System Architecture

The application follows a layered architecture that separates the user interface, state management, navigation, and data operations.

```text
              +----------------------+
              |         USER         |
              +----------------------+
                         |
                         v
              +----------------------+
              |    FLUTTER UI LAYER  |
              |   Screens & Widgets  |
              +----------------------+
                         |
                         v
              +----------------------+
              |  STATE MANAGEMENT   |
              |       Provider       |
              +----------------------+
                         |
                         v
              +----------------------+
              |   NAVIGATION LAYER  |
              |       GoRouter       |
              +----------------------+
                         |
                         v
              +----------------------+
              |   REPOSITORY LAYER  |
              +----------------------+
                         |
                  +------+------+
                  |             |
                  v             v
          +---------------+  +----------------+
          |    FIREBASE   |  | CLOUD FIRESTORE|
          | AUTHENTICATION|  |   ORDER DATA   |
          +---------------+  +----------------+
                  |             |
                  +------+------+
                         |
                         v
              +----------------------+
              |      USER DATA       |
              +----------------------+
```

### Application Workflow

```text
       +-------------------------+
       |    Open Application     |
       +-------------------------+
                   |
                   v
       +-------------------------+
       |     Login / Signup      |
       +-------------------------+
                   |
                   v
       +-------------------------+
       | Firebase Authentication |
       +-------------------------+
                   |
                   v
       +-------------------------+
       |     Home Dashboard      |
       +-------------------------+
                   |
          +--------+--------+
          |        |        |
          v        v        v
       +------+ +------+ +-----------+
       | Add  | | View | | Analytics |
       |Order | |Orders| |           |
       +------+ +------+ +-----------+
                   |
                   v
       +-------------------------+
       |     Order Details       |
       +-------------------------+
                   |
            +------+------+
            |             |
            v             v
     +-------------+ +-------------+
     |   Timeline  | | Track on Map|
     +-------------+ +-------------+
```

## 📁 Project Structure

```text
TrackMyOrder/
│
├── android/
├── web/
├── lib/
│   ├── core/
│   ├── models/
│   ├── providers/
│   ├── repositories/
│   ├── screens/
│   ├── services/
│   ├── widgets/
│   │
│   ├── app.dart
│   ├── main.dart
│   └── firebase_options.dart
│
├── test/
├── pubspec.yaml
└── README.md
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK
- Dart SDK
- Android Studio or Visual Studio Code
- Firebase account

### Installation

**1. Clone the repository**

```bash
git clone https://github.com/Praharshitha07/TrackMyOrder.git
```

**2. Navigate to the project directory**

```bash
cd TrackMyOrder
```

**3. Install dependencies**

```bash
flutter pub get
```

**4. Configure Firebase**

- Configure Firebase for the Android and web applications.
- Enable Email/Password authentication.
- Create a Cloud Firestore database.
- Configure Firebase options for the project.

**5. Run the application**

```bash
flutter run
```

To run the application in Chrome:

```bash
flutter run -d chrome
```

## 🔥 Firebase Integration

Track My Order uses Firebase services for authentication and cloud data storage.

- **Firebase Authentication:** Handles user registration and login.
- **Cloud Firestore:** Stores and manages users' order information.
- **User Data Isolation:** Each authenticated user accesses their own orders.

### Firestore Database Structure

```text
users/
   |
   +── USER_ID/
          |
          +── orders/
                 |
                 +── ORDER_ID
                 |
                 +── ORDER_ID
```

## 🧪 Testing

The following commands can be used to analyze the application and execute available automated tests.

**Analyze the project:**

```bash
flutter analyze
```

**Run automated tests:**

```bash
flutter test
```

## 🌐 Deployment

**Build the Flutter web application:**

```bash
flutter build web
```

**Deploy using Firebase Hosting:**

```bash
firebase deploy --only hosting
```

## 🔮 Future Enhancements

- Integration with real courier tracking APIs.
- Live delivery status notifications.
- Automatic tracking updates.
- Advanced delivery analytics and predictions.
- Support for additional courier services.

## 👩‍💻 Developer

**Praharshitha Malladi**

B.Tech — Computer Science and Engineering

Vishnu Institute of Technology, Bhimavaram

---

⭐ If you find this project useful, consider giving the repository a star!
