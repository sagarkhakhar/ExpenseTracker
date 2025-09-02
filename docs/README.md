# 📖 ExpenseTracker Documentation

Centralized documentation hub for the ExpenseTracker Flutter application.

## 📚 Documentation Index

### 🚀 **Getting Started**
Start here for initial setup and development:

| Document | Description | For |
|----------|-------------|-----|
| **[../README.md](../README.md)** | 🏠 Main project README with quick start | Everyone |
| **[../CLAUDE.md](../CLAUDE.md)** | 💻 Complete development guide & all commands | Developers |

### 🐳 **Local Development & Docker**
Set up your local development environment:

| Document | Description | For |
|----------|-------------|-----|
| **[DOCKER_SUPABASE_SETUP.md](DOCKER_SUPABASE_SETUP.md)** | 🐳 Complete Docker setup guide for Supabase | Developers |
| **[DEPLOYMENT_WORKFLOW.md](DEPLOYMENT_WORKFLOW.md)** | 🚀 Local to production deployment workflow | DevOps/Developers |
| **[SCHEMA_MIGRATION_GUIDE.md](SCHEMA_MIGRATION_GUIDE.md)** | 🗄️ Database schema management guide | Backend/Developers |

## 🎯 Quick Reference

### **New Developer Setup:**
1. Read [Main README](../README.md) for project overview
2. Follow [Quick Start](../README.md#-quick-start) for installation  
3. Set up [Docker Supabase](DOCKER_SUPABASE_SETUP.md) for local backend
4. Check [CLAUDE.md](../CLAUDE.md) for all available commands

### **Local Development:**
```bash
# Start local backend
./scripts/supabase-docker.sh start

# Run Flutter app  
flutter run

# See all commands in CLAUDE.md
```

### **Production Deployment:**
```bash
# Deploy schema changes
./scripts/deploy_schema_updates.sh

# Build for production
flutter build apk --dart-define-from-file=.env.production
```

## 📋 Documentation Overview

### 🏠 **[Main README](../README.md)**
- Project overview and features
- Quick start instructions
- Architecture overview
- Basic commands and troubleshooting

### 💻 **[CLAUDE.md](../CLAUDE.md)**  
- **Complete development reference**
- All Flutter, Docker, and Supabase commands
- Architecture details
- Testing and deployment instructions
- Code generation and build processes

### 🐳 **[Docker Supabase Setup](DOCKER_SUPABASE_SETUP.md)**
- Local development environment setup
- Docker container management
- Supabase service configuration
- Connection testing and troubleshooting

### 🚀 **[Deployment Workflow](DEPLOYMENT_WORKFLOW.md)**
- Environment management (local → remote)
- Schema deployment process
- Production build configurations
- Multi-environment setup

### 🗄️ **[Schema Migration Guide](SCHEMA_MIGRATION_GUIDE.md)**
- Database migration best practices
- Local to remote schema deployment
- Migration troubleshooting
- Schema versioning

## 🛠️ Quick Commands

```bash
# Development
flutter run                                    # Start app
flutter test                                   # Run tests
flutter analyze                                # Code analysis

# Docker Supabase
./scripts/supabase-docker.sh start             # Start backend
./scripts/supabase-docker.sh status            # Check status  

# Deployment
./scripts/deploy_schema_updates.sh             # Deploy schema
flutter run --dart-define-from-file=.env.production  # Test production
```

## 📞 Need Help?

1. **Getting Started**: Read [Main README](../README.md)
2. **Development Issues**: Check [CLAUDE.md](../CLAUDE.md) 
3. **Docker Problems**: See [Docker Setup Guide](DOCKER_SUPABASE_SETUP.md)
4. **Deployment Issues**: Check [Deployment Workflow](DEPLOYMENT_WORKFLOW.md)

---

**Last Updated**: December 2024  
**Documentation Version**: 2.0  
**Project Status**: Production Ready ✅