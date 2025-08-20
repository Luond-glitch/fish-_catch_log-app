

# 🎣 Fish Catch Log App  

A Flutter mobile app for anglers to record, analyze, and share their fishing adventures. Log catches, track hotspots, and visualize your fishing data with ease.  

## ✨ Key Features  
✅ **Catch Logging**  
- Record species, length, weight, bait/lure used  
- Add photos and notes for each catch  
- Categorize by freshwater/saltwater  

📍 **Location Tracking**  
- Save GPS coordinates of fishing spots  
- View catches on an interactive map  
- Mark private vs. public spots  

📊 **Statistics & Insights**  
- Weekly/monthly catch totals  
- Species breakdown charts  
- Best times/locations for fishing  

🌤️ **Environmental Data**  
- Log weather conditions (temperature, wind)  
- Moon phase tracking  
- Water temperature (manual entry)  

🔗 **Sync & Backup**  
- Local SQLite database (offline support)  
- Optional Firebase Cloud Sync *(if implemented)*  

---

## 🛠️ Installation  

### **Prerequisites**  
- Flutter 3.19+  
- Dart 3.3+  
- Android/iOS development environment  

### **Steps**  
1. Clone the repo:  
   ```bash
   git clone https://github.com/yourusername/fish_catch_log-app.git
   cd fish_catch_log-app
Install dependencies:

bash
flutter pub get
(Optional) Configure Firebase:

Add your google-services.json (Android) or GoogleService-Info.plist (iOS)

Run the app:

bash
flutter run
📂 Project Structure
text
lib/  
├── core/  
│   ├── constants/      # App colors, strings, etc.  
│   ├── utils/         # Helpers (date formatters, validators)  
├── data/  
│   ├── models/        # Catch, Location, Weather models  
│   ├── repositories/  # Database operations  
├── features/  
│   ├── catches/       # Catch logging UI + logic  
│   ├── map/          # Location tracking  
│   ├── stats/        # Analytics screens  
└── main.dart         # App entry point  
🧩 Dependencies
Package	Usage
sqflite	Local database storage
google_maps_flutter	Interactive map view
image_picker	Attach photos to catches
flutter_bloc	State management
intl	Date/number formatting
(Run flutter pub outdated to check for updates)

🚀 Roadmap
Social sharing of catches

Export data to CSV/PDF

Integration with weather APIs

⁉️ Support & Contribution
Found a bug? Open an issue.
Want a feature? Submit a PR or reach out!
