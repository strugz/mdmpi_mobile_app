# Architecture Diagrams - MDMPI Mobile App

**Version:** 1.0  
**Date:** January 16, 2026  
**Purpose:** Visual reference for current and proposed architectures

---

## Current Architecture (GetX MVC + Repository Pattern)

### High-Level Layer Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                          PRESENTATION LAYER                         │
│                                                                     │
│  ┌──────────────────┐  ┌──────────────────┐  ┌─────────────────┐  │
│  │   Screens        │  │   Widgets        │  │   Controllers   │  │
│  │   (UI)           │  │   (Reusable)     │  │   (GetX)        │  │
│  │                  │  │                  │  │   - State       │  │
│  │  - pick_up_list  │  │  - BAppBar       │  │   - Logic       │  │
│  │  - air_sea_list  │  │  - BButton       │  │   - Events      │  │
│  │  - pull_out_form │  │  - BCard         │  │                 │  │
│  └──────────────────┘  └──────────────────┘  └─────────────────┘  │
│                                                                     │
│  Technology: Flutter Widgets + GetX Reactive State (Obx)           │
└─────────────────────────┬───────────────────────────────────────────┘
                          │ Get.find<Controller>()
                          │ controller.method()
┌─────────────────────────▼───────────────────────────────────────────┐
│                     BUSINESS LOGIC LAYER                            │
│                                                                     │
│  ┌──────────────────┐  ┌──────────────────┐  ┌─────────────────┐  │
│  │  DataManagers    │  │  FilterManagers  │  │   FormState     │  │
│  │                  │  │                  │  │                 │  │
│  │  - Orchestrate   │  │  - Filter logic  │  │  - Form fields  │  │
│  │  - Validate      │  │  - Sort logic    │  │  - Validation   │  │
│  │  - Transform     │  │  - Date ranges   │  │  - Controllers  │  │
│  └──────────────────┘  └──────────────────┘  └─────────────────┘  │
│                                                                     │
│  ┌──────────────────┐  ┌──────────────────┐                       │
│  │    Mappers       │  │    Helpers       │                       │
│  │                  │  │                  │                       │
│  │  - DTO ↔ Model   │  │  - Utilities     │                       │
│  │  - API ↔ DB      │  │  - Converters    │                       │
│  └──────────────────┘  └──────────────────┘                       │
└─────────────────────────┬───────────────────────────────────────────┘
                          │ Get.find<Repository>()
                          │ repository.getAll()
┌─────────────────────────▼───────────────────────────────────────────┐
│                          DATA LAYER                                 │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                     Repositories                             │  │
│  │  - Abstract data sources (API + Local DB)                    │  │
│  │  - Handle caching, sync, error handling                      │  │
│  │                                                              │  │
│  │  ┌────────────────┐  ┌────────────────┐  ┌───────────────┐ │  │
│  │  │ PickUpRepo     │  │ AirSeaRepo     │  │ PullOutRepo   │ │  │
│  │  │ - getAll()     │  │ - create()     │  │ - update()    │ │  │
│  │  │ - create()     │  │ - update()     │  │ - cancel()    │ │  │
│  │  └────────────────┘  └────────────────┘  └───────────────┘ │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                     │
│  ┌────────────────────────┐  ┌──────────────────────────────────┐ │
│  │    Data Access Objects │  │    Platform Services             │ │
│  │    (DAOs)              │  │                                  │ │
│  │  - SQLite operations   │  │  - IPermissionService            │ │
│  │  - Direct DB access    │  │  - INotificationService          │ │
│  │  - Insert/Update/Query │  │  - ICameraService                │ │
│  └────────────────────────┘  └──────────────────────────────────┘ │
│                                                                     │
│  Data Sources: REST API + SQLite + Firebase + Local Storage        │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Data Flow Examples

### Example 1: Loading Pick-Up Requests

```
User Action: Opens Pick-Up List Screen
     │
     ├─> [PickUpListScreen] (UI)
     │        │
     │        ├─> Get.find<PickUpController>()
     │        │
     │        └─> Obx(() => controller.filteredPickUps) ─┐
     │                                                     │
     ├─> [PickUpController] (State)                       │
     │        │                                            │
     │        ├─> onInit()                                 │
     │        │    └─> dataManager.fetchPickUps()          │
     │        │                                            │
     │        └─> pickUps.obs (reactive list) <───────────┘
     │                 │
     ├─> [PickUpDataManager] (Business Logic)
     │        │
     │        ├─> validateConnectivity()
     │        ├─> repository.getAll()
     │        └─> filterManager.applyFilters()
     │                 │
     ├─> [PickUpRepository] (Data Layer)
     │        │
     │        ├─> Check local DB first
     │        │    └─> dao.getAllPickUps()
     │        │
     │        ├─> If empty, fetch from API
     │        │    └─> http.get('/api4/RequestPickUp')
     │        │
     │        └─> Cache locally
     │             └─> dao.insertAll(models)
     │
     └─> Data flows back up through layers
          └─> UI updates automatically via Obx
```

### Example 2: Creating a Pick-Up Request

```
User Action: Submits Pick-Up Form
     │
     ├─> [PickUpFormScreen] (UI)
     │        │
     │        ├─> controller.createPickUp()
     │        │
     ├─> [PickUpController] (State)
     │        │
     │        ├─> isSaving.value = true
     │        ├─> Show loading dialog
     │        │
     │        └─> dataManager.savePickUp()
     │                 │
     ├─> [PickUpDataManager] (Business Logic)
     │        │
     │        ├─> Validate form data
     │        │    └─> Check required fields
     │        │
     │        ├─> Build PickUpModel from form
     │        │
     │        ├─> repository.create(model)
     │        │
     │        ├─> Upload images
     │        │    └─> imageRepository.uploadMultiple()
     │        │
     │        └─> Upload signature
     │             └─> imageRepository.uploadSignature()
     │                      │
     ├─> [PickUpRepository] (Data Layer)
     │        │
     │        ├─> Check connectivity
     │        │
     │        ├─> POST to API
     │        │    └─> http.post('/api4/RequestPickUp', body)
     │        │
     │        └─> Save to local DB
     │             └─> dao.insert(model)
     │
     └─> Success/Failure propagates back
          ├─> Show snackbar
          ├─> Navigate back
          └─> Clear form
```

---

## Proposed Clean Architecture (Selective Adoption)

### With Use Cases and Repository Interfaces

```
┌─────────────────────────────────────────────────────────────────────┐
│                          PRESENTATION LAYER                         │
│                          (No major changes)                         │
│                                                                     │
│  ┌──────────────────┐  ┌──────────────────┐  ┌─────────────────┐  │
│  │   Screens        │  │   Widgets        │  │   Controllers   │  │
│  │   (UI)           │  │   (Reusable)     │  │   (GetX)        │  │
│  │                  │  │                  │  │   - State       │  │
│  │  Same as before  │  │  Same as before  │  │   - Events      │  │
│  │                  │  │                  │  │   - Uses UseCases│ │
│  └──────────────────┘  └──────────────────┘  └─────────────────┘  │
└─────────────────────────┬───────────────────────────────────────────┘
                          │ Get.find<UseCase>()
                          │ useCase.execute(request)
┌─────────────────────────▼───────────────────────────────────────────┐
│                     APPLICATION LAYER (NEW!)                        │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                       Use Cases                              │  │
│  │  - One class per business operation                          │  │
│  │  - Clear input/output contracts                              │  │
│  │  - Easy to test in isolation                                 │  │
│  │                                                              │  │
│  │  ┌──────────────────────┐  ┌──────────────────────────┐    │  │
│  │  │ CreatePickUpUseCase  │  │ UpdatePickUpUseCase      │    │  │
│  │  │  - execute(request)  │  │  - execute(id, updates)  │    │  │
│  │  │  - validate()        │  │  - validate()            │    │  │
│  │  │  - orchestrate()     │  │  - orchestrate()         │    │  │
│  │  └──────────────────────┘  └──────────────────────────┘    │  │
│  │                                                              │  │
│  │  ┌──────────────────────┐  ┌──────────────────────────┐    │  │
│  │  │ CancelPickUpUseCase  │  │ GetPickUpsUseCase        │    │  │
│  │  │  - execute(id, rmks) │  │  - execute(filters)      │    │  │
│  │  └──────────────────────┘  └──────────────────────────┘    │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                     │
│  Returns: Result<T> (success/failure) instead of throwing          │
└─────────────────────────┬───────────────────────────────────────────┘
                          │ Depends on interfaces (not concrete)
                          │ IPickUpRepository, IImageRepository
┌─────────────────────────▼───────────────────────────────────────────┐
│                        DOMAIN LAYER (NEW!)                          │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                     Entities (Pure)                          │  │
│  │  - Business objects with domain logic                        │  │
│  │  - No serialization, no framework dependencies               │  │
│  │                                                              │  │
│  │  ┌────────────────────┐  ┌────────────────────────────┐    │  │
│  │  │  PickUpEntity      │  │  ClientEntity              │    │  │
│  │  │  - canBeCancelled()│  │  - isActive()              │    │  │
│  │  │  - isOverdue()     │  │  - getDisplayName()        │    │  │
│  │  │  - getNextStatuses()│  │                            │    │  │
│  │  └────────────────────┘  └────────────────────────────┘    │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                Repository Interfaces (NEW!)                  │  │
│  │  - Contracts for data access                                 │  │
│  │  - Enable mocking for tests                                  │  │
│  │                                                              │  │
│  │  abstract class IPickUpRepository {                          │  │
│  │    Future<Result<List<PickUpEntity>>> getAll();              │  │
│  │    Future<Result<PickUpEntity>> create(entity);              │  │
│  │    Future<Result<PickUpEntity>> update(entity);              │  │
│  │  }                                                           │  │
│  └──────────────────────────────────────────────────────────────┘  │
└─────────────────────────┬───────────────────────────────────────────┘
                          │ Implements interfaces
┌─────────────────────────▼───────────────────────────────────────────┐
│                          DATA LAYER                                 │
│                       (Minor changes)                               │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │              Repositories (Implementations)                  │  │
│  │  - Implement domain interfaces                               │  │
│  │  - Work with DTOs (models) internally                        │  │
│  │  - Convert DTOs ↔ Entities                                   │  │
│  │                                                              │  │
│  │  class PickUpRepository implements IPickUpRepository {       │  │
│  │    @override                                                 │  │
│  │    Future<Result<List<PickUpEntity>>> getAll() {            │  │
│  │      // Fetch DTOs from API/DB                              │  │
│  │      // Convert to entities                                 │  │
│  │      return Result.success(entities);                       │  │
│  │    }                                                         │  │
│  │  }                                                           │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                     │
│  ┌────────────────────────┐  ┌──────────────────────────────────┐ │
│  │    DTOs/Models         │  │    DAOs & Services               │ │
│  │  - JSON serialization  │  │  - Same as before                │ │
│  │  - API mapping         │  │  - SQLite, Firebase, etc.        │ │
│  └────────────────────────┘  └──────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Comparison: Before vs After

### Data Flow: Creating a Pick-Up

#### BEFORE (Current)

```
[UI] ────> [Controller] ────> [DataManager] ────> [Repository] ────> [API/DB]
         isSaving.value    validateForm()       http.post()
         showLoader()      buildModel()         dao.insert()
                           uploadImages()
                           uploadSignature()
```

**Issues:**
- DataManager does too much (God object)
- Hard to test individual operations
- No clear contracts (repositories are concrete)

#### AFTER (With Use Cases)

```
[UI] ────> [Controller] ────> [UseCase] ────> [IRepository] ────> [API/DB]
         isSaving.value    validate()        (interface)      http.post()
         showLoader()      orchestrate()                      dao.insert()
                           return Result<T>
```

**Benefits:**
- ✅ Single Responsibility: UseCase does ONE thing
- ✅ Testable: Mock IRepository easily
- ✅ Clear Contracts: Input/Output types
- ✅ Composable: Chain use cases if needed

---

## Testing Architecture

### Current Testing Challenges

```
┌─────────────────────────────────────────────┐
│           Unit Tests (Partial)              │
│  - Some repository tests exist              │
│  - Controllers hard to test (GetX setup)    │
│  - DataManagers not tested                  │
└─────────────────────────────────────────────┘

┌─────────────────────────────────────────────┐
│           Widget Tests (Limited)            │
│  - Few screen tests                         │
│  - Hard to mock dependencies                │
└─────────────────────────────────────────────┘

┌─────────────────────────────────────────────┐
│         Integration Tests (None)            │
│  - No end-to-end tests                      │
└─────────────────────────────────────────────┘
```

### Proposed Testing Strategy

```
┌─────────────────────────────────────────────────────────────────┐
│                    Unit Tests (Use Cases)                       │
│  ✅ Easy to test with mocked repositories                       │
│  ✅ Fast execution (no UI, no DB)                               │
│  ✅ High coverage target: 80%+                                  │
│                                                                 │
│  test('should create pick-up successfully', () async {          │
│    when(mockRepo.create(any)).thenAnswer(...);                  │
│    final result = await useCase.execute(request);               │
│    expect(result.isSuccess, true);                              │
│  });                                                            │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                Unit Tests (Repositories)                        │
│  ✅ Test data mapping and caching logic                         │
│  ✅ Mock HTTP client and DAOs                                   │
│  ✅ Target: 70%+ coverage                                       │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                   Widget Tests (Screens)                        │
│  ✅ Test UI rendering and user interactions                     │
│  ✅ Mock controllers or use cases                               │
│  ✅ Target: Critical paths covered                              │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│              Integration Tests (Optional)                       │
│  ✅ Test full flow with real DB (in-memory)                     │
│  ✅ Test API integration with mock server                       │
│  ✅ Target: Happy path scenarios                                │
└─────────────────────────────────────────────────────────────────┘
```

---

## Folder Structure Comparison

### Current Structure

```
lib/
  features/
    logistics/
      controllers/          # GetX controllers
      screens/              # UI components
      models/               # Domain models + DTOs
      helpers/              # DataManagers, FilterManagers
      mappers/              # DTO ↔ Model conversions
      services/             # Feature-specific services
  data/
    repositories/           # Concrete repositories
    models/                 # Shared models
    local/
      dao/                  # Database access
  common/
    services/
      abstracts/            # Service interfaces
      implementations/      # Service implementations
  bindings/                 # DI registrations
```

### Proposed Structure (Selective Adoption)

```
lib/
  features/
    logistics/
      domain/               # NEW: Pure domain layer
        entities/           # Pure business objects
        repositories/       # Repository interfaces (IPickUpRepository)
        usecases/           # Use case classes
      application/          # RENAMED: was "controllers"
        pick_up_controller.dart
      presentation/         # RENAMED: was "screens"
        screens/
        widgets/
      data/                 # RENAMED: was "helpers" (optional)
        pick_up_data_manager.dart  # Can be removed after migration
  data/
    repositories/
      pick_up/
        pick_up_repository.dart     # Implements IPickUpRepository
    models/                 # DTOs (for JSON serialization)
    local/
      dao/
  common/
    services/
      abstracts/
      implementations/
  bindings/
```

**Note:** Folder restructure is **optional**. Can keep current structure and just add new layers.

---

## Migration Path Visualization

### Phase 1: Foundation

```
Before:                   After Phase 1:

[Controller]              [Controller]
     │                         │
[Repository]              [IRepository] ← interface!
     │                         │
  [API/DB]              [Repository] ← implements interface
                              │
                           [API/DB]

Changes:
✅ Add Result<T> type
✅ Extract repository interfaces
✅ Update DI bindings
```

### Phase 2: Use Cases

```
Before:                   After Phase 2:

[Controller]              [Controller]
     │                         │
[DataManager]             [UseCase] ← new!
     │                         │
[Repository]              [IRepository]
     │                         │
  [API/DB]              [Repository]
                              │
                           [API/DB]

Changes:
✅ Create use case classes
✅ Move logic from DataManager to UseCases
✅ Update controllers to call use cases
✅ Write unit tests for use cases
```

### Phase 3: Entities (Optional)

```
Before:                   After Phase 3:

[UseCase]                 [UseCase]
     │                         │
[IRepository]             [IRepository]
     │                         │
[Repository]              [Repository]
     │                         │
  [Model]                  [DTO] ←→ [Entity] ← new!
     │                              (pure)
  [API/DB]                    [API/DB]

Changes:
✅ Extract pure entities from models
✅ Keep models as DTOs
✅ Add toEntity() / fromEntity() mappers
✅ Use cases work with entities
```

---

## Decision Tree: When to Use Each Approach

```
                    ┌─────────────────────┐
                    │  New Feature?       │
                    └──────────┬──────────┘
                               │
                ┌──────────────┴──────────────┐
                │                             │
            ┌───▼────┐                   ┌───▼────┐
            │  Yes   │                   │   No   │
            └───┬────┘                   └───┬────┘
                │                            │
    ┌───────────▼──────────┐    ┌───────────▼──────────┐
    │ Is it complex?       │    │ Is refactor needed?  │
    └───────────┬──────────┘    └───────────┬──────────┘
                │                            │
        ┌───────┴────────┐           ┌──────┴──────┐
        │                │           │             │
    ┌───▼────┐      ┌───▼────┐  ┌───▼────┐   ┌───▼────┐
    │  Yes   │      │   No   │  │  Yes   │   │   No   │
    └───┬────┘      └───┬────┘  └───┬────┘   └───┬────┘
        │                │           │            │
        │                │           │            │
    ┌───▼──────────┐  ┌─▼────────┐  │      ┌─────▼──────┐
    │ Use Cases +  │  │ Simple   │  │      │ Keep       │
    │ Repository   │  │ Repo     │  │      │ Current    │
    │ Interface    │  │ Interface│  │      │ Pattern    │
    └──────────────┘  └──────────┘  │      └────────────┘
                                    │
                              ┌─────▼──────────┐
                              │ Gradual Refac: │
                              │ - Add Interface│
                              │ - Extract Use  │
                              │   Cases later  │
                              └────────────────┘
```

---

## Summary: Key Architectural Changes

| Aspect | Current | After Selective Adoption | Change Level |
|--------|---------|-------------------------|--------------|
| **Controllers** | Call DataManagers | Call Use Cases | 🟡 Medium |
| **Business Logic** | In DataManagers | In Use Cases | 🟢 Low-Medium |
| **Repositories** | Concrete classes | Implement interfaces | 🟢 Low |
| **Models** | Mix domain + DTO | Separate (optional) | 🟡 Medium |
| **Error Handling** | Exceptions | Result<T> | 🟢 Low |
| **Testing** | Limited | Comprehensive | 🟢 Low-Medium |
| **Folder Structure** | Current | Same or refined | 🟢 Low |

**Overall Migration Effort:** 🟡 **Low to Medium** (if done gradually)

---

**Document Owner:** Architecture Review Team  
**Created:** January 16, 2026  
**Version:** 1.0
