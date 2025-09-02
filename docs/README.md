# 📖 ExpenseTracker Documentation

Centralized documentation hub for the ExpenseTracker Flutter application.

## 📚 Documentation Index

### 🚀 **Getting Started**
Start here for initial setup and development:

| Document | Description | For |
|----------|-------------|-----|
| **[../README.md](../README.md)** | 🏠 Main project README with quick start | Everyone |
| **[../CLAUDE.md](../CLAUDE.md)** | 💻 Complete development guide & all commands | Developers |

### 🐳 **Supabase Setup Guides**
Complete setup guides for both local development and production deployment:

| Document | Description | For |
|----------|-------------|-----|
| **[DOCKER_SUPABASE_SETUP.md](DOCKER_SUPABASE_SETUP.md)** | 🐳 **Local Setup** - Complete Docker-based local development guide | New Developers |
| **[REMOTE_SUPABASE_SETUP.md](REMOTE_SUPABASE_SETUP.md)** | 🌐 **Remote Setup** - Production Supabase deployment guide | Production/DevOps |
| **[DEPLOYMENT_WORKFLOW.md](DEPLOYMENT_WORKFLOW.md)** | 🔄 Local to production workflow and environment management | Experienced Developers |
| **[SCHEMA_MIGRATION_GUIDE.md](SCHEMA_MIGRATION_GUIDE.md)** | 🗄️ Database schema management and migrations | Backend/Developers |

## 🎯 Quick Reference

### **New Developer Setup:**
1. Read [Main README](../README.md) for project overview
2. Follow [Quick Start](../README.md#-quick-start) for installation  
3. Set up [Local Supabase](DOCKER_SUPABASE_SETUP.md) for development backend
4. Check [CLAUDE.md](../CLAUDE.md) for all available commands

### **Production Deployment:**
1. Complete local development setup first
2. Follow [Remote Supabase Setup](REMOTE_SUPABASE_SETUP.md) for production
3. Use [Deployment Workflow](DEPLOYMENT_WORKFLOW.md) for ongoing deployments

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
# Deploy schema to remote Supabase
./scripts/deploy_schema_updates.sh

# Run with remote backend
flutter run --dart-define-from-file=.env.production

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

### 🐳 **[Local Supabase Setup](DOCKER_SUPABASE_SETUP.md)**
- **Complete beginner-friendly guide** for local development
- Docker installation and container management
- Automated and manual setup options
- Database schema explanation and dummy data
- Daily development workflow and troubleshooting

### 🌐 **[Remote Supabase Setup](REMOTE_SUPABASE_SETUP.md)**
- **Complete production deployment guide**
- Remote Supabase project creation and linking
- Authentication, storage, and security configuration
- Environment management and CI/CD setup
- Monitoring, maintenance, and scaling

### 🔄 **[Deployment Workflow](DEPLOYMENT_WORKFLOW.md)**
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
2. **Local Setup Issues**: See [Local Supabase Setup](DOCKER_SUPABASE_SETUP.md)
3. **Production Deployment**: Check [Remote Supabase Setup](REMOTE_SUPABASE_SETUP.md)
4. **Development Issues**: Check [CLAUDE.md](../CLAUDE.md) 
5. **Deployment Workflow**: See [Deployment Workflow](DEPLOYMENT_WORKFLOW.md)

---

**Last Updated**: December 2024  
**Documentation Version**: 2.0  
**Project Status**: Production Ready ✅