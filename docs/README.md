# MDMPI Mobile App - Documentation

Welcome to the documentation repository for the MDMPI Mobile App.

---

## 📚 Documentation Structure

```
docs/
├── modules/                                    # Module-specific documentation
│   ├── air-sea/                               # Air/Sea logistics module
│   ├── standard-delivery/                     # Standard Delivery module
│   ├── general/                               # General fixes and features
│   └── LOGISTICS_MODULE_IMPLEMENTATION_GUIDE.md
├── guidelines/                                 # Project-wide guidelines
│   ├── CONTRIBUTING.md
│   ├── COPILOT_INSTRUCTIONS_UPDATE.md
│   └── SECURITY_API_KEY_MIGRATION.md
├── templates/                                  # Documentation templates
├── QA_TEST_PLAN.md
├── test_cases_index.csv
└── README.md                                   # This file
```

---

## 🗂️ Module Documentation

### Logistics Modules

#### [Air/Sea Module](modules/air-sea/)
Complete documentation for the Air/Sea logistics request management system.

**Key Topics**:
- Status flow and lifecycle management
- Role-based access control (Request, Release, Courier, Viewer)
- Digital signature capture and proof image documentation
- Waybill tracking and dispatch management
- Drop-off confirmation workflow

**Files**:
- [Main Documentation](modules/air-sea/AIR_SEA_MODULE_DOCUMENTATION.md) - Complete reference guide
- [Consolidation Summary](modules/air-sea/CONSOLIDATION_SUMMARY.md) - Documentation history
- [Multi-Role Fix](modules/air-sea/MULTI_ROLE_FIX_IMPLEMENTATION.md) - Role priority system
- [All Modules Summary](modules/air-sea/ALL_MODULES_COMPLETE_SUMMARY.md) - Multi-role fix across all modules
- [Waybill Scanner](modules/air-sea/WAYBILL_SCANNER_IMPLEMENTATION_COMPLETE.md) - OCR scanning implementation
- [Waybill Display Fix](modules/air-sea/WAYBILL_DISPLAY_FIX.md) - Bug fix documentation

**Status**: ✅ Production Ready | **Version**: 2.0 | **Last Updated**: Dec 17, 2025

---

#### [Standard Delivery Module](modules/standard-delivery/)
**Complete consolidated documentation** for Standard Delivery logistics module - All-in-one comprehensive guide.

**Documentation:**
- [📘 Standard Delivery Complete Documentation](modules/standard-delivery/STANDARD_DELIVERY_COMPLETE_CONSOLIDATED.md) - **Single comprehensive document** covering:
  - Architecture (Controller + Managers pattern v2.0)
  - Complete data model & API DTOs
  - Controllers, Managers, and all components
  - Features implementation (creation, updates, tracking, filtering, offline, notifications)
  - API integration (repositories, mappers)
  - Status flow diagram & rules
  - Troubleshooting guide
  - Testing guide (unit, integration, manual)
  - Complete change history
  - Multi-role dialog fix implementation
  - Multi-role fix analysis

**Status**: ✅ Complete | **Last Updated**: Dec 22, 2025 | **Version**: 2.0 | **Pages**: Single consolidated document

---

#### [General Fixes and Features](modules/general/)
Cross-module bug fixes and feature implementations.

**Files**:
- [Item Category Local DB](modules/general/ITEM_CATEGORY_LOCAL_DB.md)
- [Signature Button Update](modules/general/SIGNATURE_BUTTON_UPDATE.md)
- [Submit Button Issue Resolved](modules/general/SUBMIT_BUTTON_ISSUE_RESOLVED.md)

---

#### [Logistics Module Implementation Guide](modules/LOGISTICS_MODULE_IMPLEMENTATION_GUIDE.md)
Comprehensive guide for Pick-Up, Pull-Out, and logistics module implementations.

---

## 📋 Project Guidelines

### Documentation Standards

#### [Documentation Organization Guidelines](guidelines/COPILOT_INSTRUCTIONS_UPDATE.md)
Standards for organizing all project documentation.

**Key Guidelines**:
- ALL .md files must be in `docs/` folder
- Module-specific docs in `docs/modules/<module-name>/`
- Use SCREAMING_SNAKE_CASE for documentation file names
- Each module needs a README.md for navigation
- Required sections for module documentation
- Navigation link maintenance requirements

**Status**: ✅ Active | **Updated**: Dec 17, 2025

---

#### [Contributing Guidelines](guidelines/CONTRIBUTING.md)
Guidelines for contributing to the project.

---

#### [Security API Key Migration](guidelines/SECURITY_API_KEY_MIGRATION.md)
Documentation for API key security migration.

---

## 📋 Documentation Guidelines

### Adding New Documentation

When creating documentation for a new module or feature:

1. **Create module folder**: `docs/modules/[module-name]/`
2. **Create main documentation**: `[MODULE_NAME]_DOCUMENTATION.md`
3. **Create module README**: `README.md` with navigation links
4. **Update this file**: Add module to the list above
5. **Update root README**: Link to the documentation

### Documentation Structure

Each module documentation should include:

- **Overview**: Purpose and key features
- **Architecture**: Design patterns and component structure
- **Implementation**: Detailed feature descriptions
- **API Integration**: Endpoints and data flows
- **Testing**: Test scenarios and checklists
- **Troubleshooting**: Common issues and solutions

### Naming Conventions

- Module folders: `kebab-case` (e.g., `air-sea`, `standard-delivery`)
- Documentation files: `SCREAMING_SNAKE_CASE` (e.g., `AIR_SEA_MODULE_DOCUMENTATION.md`)
- Module READMEs: `README.md`

### Version Control

- Update version number and date when making significant changes
- Keep a version history section in main documentation
- Document breaking changes clearly

---

## 🔍 Finding Documentation

### By Feature
- **Air/Sea Logistics**: [modules/air-sea/](modules/air-sea/)
- **Standard Delivery**: Coming soon
- **Pick Up**: Coming soon
- **Pull Out**: Coming soon

### By Topic
- **Architecture**: Check individual module documentation
- **Testing**: Look for "Testing Guide" sections
- **API Integration**: Look for "API Integration" sections
- **Troubleshooting**: Look for "Troubleshooting" sections

---

## 📖 Quick Start

1. **New to the project?** Start with the [main README](../README.md)
2. **Working on Air/Sea?** Read the [Air/Sea documentation](modules/air-sea/AIR_SEA_MODULE_DOCUMENTATION.md)
3. **Need to test?** Check the module's testing guide section
4. **Fixing a bug?** Check the troubleshooting section of relevant module

---

## 🤝 Contributing to Documentation

### Making Updates

1. Navigate to the relevant module folder
2. Edit the main documentation file
3. Update version and date
4. Update the module README if structure changed
5. Test all links and code examples

### Best Practices

- ✅ Keep documentation up-to-date with code changes
- ✅ Use clear, concise language
- ✅ Include code examples and diagrams
- ✅ Add table of contents for long documents
- ✅ Use consistent formatting and structure
- ✅ Link related sections and external resources

### Quality Checklist

- [ ] All links work correctly
- [ ] Code examples are accurate
- [ ] Diagrams are clear and up-to-date
- [ ] Version and date are updated
- [ ] Spelling and grammar checked
- [ ] Follows naming conventions
- [ ] Navigation is clear

---

## 📞 Support

For questions about documentation:
1. Check the relevant module documentation first
2. Review the troubleshooting sections
3. Check the source code for inline comments
4. Contact the development team

---

## 📅 Documentation Updates

| Module | Last Updated | Version | Status |
|--------|--------------|---------|--------|
| Air/Sea | Dec 17, 2025 | 2.0 | ✅ Complete |
| Standard Delivery | - | - | 📝 Pending |
| Pick Up | - | - | 📝 Pending |
| Pull Out | - | - | 📝 Pending |

---

**Location**: `docs/`  
**Maintained by**: Development Team  
**Last Updated**: December 17, 2025

