<div align="center">
  <img width="150" src="assets/logo.png" alt="POS Logo">
  
  # POS (Point of Sale)

  **An open-source, offline-first Point of Sale (POS) application built with Flutter.**

  [![Flutter](https://img.shields.io/badge/Flutter-3.47+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
  [![Dart](https://img.shields.io/badge/Dart-3.13+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
  [![Platform](https://img.shields.io/badge/Platform-Android%20|%20Windows%20|%20macOS%20|%20iOS-lightgrey)]()
  [![Database](https://img.shields.io/badge/Database-Isar%20Offline%20%2B%20Supabase-blue)]()

  <br />

  [<img src="https://github.com/Shan0h/Pos/assets/20653803/b0af666a-99c3-414a-b9e0-0558e8bee10b" width="250" alt="Get it on Google Play">](https://play.google.com/store/apps/details?id=com.shan0h.pos)

</div>

---

## 📌 Overview

**POS** is a cross-platform Point of Sale and store management application designed with an **offline-first architecture**. It allows retail and rental businesses to manage sales, track inventory, handle barcode scanning, print receipts via thermal printers, and sync data seamlessly with cloud backends (Supabase).

---

## ✨ Features

### 📦 1. Inventory Management
- **Full CRUD Operations**: Add, edit, view, and delete inventory items.
- **Search & Filter**: Real-time item lookup by name, category, or SKU.
- **Barcode Scanning**: Integrated support for hardware barcode scanners and mobile cameras.
- **CSV Data Import/Export**: Bulk import inventory data and export stock reports to CSV.
- **Low Stock Alerts**: Out-of-stock and low-stock indicators.

### 💳 2. Sales & Checkout
- **Cart & Order Processing**: Fast product addition, discount handling, and order summary.
- **Thermal Printing**: Direct ESC/POS thermal receipt printing via Bluetooth and USB (Windows & Android).
- **Cash Drawer Integration**: Automatically triggers cash drawer kick-out on transaction completion.
- **Multi-currency Support**: Default currency formatted in Malaysian Ringgit (`RM`).

### 📊 3. Analytics & Reporting
- **Sales Insights**: Real-time sales comparison (Today vs. Yesterday).
- **Revenue & Profit Breakdown**: Gross revenue, net profit, rent income, and expense tracking.
- **Best Sellers**: Automatic ranking of top-performing items.
- **Visual Charts**: Interactive revenue and visitor traffic charts by date range.
- **Export & Receipts**: PDF receipt and report generation.

### 👥 4. Customer & User Management
- **Customer Directory**: Store contact information, transaction history, and purchase logs.
- **Role-Based Access**: Multi-user support with role-based permissions and admin controls.

### 🔄 5. Offline-First & Cloud Sync
- **Local Database (Isar)**: Lightning-fast, ACID-compliant offline database for zero-latency local operations.
- **Cloud Synchronization**: Optional two-way background sync with **Supabase**.
- **Backup & Restore**: Export local database backups and restore on any device.

### 🏢 6. Additional Modules
- **Rental Tracking**: Flexible rental durations (3-day, weekly, monthly) with overdue penalty calculation.
- **Staff Attendance (Presence)**: Check-in/check-out tracking for staff and cashiers.
- **Payroll Management**: Salary calculations, custom bonus/deduction line items, and PDF payslip generation.

---

## 🛠️ Tech Stack & Architecture

- **Framework**: [Flutter](https://flutter.dev/) (Channel Stable)
- **Language**: [Dart](https://dart.dev/)
- **Local Database**: [Isar Database](https://isar.dev/)
- **Cloud Backend**: [Supabase](https://supabase.com/)
- **State Management**: [Signals for Flutter](https://pub.dev/packages/signals)
- **UI Components**: [Shadcn UI for Flutter](https://shadcn-ui.com/)
- **Hardware Integration**: ESC/POS Thermal Printing (`print_bluetooth_thermal`, `esc_pos_utils`), Camera Barcode Scanner

---

## 🚀 Getting Started

### Prerequisites

Ensure you have the following installed on your development machine:
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (`>= 3.24.0` / recommended `3.47+`)
- [Java JDK 21](https://adoptium.net/) or Android Studio JBR
- [Android Studio](https://developer.android.com/studio) (with Android SDK Command-line tools & NDK)
- [Git](https://git-scm.com/)

### Installation

1. **Clone the repository**:
   ```sh
   git clone https://github.com/Shan0h/Pos.git
   cd Pos
   ```

2. **Install dependencies**:
   ```sh
   flutter pub get
   ```

3. **Configure Environment Variables**:
   Create or verify your Supabase configuration in `lib/utils/env.dart`.

4. **Run the application**:
   ```sh
   # Run on connected device (Android / Windows / Web)
   flutter run
   ```

---

## 📦 Building for Production

### Android (APK)
```sh
flutter build apk --release
```
The release APK will be generated at `build/app/outputs/flutter-apk/app-release.apk`.

### Windows (Desktop)
```sh
flutter build windows --release
```

---

## 👥 Authors & Acknowledgments

- **Original Author**: [Luthfi](https://github.com/hifiaz) • [LinkedIn](https://linkedin.com/in/luthfiazhari)
- **Maintainer & Contributor**: [Shan0h](https://github.com/Shan0h) • [LinkedIn](https://linkedin.com/in/akmalfauzi34)

---

## 📄 License

This project is licensed under the terms of the MIT License.
