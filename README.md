<div align="center">
  <img width="150" src="assets/logo.png" alt="POS Logo">
  
  # POS (Point of Sale)

  **An open-source, offline-first Point of Sale (POS) application built with Flutter.**

  [![Flutter](https://img.shields.io/badge/Flutter-3.47+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
  [![Dart](https://img.shields.io/badge/Dart-3.13+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
  [![Platform](https://img.shields.io/badge/Platform-Android%20|%20Windows%20|%20macOS%20|%20iOS-lightgrey)]()
  [![Database](https://img.shields.io/badge/Database-Isar%20Offline%20%2B%20Supabase-blue)]()

  <br />

</div>

---

## 📌 Overview

**POS** is a cross-platform Point of Sale and store management application designed with an **offline-first architecture** and a brand new **Modern POS (Beta)** user interface. It allows retail and rental businesses to manage sales, track inventory, handle barcode scanning, print receipts via thermal printers, and sync data seamlessly with cloud backends (Supabase). The application features a fully English user interface, Dark Mode compatibility, and is configured for Malaysian Ringgit (RM) by default.

---

## 📸 Screenshots

| | |
|---|---|
| ![Modern POS checkout](screenshots/pos_modern.png) | ![Awaiting Orders](screenshots/awaiting_orders.png) |
| *Modern POS — catalog, cart & payment* | *Awaiting Orders — Cancel / Mark as Done* |
| ![Reports & Analytics](screenshots/reports.png) | ![Backup & Restore](screenshots/backup_restore.png) |
| *Reports & Analytics* | *Owner Dashboard — Backup / Restore database* |

<p align="center">
  <img width="70%" src="screenshots/month_picker.png" alt="Month picker"><br/>
  <i>Monthly Report — month picker export</i>
</p>

---

## ✨ Features

### 📦 1. Inventory Management
- **Full CRUD Operations**: Add, edit, view, and delete inventory items.
- **Search & Filter**: Real-time item lookup by name, category, or SKU.
- **CSV Data Import/Export**: Bulk import inventory data and export stock reports to CSV.
- **Low Stock Alerts**: Out-of-stock and low-stock indicators.

### 💳 2. Sales & Checkout
- **Cart & Order Processing**: Fast product addition, discount handling, and order summary.
- **Order Fulfillment (Awaiting Orders)**: Paid orders enter an *Awaiting Orders* queue — the worker taps **Mark as Done** when fulfilled, or **Cancel** to void the order (line items automatically return to stock). Revenue reports count **fulfilled orders only**, so sales appear the moment an order is actually handed over.
- **Thermal Printing**: Direct ESC/POS thermal receipt printing via Bluetooth and USB (Windows & Android).
- **Cash Drawer Integration**: Automatically triggers cash drawer kick-out on transaction completion.
- **Multi-currency Support**: Default currency formatted in Malaysian Ringgit (`RM`).

### 📊 3. Analytics & Reporting
- **Sales Insights**: Real-time sales comparison (Today vs. Yesterday).
- **Revenue & Profit Breakdown**: Gross revenue, estimated profit, and expense tracking.
- **Best Sellers**: Automatic ranking of top-performing items.
- **Visual Charts**: Interactive revenue and visitor traffic charts by date range.
- **Monthly Report PDF**: Export any calendar month via a dedicated **month picker** (future months disabled). The paginated PDF includes an explicit period line, revenue/orders/expenses/profit summary cards, payment-method breakdown, best sellers, a daily breakdown table, and a clear "No fulfilled sales in this period" notice when the month was empty.
- **Export & Receipts**: Formal per-sale PDF receipts/invoices.

### 👥 4. Customer & User Management
- **Customer Directory**: Store contact information, transaction history, and purchase logs.
- **Role-Based Access**: Multi-user support with role-based permissions and admin controls.

### 🔄 5. Offline-First & Cloud Sync
- **Local Database (Isar)**: Lightning-fast, ACID-compliant offline database for zero-latency local operations.
- **Cloud Synchronization**: Optional two-way background sync with **Supabase**.
- **Portable Backup & Restore**: Export the whole database as a **JSON backup (`.posbackup`)** — validated before anything is written and restored atomically in a single transaction. Backups travel between devices (send via WhatsApp/Telegram as a *document*), survive schema differences between app versions, and restore without an app restart. Legacy `.isar` file restore is still supported, now with validate-before-swap so a corrupt/incompatible file can never destroy live data.

### 🏢 6. Additional Modules
- **Payroll Management**: Salary calculations, custom bonus/deduction line items, and PDF payslip generation.
- **Modern POS UI**: A completely revamped tablet-optimized and Dark Mode compatible Staff and Owner Dashboard — including staff **PIN quick sign-in** ("Who's working?" picker) and an Owner Dashboard with sales overview and database settings.

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
