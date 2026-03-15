# Arquitectura Detallada - SGD
## Sistema de Gestión Documental

---

## 1. DECISIONES ARQUITECTÓNICAS

### 1.1 Stack Tecnológico Definido

#### Backend
- **Lenguaje**: Go (Golang) 1.21+
- **Framework Web**: Gin (elegido por rendimiento y simplicidad)
- **Razones de la elección**:
  - Alto rendimiento y concurrencia nativa (goroutines)
  - Compilación a binario único (fácil despliegue)
  - Excelente manejo de I/O para operaciones de archivos
  - Bajo consumo de memoria
  - Tipado estático y compilación rápida
  - Ecosystem maduro para microservicios

#### Frontend
Dos opciones disponibles según necesidades específicas:

##### Opción A: Flutter (Recomendada para máxima cobertura)
- **Framework**: Flutter 3.x
- **Ventajas**:
  - Single codebase para 6 plataformas (Web, Android, iOS, Windows, Linux, macOS)
  - Hot reload para desarrollo rápido
  - Rendimiento nativo
  - Material Design 3 integrado
  - Ecosystem maduro con packages robustos
- **Gestión de Estado**: Riverpod (moderna, type-safe, testing-friendly)
- **Navegación**: go_router
- **HTTP**: Dio + Retrofit
- **DI**: GetIt + Injectable

##### Opción B: Kotlin Multiplatform + Jetpack Compose
- **Lógica compartida**: Kotlin Multiplatform
- **UI**: 
  - Android/Desktop: Jetpack Compose Desktop
  - iOS: SwiftUI (nativo) con shared ViewModels
  - Web: Compose for Web
- **Ventajas**:
  - Código compartido a nivel de lógica de negocio
  - UIs nativas optimizadas por plataforma
  - Integración perfecta con ecosistema Android
  - Type safety total con Kotlin
- **DI**: Koin Multiplatform
- **HTTP**: Ktor Client
- **Serialización**: kotlinx.serialization

### 1.2 Patrones Arquitectónicos

#### Clean Architecture
```
┌────────────────────────────────────────────────────────┐
│ PRESENTATION │ UI, ViewModels, Controllers, DTOs       │
├────────────────────────────────────────────────────────┤
│ DOMAIN       │ Entities, Use Cases, Repository Ports  │ ← Sin dependencias externas
├────────────────────────────────────────────────────────┤
│ DATA/INFRA   │ Repository Impl, DB, APIs, Frameworks  │
└────────────────────────────────────────────────────────┘

Reglas de dependencia:
→ Domain no depende de nada
→ Data/Presentation dependen de Domain (dependency inversion)
→ Frameworks son detalles intercambiables
```

#### MVVM (Model-View-ViewModel)
```
┌─────────┐         ┌─────────────┐         ┌─────────┐
│  View   │ ←──────→│  ViewModel  │ ───────→│  Model  │
│ (UI)    │  Binding│  (State +   │  Uses   │(Domain +│
│         │         │   Logic)    │         │  Data)  │
└─────────┘         └─────────────┘         └─────────┘
```

**Flutter**: Provider/Riverpod para binding reactivo  
**KMP**: StateFlow/SharedFlow para reactive state

---

## 2. ESTRUCTURA DE PROYECTO DETALLADA

### 2.1 Backend (Golang)

```
sgd-backend/
├── cmd/
│   └── api/
│       └── main.go                 # Entry point
├── internal/                       # Código privado no exportable
│   ├── core/                       # Núcleo compartido
│   │   ├── domain/                 # Entidades de negocio puras
│   │   │   ├── document.go
│   │   │   ├── user.go
│   │   │   ├── audit.go
│   │   │   └── errors.go
│   │   ├── ports/                  # Interfaces (Hexagonal Architecture)
│   │   │   ├── repositories/
│   │   │   │   ├── document_repository.go
│   │   │   │   ├── user_repository.go
│   │   │   │   └── audit_repository.go
│   │   │   └── services/
│   │   │       ├── storage_service.go
│   │   │       ├── email_service.go
│   │   │       └── crypto_service.go
│   │   └── utils/
│   │       ├── crypto.go
│   │       ├── validators.go
│   │       └── time.go
│   │
│   ├── features/                   # Módulos por funcionalidad
│   │   ├── document-management/
│   │   │   ├── domain/             # Entidades específicas del módulo
│   │   │   │   └── document_metadata.go
│   │   │   ├── usecase/            # Casos de uso (application layer)
│   │   │   │   ├── create_document.go
│   │   │   │   ├── version_document.go
│   │   │   │   ├── search_document.go
│   │   │   │   └── delete_document.go
│   │   │   ├── repository/         # Implementaciones
│   │   │   │   ├── postgres_document_repo.go
│   │   │   │   └── elastic_search_repo.go
│   │   │   ├── handler/            # HTTP handlers (Gin)
│   │   │   │   ├── document_handler.go
│   │   │   │   └── routes.go
│   │   │   ├── dto/                # Data Transfer Objects
│   │   │   │   ├── create_document_request.go
│   │   │   │   └── document_response.go
│   │   │   └── plugin.go           # Feature plugin registration
│   │   │
│   │   ├── authentication/
│   │   │   ├── domain/
│   │   │   ├── usecase/
│   │   │   │   ├── login.go
│   │   │   │   ├── register.go
│   │   │   │   ├── mfa_setup.go
│   │   │   │   └── refresh_token.go
│   │   │   ├── handler/
│   │   │   ├── dto/
│   │   │   └── plugin.go
│   │   │
│   │   ├── digital-signature/
│   │   │   ├── usecase/
│   │   │   │   ├── sign_document.go
│   │   │   │   ├── verify_signature.go
│   │   │   │   └── validate_certificate.go
│   │   │   ├── handler/
│   │   │   └── plugin.go
│   │   │
│   │   ├── audit/
│   │   │   ├── usecase/
│   │   │   │   ├── log_action.go
│   │   │   │   └── search_logs.go
│   │   │   ├── repository/
│   │   │   ├── handler/
│   │   │   └── plugin.go
│   │   │
│   │   ├── retention/
│   │   │   ├── usecase/
│   │   │   │   ├── calculate_retention.go
│   │   │   │   ├── schedule_disposition.go
│   │   │   │   └── execute_disposition.go
│   │   │   └── plugin.go
│   │   │
│   │   └── workflow/
│   │       ├── domain/
│   │       │   └── workflow_definition.go
│   │       ├── usecase/
│   │       │   ├── create_workflow.go
│   │       │   ├── execute_step.go
│   │       │   └── approve_reject.go
│   │       └── plugin.go
│   │
│   ├── adapters/                   # Adaptadores a servicios externos
│   │   ├── postgres/
│   │   │   ├── connection.go
│   │   │   └── migrations/
│   │   ├── mongodb/
│   │   │   └── connection.go
│   │   ├── minio/
│   │   │   ├── client.go
│   │   │   └── operations.go
│   │   ├── elasticsearch/
│   │   │   ├── client.go
│   │   │   └── indexes.go
│   │   ├── keycloak/
│   │   │   └── client.go
│   │   └── smtp/
│   │       └── mailer.go
│   │
│   └── infrastructure/              # Configuración e infraestructura
│       ├── config/
│       │   └── config.go           # Viper configuration
│       ├── middleware/
│       │   ├── auth.go             # JWT validation
│       │   ├── cors.go
│       │   ├── logger.go
│       │   ├── rate_limit.go
│       │   └── recovery.go
│       ├── di/                     # Dependency Injection
│       │   └── container.go        # Wire or manual DI
│       └── server/
│           └── server.go           # HTTP server setup
│
├── pkg/                            # Código público reutilizable
│   ├── logger/
│   │   └── logger.go               # Structured logging (zap/zerolog)
│   ├── errs/
│   │   └── errors.go               # Error types
│   └── response/
│       └── response.go             # Standardized API responses
│
├── api/                            # Especificaciones de API
│   └── openapi/
│       └── sgd-api.yaml            # OpenAPI 3.0 spec
│
├── scripts/
│   ├── migrate.sh
│   └── seed.sh
│
├── deployments/                    # Docker, K8s configs
│   ├── docker/
│   │   └── Dockerfile
│   └── kubernetes/
│       ├── deployment.yaml
│       ├── service.yaml
│       └── ingress.yaml
│
├── tests/
│   ├── unit/
│   ├── integration/
│   └── e2e/
│
├── .env.example
├── go.mod
├── go.sum
├── Makefile
└── README.md
```

### 2.2 Frontend (Flutter)

```
sgd-frontend/
├── lib/
│   ├── core/                       # Funcionalidad compartida
│   │   ├── constants/
│   │   │   ├── api_constants.dart
│   │   │   └── app_constants.dart
│   │   ├── di/                     # Dependency Injection
│   │   │   └── injection.dart      # GetIt setup
│   │   ├── errors/
│   │   │   └── failures.dart
│   │   ├── network/
│   │   │   ├── api_client.dart     # Dio configuration
│   │   │   ├── interceptors/
│   │   │   │   ├── auth_interceptor.dart
│   │   │   │   └── logging_interceptor.dart
│   │   │   └── endpoints.dart
│   │   ├── storage/
│   │   │   ├── secure_storage.dart # flutter_secure_storage
│   │   │   └── local_storage.dart  # Hive/Isar
│   │   ├── theme/
│   │   │   ├── app_theme.dart
│   │   │   ├── colors.dart
│   │   │   └── typography.dart
│   │   ├── utils/
│   │   │   ├── validators.dart
│   │   │   ├── formatters.dart
│   │   │   └── extensions.dart
│   │   └── widgets/                # Widgets compartidos
│   │       ├── app_button.dart
│   │       ├── app_text_field.dart
│   │       └── loading_indicator.dart
│   │
│   ├── features/                   # Módulos por funcionalidad
│   │   ├── authentication/
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   └── user.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   └── auth_repository.dart
│   │   │   │   └── usecases/
│   │   │   │       ├── login_usecase.dart
│   │   │   │       ├── logout_usecase.dart
│   │   │   │       └── setup_mfa_usecase.dart
│   │   │   ├── data/
│   │   │   │   ├── models/
│   │   │   │   │   ├── user_model.dart
│   │   │   │   │   └── login_response.dart
│   │   │   │   ├── datasources/
│   │   │   │   │   ├── auth_remote_datasource.dart
│   │   │   │   │   └── auth_local_datasource.dart
│   │   │   │   └── repositories/
│   │   │   │       └── auth_repository_impl.dart
│   │   │   └── presentation/
│   │   │       ├── providers/
│   │   │       │   └── auth_provider.dart      # Riverpod
│   │   │       ├── pages/
│   │   │       │   ├── login_page.dart
│   │   │       │   └── mfa_setup_page.dart
│   │   │       └── widgets/
│   │   │           └── login_form.dart
│   │   │
│   │   ├── document_management/
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   ├── document.dart
│   │   │   │   │   └── document_version.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   └── document_repository.dart
│   │   │   │   └── usecases/
│   │   │   │       ├── create_document_usecase.dart
│   │   │   │       ├── get_document_usecase.dart
│   │   │   │       ├── search_documents_usecase.dart
│   │   │   │       └── upload_file_usecase.dart
│   │   │   ├── data/
│   │   │   │   ├── models/
│   │   │   │   ├── datasources/
│   │   │   │   └── repositories/
│   │   │   └── presentation/
│   │   │       ├── providers/
│   │   │       │   ├── document_list_provider.dart
│   │   │       │   └── document_detail_provider.dart
│   │   │       ├── pages/
│   │   │       │   ├── document_list_page.dart
│   │   │       │   ├── document_detail_page.dart
│   │   │       │   └── document_upload_page.dart
│   │   │       └── widgets/
│   │   │           ├── document_card.dart
│   │   │           └── document_preview.dart
│   │   │
│   │   ├── search/
│   │   │   └── ... (estructura similar)
│   │   │
│   │   ├── digital_signature/
│   │   │   └── ...
│   │   │
│   │   ├── audit/
│   │   │   └── ...
│   │   │
│   │   └── settings/
│   │       └── ...
│   │
│   ├── app/
│   │   ├── app.dart                # MaterialApp root
│   │   ├── routes/
│   │   │   └── app_router.dart     # go_router config
│   │   └── providers.dart          # Global Riverpod providers
│   │
│   └── main.dart                   # Entry point
│
├── test/
│   ├── unit/
│   ├── widget/
│   └── integration/
│
├── assets/
│   ├── images/
│   ├── icons/
│   └── fonts/
│
├── android/
├── ios/
├── web/
├── windows/
├── linux/
├── macos/
│
├── pubspec.yaml
└── README.md
```

### 2.3 Frontend (Kotlin Multiplatform - Alternativa)

```
sgd-kmp/
├── shared/                         # Código compartido KMP
│   ├── src/
│   │   ├── commonMain/kotlin/
│   │   │   ├── core/
│   │   │   │   ├── di/
│   │   │   │   │   └── Koin.kt
│   │   │   │   ├── network/
│   │   │   │   │   └── HttpClient.kt    # Ktor
│   │   │   │   └── utils/
│   │   │   ├── features/
│   │   │   │   ├── authentication/
│   │   │   │   │   ├── domain/
│   │   │   │   │   ├── data/
│   │   │   │   │   └── presentation/
│   │   │   │   │       └── AuthViewModel.kt
│   │   │   │   └── document/
│   │   │   │       └── ...
│   │   │   └── Platform.kt
│   │   ├── androidMain/kotlin/
│   │   ├── iosMain/kotlin/
│   │   └── jsMain/kotlin/
│   └── build.gradle.kts
│
├── androidApp/                     # Android específico
│   ├── src/main/kotlin/
│   │   └── ui/
│   │       └── screens/            # Jetpack Compose
│   └── build.gradle.kts
│
├── iosApp/                         # iOS específico
│   └── iosApp/
│       └── ContentView.swift       # SwiftUI
│
├── webApp/                         # Web específico
│   └── src/jsMain/kotlin/
│       └── App.kt                  # Compose for Web
│
├── desktopApp/                     # Desktop (Windows/Linux/Mac)
│   └── src/jvmMain/kotlin/
│       └── Main.kt                 # Compose Desktop
│
└── build.gradle.kts
```

---

## 3. PLUGIN CONVENTIONS - IMPLEMENTACIÓN

### 3.1 Backend (Golang)

**Plugin Interface**:
```go
// internal/infrastructure/plugin/plugin.go
package plugin

import (
    "database/sql"
    "github.com/gin-gonic/gin"
    "sgd-backend/internal/infrastructure/di"
)

type Feature interface {
    // Identificación
    Name() string
    Version() string
    
    // Ciclo de vida
    Initialize(container *di.Container) error
    RegisterRoutes(router *gin.RouterGroup)
    Migrate(db *sql.DB) error
    
    // Health check
    HealthCheck() error
}

type Registry struct {
    features []Feature
}

func NewRegistry() *Registry {
    return &Registry{
        features: make([]Feature, 0),
    }
}

func (r *Registry) Register(feature Feature) {
    r.features = append(r.features, feature)
}

func (r *Registry) InitializeAll(container *di.Container) error {
    for _, feature := range r.features {
        if err := feature.Initialize(container); err != nil {
            return fmt.Errorf("failed to initialize %s: %w", feature.Name(), err)
        }
    }
    return nil
}

func (r *Registry) RegisterAllRoutes(router *gin.RouterGroup) {
    for _, feature := range r.features {
        featureGroup := router.Group(fmt.Sprintf("/%s", feature.Name()))
        feature.RegisterRoutes(featureGroup)
    }
}
```

**Implementación de Feature**:
```go
// internal/features/document-management/plugin.go
package documentmanagement

import (
    "database/sql"
    "github.com/gin-gonic/gin"
    "sgd-backend/internal/infrastructure/di"
    "sgd-backend/internal/infrastructure/plugin"
)

type DocumentFeature struct {
    handler *DocumentHandler
}

func NewFeature() plugin.Feature {
    return &DocumentFeature{}
}

func (f *DocumentFeature) Name() string {
    return "documents"
}

func (f *DocumentFeature) Version() string {
    return "1.0.0"
}

func (f *DocumentFeature) Initialize(container *di.Container) error {
    // Registrar dependencias
    repo := NewPostgresDocumentRepository(container.DB)
    storageService := container.StorageService
    usecase := NewCreateDocumentUseCase(repo, storageService)
    f.handler = NewDocumentHandler(usecase)
    return nil
}

func (f *DocumentFeature) RegisterRoutes(group *gin.RouterGroup) {
    group.POST("", f.handler.Create)
    group.GET("/:id", f.handler.GetByID)
    group.PUT("/:id", f.handler.Update)
    group.DELETE("/:id", f.handler.Delete)
    group.GET("", f.handler.Search)
    group.POST("/:id/versions", f.handler.CreateVersion)
}

func (f *DocumentFeature) Migrate(db *sql.DB) error {
    // Ejecutar migraciones
    return runDocumentMigrations(db)
}

func (f *DocumentFeature) HealthCheck() error {
    return nil
}
```

**Main Application**:
```go
// cmd/api/main.go
package main

import (
    "sgd-backend/internal/infrastructure/plugin"
    "sgd-backend/internal/infrastructure/di"
    "sgd-backend/internal/features/document-management"
    "sgd-backend/internal/features/authentication"
    "sgd-backend/internal/features/audit"
    // ... más features
)

func main() {
    // Setup
    container := di.NewContainer()
    router := gin.Default()
    registry := plugin.NewRegistry()
    
    // Registrar features (plug & play)
    registry.Register(documentmanagement.NewFeature())
    registry.Register(authentication.NewFeature())
    registry.Register(audit.NewFeature())
    // Fácil agregar/remover features
    
    // Inicializar
    if err := registry.InitializeAll(container); err != nil {
        log.Fatal(err)
    }
    
    // Registrar rutas
    api := router.Group("/api/v1")
    registry.RegisterAllRoutes(api)
    
    // Start
    router.Run(":8080")
}
```

### 3.2 Frontend (Flutter)

**Convention con build.yaml** (para generación de código):
```yaml
# build.yaml
targets:
  $default:
    builders:
      injectable_generator|injectable_builder:
        enabled: true
        options:
          auto_register: true
          
      retrofit_generator|retrofit:
        enabled: true
```

**Modularización**:
```dart
// lib/core/di/injection.dart
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

final getIt = GetIt.instance;

@InjectableInit()
Future<void> configureDependencies() async {
  // Auto-generated por injectable
  await getIt.init();
}

// Cada feature se registra automáticamente con @injectable
```

**Feature Module**:
```dart
// lib/features/document_management/di/document_module.dart
import 'package:injectable/injectable.dart';

@module
abstract class DocumentModule {
  @lazySingleton
  DocumentRepository provideRepository(
    DocumentRemoteDataSource remote,
    DocumentLocalDataSource local,
  ) => DocumentRepositoryImpl(remote, local);
  
  @lazySingleton
  DocumentRemoteDataSource provideRemoteDataSource(ApiClient client) => 
      DocumentRemoteDataSourceImpl(client);
}
```

---

## 4. COMUNICACIÓN BACKEND-FRONTEND

### 4.1 API REST

**Estructura de Response**:
```go
// pkg/response/response.go
package response

type APIResponse struct {
    Success bool        `json:"success"`
    Data    interface{} `json:"data,omitempty"`
    Error   *APIError   `json:"error,omitempty"`
    Meta    *MetaData   `json:"meta,omitempty"`
}

type APIError struct {
    Code    string `json:"code"`
    Message string `json:"message"`
    Details string `json:"details,omitempty"`
}

type MetaData struct {
    Page       int `json:"page,omitempty"`
    PageSize   int `json:"page_size,omitempty"`
    TotalItems int `json:"total_items,omitempty"`
    TotalPages int `json:"total_pages,omitempty"`
}
```

**Endpoints Principales**:
```
POST   /api/v1/auth/login
POST   /api/v1/auth/logout
POST   /api/v1/auth/refresh
POST   /api/v1/auth/mfa/setup
POST   /api/v1/auth/mfa/verify

POST   /api/v1/documents
GET    /api/v1/documents/:id
PUT    /api/v1/documents/:id
DELETE /api/v1/documents/:id
GET    /api/v1/documents
POST   /api/v1/documents/:id/versions
GET    /api/v1/documents/:id/versions
POST   /api/v1/documents/:id/sign
GET    /api/v1/documents/:id/download

GET    /api/v1/search?q=...&filters=...

GET    /api/v1/audit/logs
GET    /api/v1/audit/logs/:id

POST   /api/v1/workflows
GET    /api/v1/workflows/:id
POST   /api/v1/workflows/:id/execute
```

### 4.2 Autenticación JWT

```go
type JWTClaims struct {
    UserID    string   `json:"user_id"`
    Username  string   `json:"username"`
    Roles     []string `json:"roles"`
    Permissions []string `json:"permissions"`
    jwt.StandardClaims
}
```

**Headers**:
```
Authorization: Bearer <access_token>
X-Refresh-Token: <refresh_token>
```

---

## 5. TESTING STRATEGY

### 5.1 Backend (Go)

```go
// Unit Test (Table-Driven)
func TestCreateDocumentUseCase(t *testing.T) {
    tests := []struct {
        name    string
        input   *CreateDocumentInput
        wantErr bool
    }{
        {
            name: "valid document",
            input: &CreateDocumentInput{
                Title: "Test Doc",
                // ...
            },
            wantErr: false,
        },
        // más casos
    }
    
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            // Arrange
            mockRepo := new(MockDocumentRepository)
            usecase := NewCreateDocumentUseCase(mockRepo)
            
            // Act
            err := usecase.Execute(context.Background(), tt.input)
            
            // Assert
            if (err != nil) != tt.wantErr {
                t.Errorf("got error = %v, wantErr %v", err, tt.wantErr)
            }
        })
    }
}
```

### 5.2 Frontend (Flutter)

```dart
// Unit Test
void main() {
  late MockAuthRepository mockRepo;
  late LoginUseCase usecase;
  
  setUp(() {
    mockRepo = MockAuthRepository();
    usecase = LoginUseCase(mockRepo);
  });
  
  test('should return User when login is successful', () async {
    // Arrange
    when(mockRepo.login(any, any))
        .thenAnswer((_) async => Right(tUser));
    
    // Act
    final result = await usecase(LoginParams('user', 'pass'));
    
    // Assert
    expect(result, Right(tUser));
    verify(mockRepo.login('user', 'pass'));
  });
}

// Widget Test
testWidgets('LoginPage shows error on failed login', (tester) async {
  await tester.pumpWidget(MyApp());
  
  await tester.enterText(find.byKey(Key('username')), 'user');
  await tester.enterText(find.byKey(Key('password')), 'wrong');
  await tester.tap(find.byKey(Key('login_button')));
  await tester.pumpAndSettle();
  
  expect(find.text('Invalid credentials'), findsOneWidget);
});
```

---

## 6. DEPLOYMENT

### 6.1 Docker

**Backend Dockerfile**:
```dockerfile
# Multi-stage build
FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o sgd-api ./cmd/api

FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=builder /app/sgd-api .
EXPOSE 8080
CMD ["./sgd-api"]
```

**Docker Compose**:
```yaml
version: '3.8'
services:
  api:
    build: ./sgd-backend
    ports:
      - "8080:8080"
    environment:
      - DB_HOST=postgres
      - MINIO_ENDPOINT=minio:9000
    depends_on:
      - postgres
      - minio
      - elasticsearch
      
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: sgd
      POSTGRES_USER: sgd_user
      POSTGRES_PASSWORD: secure_password
    volumes:
      - postgres_data:/var/lib/postgresql/data
      
  minio:
    image: minio/minio
    command: server /data --console-address ":9001"
    ports:
      - "9000:9000"
      - "9001:9001"
    volumes:
      - minio_data:/data
      
  elasticsearch:
    image: elasticsearch:8.11.0
    environment:
      - discovery.type=single-node
    volumes:
      - es_data:/usr/share/elasticsearch/data
      
  keycloak:
    image: quay.io/keycloak/keycloak:23.0
    environment:
      KC_DB: postgres
      KC_DB_URL: jdbc:postgresql://postgres:5432/keycloak
    ports:
      - "8081:8080"

volumes:
  postgres_data:
  minio_data:
  es_data:
```

### 6.2 Kubernetes

```yaml
# deployments/kubernetes/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sgd-api
spec:
  replicas: 3
  selector:
    matchLabels:
      app: sgd-api
  template:
    metadata:
      labels:
        app: sgd-api
    spec:
      containers:
      - name: sgd-api
        image: sgd-api:latest
        ports:
        - containerPort: 8080
        env:
        - name: DB_HOST
          valueFrom:
            configMapKeyRef:
              name: sgd-config
              key: db.host
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
```

---

## 7. PRÓXIMOS PASOS

1. **Setup de Proyectos**:
   - Inicializar repo backend: `go mod init sgd-backend`
   - Inicializar frontend: `flutter create sgd_frontend` o setup KMP
   
2. **Configurar CI/CD**:
   - GitHub Actions o GitLab CI
   - Linting, testing, building automatizado
   
3. **Implementar Features por prioridad**:
   - Sprint 1: Authentication + Document Upload básico
   - Sprint 2: Versioning + Search
   - Sprint 3: Digital Signature
   - Sprint 4: Workflows + Retention

**Versión**: 1.0  
**Fecha**: Enero 2026
