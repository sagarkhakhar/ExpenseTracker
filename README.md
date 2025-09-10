# 💰 ExpenseTracker - Production Flutter App

<div align="center">
  
  ![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
  ![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
  ![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)
  ![License](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)
  
  **A sophisticated expense tracking application built with Flutter using Clean Architecture, Riverpod state management, and Supabase backend**
  
  📱 Cross-platform • 🎯 Production-ready • 🔒 Offline-first • 🎨 Beautiful UI • 🧪 Well-tested
  
  [🚀 Quick Start](#-quick-start) • [📖 Documentation](#-documentation) • [🏗️ Architecture](#️-architecture) • [🐳 Docker Setup](#-docker--supabase-setup)

</div>

---

## 🌟 Features

### 💳 Core Expense Management
- ✅ Add, edit, delete expenses with validation
- ✅ Smart categories with custom options
- ✅ Receipt photo capture and storage
- ✅ Recurring transaction support

### 📊 Advanced Analytics & Budgeting  
- ✅ Budget management with alerts
- ✅ Financial goal tracking
- ✅ Trend analysis with visual charts
- ✅ Comprehensive statistics dashboard

### 🔍 Smart Features
- ✅ Advanced search and filtering
- ✅ Data export (CSV, JSON)
- ✅ Multi-platform support (iOS, Android, Web)
- ✅ Dark/Light theme adaptation
- ✅ Offline-first with optional cloud sync

### 🌐 Backend & Sync
- ✅ Local-first with Hive database
- ✅ Optional Supabase cloud sync
- ✅ Real-time data synchronization
- ✅ Multi-device support

---

## 🚀 Quick Start

### Prerequisites
- Flutter SDK `>=3.2.3`
- Dart SDK `>=3.0.0`
- Docker Desktop (for Supabase)

### Installation

```bash
# Clone repository
git clone https://github.com/yourusername/ExpenseTracker.git
cd ExpenseTracker

# Install dependencies
flutter pub get

# Generate code
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n

# Set up Supabase database (choose one):
./scripts/setup_supabase.sh fresh-local    # Local development database
# OR
./scripts/setup_supabase.sh fresh-remote   # Remote production database

# Run the app
flutter run
```

### Test the Setup

```bash
# Run all tests
flutter test

# Run static analysis
flutter analyze

# Check overall setup
flutter doctor
```

---

## 📖 Documentation

### 🏗️ Core Documentation

| Document | Description | Audience |
|----------|-------------|----------|
| **[CLAUDE.md](CLAUDE.md)** | Complete development guide & commands | Developers |
| **[Docker Supabase Setup](docs/DOCKER_SUPABASE_SETUP.md)** | Local development with Docker | Developers |
| **[Deployment Workflow](docs/DEPLOYMENT_WORKFLOW.md)** | Local to production deployment | DevOps |
| **[Schema Migration Guide](docs/SCHEMA_MIGRATION_GUIDE.md)** | Database schema management | Backend |

### 📚 Key Guides

#### For **Getting Started** (NEW - SIMPLIFIED):
1. **[Supabase Setup Guide](docs/SUPABASE_SETUP.md)** - ⭐ **SINGLE SETUP GUIDE** (replaces all complex setup docs)
2. **[CLAUDE.md](CLAUDE.md)** - Complete development commands and workflows
3. Follow [Quick Start](#-quick-start) above

#### For **Legacy/Advanced Users**:
1. **[Docker Supabase Setup](docs/DOCKER_SUPABASE_SETUP.md)** - Docker-based local development
2. **[Deployment Workflow](docs/DEPLOYMENT_WORKFLOW.md)** - Complex deployment workflows

**⚡ QUICK TIP**: New users should start with the **[Supabase Setup Guide](docs/SUPABASE_SETUP.md)** - it's much simpler!

---

## 🏗️ Architecture

### 🎯 Clean Architecture with MVVM
```
📱 Presentation Layer (UI/State Management)
    ↓ Riverpod Providers & Widgets
🏛️ Domain Layer (Business Logic)
    ↓ Entities, Use Cases, Repository Interfaces
💾 Data Layer (Storage & Network)
    ↓ Hive (Local) + Supabase (Remote)
```

### 📐 Project Structure
```
lib/
├── core/                    # Shared utilities & services
├── features/               # Feature modules
│   ├── expense/           # 💰 Expense management
│   ├── budget/            # 💳 Budget tracking  
│   ├── statistics/        # 📊 Analytics & reports
│   └── export/            # 📤 Data export
├── shared/                # Shared UI components
└── l10n/                  # 🌍 Internationalization

test/                      # Tests mirror lib structure
docs/                      # Documentation
scripts/                   # Build & deployment scripts
```

### 🔄 Data Flow
1. **UI Event** → Riverpod Provider → Use Case
2. **Use Case** → Repository → Data Source (Hive/Supabase)  
3. **Result** → Provider → UI Update

### 🗄️ Database Architecture
- **Local**: Hive NoSQL database (offline-first)
- **Remote**: Supabase PostgreSQL (optional sync)
- **Sync Strategy**: Bidirectional with conflict resolution

---

## 🐳 Docker & Supabase Setup

### 🏠 Local Development (Recommended)

```bash
# Start local Supabase with Docker
./scripts/supabase-docker.sh start

# Run Flutter app (connects to local Supabase automatically)
flutter run

# Check status
./scripts/supabase-docker.sh status
```

### 🌐 Production Deployment

```bash
# 1. Deploy schema to remote Supabase
./scripts/deploy_schema_updates.sh

# 2. Build app for production
flutter build apk --dart-define-from-file=.env.production

# 3. Test remote connection
flutter run --dart-define-from-file=.env.production
```

**Complete Docker & deployment guide**: **[docs/DOCKER_SUPABASE_SETUP.md](docs/DOCKER_SUPABASE_SETUP.md)**

---

## 🧪 Testing

### Test Coverage
- **Domain Layer**: 95%+ coverage
- **Data Layer**: 90%+ coverage  
- **Presentation Layer**: 85%+ coverage
- **Integration Tests**: End-to-end workflows

### Running Tests
```bash
# All tests
flutter test

# Specific feature tests
flutter test test/features/expense/

# Integration tests
flutter test integration_test/

# With coverage
flutter test --coverage
```

---

## 📦 Build & Deployment

### Development
```bash
flutter run                    # Debug mode
flutter run --release          # Release mode
```

### Production Builds
```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS  
flutter build ios --release

# Web
flutter build web --release

# With environment config
flutter build apk --dart-define-from-file=.env.production
```

### Environment Management
```bash
# Local development (default)
flutter run

# Production environment
flutter run --dart-define-from-file=.env.production

# Custom environment
flutter run --dart-define=SUPABASE_URL=https://your-project.supabase.co
```

---

## 🌍 Internationalization

Full i18n support with Flutter's built-in l10n system:

- **Languages**: English (100%), Spanish (100%)
- **70+ localized strings** across all features
- **Easy to extend**: Add new languages via ARB files

### Adding Localized Strings
1. Add to `lib/l10n/app_en.arb` and `lib/l10n/app_es.arb`
2. Run `flutter gen-l10n` to generate code
3. Use `AppLocalizations.of(context)!.keyName` in UI

---

## 🛠️ Development Commands

### Core Development
```bash
flutter run                                    # Run debug
flutter test                                   # Run tests
flutter analyze                                # Static analysis
dart run build_runner build                    # Code generation
flutter gen-l10n                               # Localization
```

### Docker Supabase Management  
```bash
./scripts/supabase-docker.sh start             # Start services
./scripts/supabase-docker.sh stop              # Stop services
./scripts/supabase-docker.sh status            # Check status
./scripts/supabase-docker.sh reset             # Reset database
```

### Environment & Deployment
```bash
# Local to remote deployment
./scripts/deploy_schema_updates.sh             # Deploy schema
flutter run --dart-define-from-file=.env.production  # Test remote

# Preview deployment changes
./scripts/deploy_schema_updates.sh --dry-run   
```

**Complete command reference**: **[CLAUDE.md](CLAUDE.md)**

---

## 🔧 Troubleshooting

### Common Issues

**Build failures:**
```bash
flutter clean && flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

**Supabase connection issues:**
```bash
./scripts/supabase-docker.sh status
./scripts/supabase-docker.sh restart
```

**Schema deployment issues:**
```bash
supabase login
supabase link --project-ref YOUR_PROJECT_ID
./scripts/deploy_schema_updates.sh --dry-run
```

---

## 🤝 Contributing

We welcome contributions! Here's how to get started:

### For Beginners
1. Fork the repository
2. Set up development environment
3. Look for "good first issue" labels
4. Make changes and add tests
5. Submit a Pull Request

### For Experts
1. Understand Clean Architecture structure
2. Choose complex features or optimizations
3. Maintain high test coverage
4. Update documentation
5. Review code quality

### Development Guidelines
- Follow Clean Architecture principles
- Write comprehensive tests
- Update documentation
- Follow Dart/Flutter conventions
- Use meaningful commit messages

---

## 📄 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- **Flutter Team** - Amazing cross-platform framework
- **Riverpod Team** - Excellent state management
- **Supabase Team** - Powerful backend-as-a-service
- **Hive Team** - Fast local database solution

---

<div align="center">

### 💖 Show Your Support

If you found this project helpful:

⭐ **Star the repository**  
🐛 **Report bugs**  
💡 **Suggest features**  
🤝 **Contribute code**  
📢 **Share with others**

---

**📱 Built with ❤️ using Flutter & Clean Architecture**

_Empowering users to take control of their financial life through beautiful, intuitive expense tracking._

[🔝 Back to Top](#-expensetracker---production-flutter-app)

</div>