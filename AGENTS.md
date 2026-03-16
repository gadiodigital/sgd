#### Frontend
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
**Patron arquitectonico**: Clean architecture para clases que no sean de la capa de presentacion.
**Cada clase**: debe tener como maximo 300 lineas de codigo. 