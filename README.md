# 🌦️ Weather App

A weather application built with **Flutter** and a **Node.js/Express.js backend**. The application allows users to request weather information by city name or by using their current location.


## 🔗 Repository

**GitHub:** [View Source Code]()
## 📸 Screenshots

### 1. Weather Home Screen

<!-- Replace with your first screenshot --><img width="954" height="431" alt="Screenshot 2026-10-26 132838" src="https://github.com/user-attachments/assets/e6f51938-9413-4bd6-88ff-e24e8cccdb0d" />

![Weather Home Screen]

### 2. Weather Information

<img width="957" height="422" alt="Screenshot 2026-10-26 133137" src="https://github.com/user-attachments/assets/81359565-b45a-46ca-9f36-e3b2eca2295d" />


> **Note:** Add your actual screenshots to the `screenshots` folder using the filenames shown above.

## ✨ Features

- 🔍 Search weather information by city.
- 📍 Request weather information using current-location coordinates.
- 🌐 Fetch weather data through a backend API.
- 📱 Flutter-based application interface.

## 🛠️ Tech Stack

- **Frontend:** Flutter, Dart
- **Backend:** Node.js, Express.js
- **API:** Backend weather endpoint

## 📁 Project Structure

```text
weather/
├── frontend/
│   └── lib/
├── backend/
└── README.md
```

*This is a simplified overview. Your actual folder structure may differ.*

## 🚀 Getting Started

### Prerequisites

Install the following tools:

- Flutter SDK
- Dart SDK (included with Flutter)
- Node.js and npm

### 1. Clone the Repository

```bash
git clone YOUR_GITHUB_REPOSITORY_URL
cd weather
```

Replace `YOUR_GITHUB_REPOSITORY_URL` with your actual GitHub repository URL.

### 2. Start the Backend

Open a terminal:

```bash
cd backend
npm install
```

Start the backend using the start script configured in your `package.json`, for example:

```bash
npm run dev
```

If your project uses a different script, use the appropriate command. Configure any required environment variables before starting the server.

### 3. Run the Flutter Frontend

Open another terminal:

```bash
cd frontend
flutter pub get
flutter run
```

### 4. Backend Connection

The frontend currently requests weather information from:

```text
http://127.0.0.1:3000/api/weather?city=Delhi%2C+India
```

Ensure the backend is running on the expected port and that the API URL is configured correctly for your target platform. Android emulators and deployed applications may require a different backend address.



## 👨‍💻 Developer

**Deepak Panchal**

