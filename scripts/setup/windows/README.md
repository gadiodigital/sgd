# Setup Windows para GDMS

Esta carpeta sirve para dejar listo el entorno de desarrollo de `C:\IA\codex` en cualquier PC Windows 11, nueva o semi-configurada.

El objetivo de estos scripts es cubrir:

- prerequisitos del sistema;
- herramientas base de desarrollo;
- Docker y stack backend;
- .NET, Flutter, Android y VS Code;
- bootstrap del workspace;
- verificación final del entorno.

## Alcance

Con este setup la PC queda lista para trabajar sobre:

- `server` (`.NET`);
- `client` (workspace Flutter con Melos);
- `windows-twain` (host local de escaneo para Windows);
- Docker Compose del proyecto.

## Requisitos previos

Antes de empezar:

1. Clonar el repositorio en `C:\IA\codex`.
2. Abrir PowerShell.
3. Ejecutar los scripts marcados como administrador en una consola elevada.
4. Tener conexión a internet durante toda la instalación.
5. Si vas a usar Android, abrir Android Studio al menos una vez después de instalarlo para completar el SDK.

## Orden recomendado en una PC nueva

### Flujo principal con Docker

Ejecutar en este orden:

1. `01-system-prereqs.ps1` como administrador
2. Reiniciar Windows
3. `02-install-core-dev-tools.ps1` como administrador
4. `03-post-install-docker.ps1` como administrador
5. `10-base-config.ps1`
6. `11-flutter-android-setup.ps1`
7. `12-vscode-extensions.ps1`
8. `14-verify-environment.ps1`
9. `15-workspace-bootstrap.ps1`
10. `16-run-gdms-docker.ps1`

### Flujo alternativo sin Docker

Usar este flujo solo si no vas a correr PostgreSQL + API con Docker:

1. Ejecutar `01-system-prereqs.ps1` como administrador
2. Reiniciar Windows
3. Ejecutar `02-install-core-dev-tools.ps1` como administrador
4. Ejecutar `10-base-config.ps1`
5. Ejecutar `11-flutter-android-setup.ps1`
6. Ejecutar `12-vscode-extensions.ps1`
7. Si no vas a usar Docker, ejecutar `13-local-postgres-optional.ps1`
8. Ejecutar `14-verify-environment.ps1`
9. Ejecutar `15-workspace-bootstrap.ps1`

Luego completar manualmente:

```powershell
firebase login
flutter doctor --android-licenses
```

## Qué hace cada script

- `01-system-prereqs.ps1`
  Habilita componentes del sistema como `WSL2`, `VirtualMachinePlatform`, `Hyper-V` y `LongPaths`.

- `02-install-core-dev-tools.ps1`
  Instala el stack base con `winget`, incluyendo Docker Desktop, VS Code, Git y herramientas del entorno.

- `03-post-install-docker.ps1`
  Ajusta Docker Desktop para uso local, verifica `docker compose` y deja listo el entorno WSL asociado.

- `10-base-config.ps1`
  Configura Git, variables de entorno, `JAVA_HOME`, `PATH` y herramientas globales de `.NET`.

- `11-flutter-android-setup.ps1`
  Configura Flutter estable con `Puro` y completa el setup de Android para desarrollo móvil.

- `12-vscode-extensions.ps1`
  Instala extensiones recomendadas de Visual Studio Code.

- `13-local-postgres-optional.ps1`
  Instala PostgreSQL local si querés trabajar sin Docker.

- `14-verify-environment.ps1`
  Verifica que Windows, Git, Docker, .NET, Flutter, Android y VS Code estén correctamente instalados.

- `15-workspace-bootstrap.ps1`
  Hace bootstrap del repo:
  - `dotnet restore` y `dotnet build` del backend;
  - `melos bootstrap` del monorepo Flutter;
  - `flutter pub get` y `flutter analyze` en `client\apps\gdms_app`.

  El workspace Flutter actual se define en:
  - `client\pubspec.yaml`

  Si `melos` falla pero Flutter/Dart sí están instalados, verificar también:
  - `C:\Users\<usuario>\AppData\Local\Pub\Cache\bin`
  - `C:\FlutterSDK\flutter\bin`
  - `C:\FlutterSDK\flutter\bin\cache\dart-sdk\bin`

- `16-run-gdms-docker.ps1`
  Levanta el stack Docker del proyecto.
  Expone:
  - Swagger: `http://localhost:8080/swagger`
  - PostgreSQL: `localhost:5433`
  Si falta `.env`, lo crea desde `.env.example` para que puedas ajustar `GDMS_JWT_SIGNING_KEY` y settings operativos.

- `17-stop-gdms-docker.ps1`
  Baja el stack Docker del proyecto.

- `scripts\ops\use_preproduction_profile.ps1`
  Reemplaza `.env` por un perfil local de preproducción para validar el stack con settings menos permisivos.

- `18-codex-bootstrap-prompt.md`
  Prompt listo para reingresar en Codex con contexto de proyecto.

- `18-copy-codex-bootstrap-prompt.ps1`
  Copia al portapapeles el prompt de reingreso para Codex.

## Comandos típicos de setup

Si estás parado en `C:\IA\codex\scripts\setup\windows`, podés ejecutar:

```powershell
powershell -ExecutionPolicy Bypass -File .\01-system-prereqs.ps1
powershell -ExecutionPolicy Bypass -File .\02-install-core-dev-tools.ps1
powershell -ExecutionPolicy Bypass -File .\03-post-install-docker.ps1
powershell -ExecutionPolicy Bypass -File .\10-base-config.ps1
powershell -ExecutionPolicy Bypass -File .\11-flutter-android-setup.ps1
powershell -ExecutionPolicy Bypass -File .\12-vscode-extensions.ps1
powershell -ExecutionPolicy Bypass -File .\14-verify-environment.ps1
powershell -ExecutionPolicy Bypass -File .\15-workspace-bootstrap.ps1
powershell -ExecutionPolicy Bypass -File .\16-run-gdms-docker.ps1
```

## Verificación mínima después del setup

Después de correr `15-workspace-bootstrap.ps1`, validar también:

```powershell
cd C:\IA\codex
powershell -ExecutionPolicy Bypass -File .\scripts\quality\validate_workspace.ps1
```

Ese validador ahora resuelve Flutter de forma robusta en este orden:

- `flutter` desde `PATH`
- `FLUTTER_ROOT\bin\flutter.bat`
- `C:\FlutterSDK\flutter\bin\flutter.bat`
- `C:\src\flutter\bin\flutter.bat`
- `C:\tools\flutter\bin\flutter.bat`

Con eso, el gate del workspace puede correr incluso si `flutter` no quedó expuesto globalmente en `PATH`, siempre que Flutter esté instalado en una de esas rutas esperadas.

Si eso termina en verde, el workspace quedó listo para desarrollo.

## Puertos y endpoints locales importantes

- API backend Docker: `http://localhost:8080/swagger`
- API backend local `.NET`: `http://localhost:5012`
- API Flutter esperada por defecto: `http://localhost:5012`
- Host local `windows-twain`: `http://127.0.0.1:43127`

## Documentación adicional

También quedó una guía más extensa en:

- [docs\migracion_nueva_pc_windows_docker.md](C:\IA\codex\docs\migracion_nueva_pc_windows_docker.md)

Y la referencia de `windows-twain` está en:

- [windows-twain\documentacion.md](C:\IA\codex\windows-twain\documentacion.md)

## Reingreso con Codex en la nueva PC

Si querés que Codex retome el proyecto con contexto:

```powershell
C:\IA\codex\scripts\setup\windows\18-copy-codex-bootstrap-prompt.ps1
```

Después pegá el contenido copiado dentro de Codex.

## Abrir y ejecutar el proyecto en Visual Studio Code

### 1. Abrir el workspace

Desde PowerShell:

```powershell
code C:\IA\codex
```

Si `code` no está en el `PATH`, abrir Visual Studio Code manualmente y elegir:

1. `File`
2. `Open Folder...`
3. `C:\IA\codex`

### 2. Abrir terminales separadas en VS Code

Conviene trabajar con 3 o 4 terminales:

- Terminal 1: backend e infraestructura
- Terminal 2: app Flutter
- Terminal 3: `windows-twain`
- Terminal 4: utilidades opcionales (`git`, validaciones, logs)

### 3. Levantar backend con Docker

En la terminal 1:

```powershell
cd C:\IA\codex
powershell -ExecutionPolicy Bypass -File .\scripts\setup\windows\16-run-gdms-docker.ps1
```

Esto levanta PostgreSQL + API del proyecto por Docker Compose.

Verificación rápida:

- Swagger: `http://localhost:8080/swagger`
- Logs:

```powershell
cd C:\IA\codex
docker compose logs -f
```

### 4. Levantar la API local `.NET` en modo desarrollo

Si querés correr la API directamente desde código en vez de Docker, usar otra terminal:

```powershell
cd C:\IA\codex\server
dotnet run --project .\src\Gdms.Api\Gdms.Api.csproj
```

La API local usa `http://localhost:5012` según `launchSettings.json`.

### 5. Levantar `windows-twain`

Este subproyecto solo aplica en Windows y es útil para el flujo de escaneo local.

En la terminal 3:

```powershell
cd C:\IA\codex\windows-twain
dotnet run --project .\windows-twain.csproj
```

Endpoint local esperado:

- `http://127.0.0.1:43127/health`

### 6. Levantar la app Flutter

En la terminal 2:

```powershell
cd C:\IA\codex\client\apps\gdms_app
flutter run --dart-define=GDMS_API_BASE_URL=http://localhost:5012
```

Si vas a consumir la API dockerizada en `8080`, ajustar el `dart-define` a esa URL si corresponde al entorno que estés usando.

### 7. Levantar todos los subproyectos mínimos

El set más útil para desarrollo diario en VS Code es:

1. Docker Compose o API local `.NET`
2. `windows-twain` si vas a probar escaneo
3. `gdms_app` con Flutter

Configuración típica:

- Opción A, con Docker + escaneo local:
  - terminal 1: `16-run-gdms-docker.ps1`
  - terminal 2: `flutter run ...`
  - terminal 3: `dotnet run --project .\windows-twain.csproj`

- Opción B, con backend local `.NET` + escaneo local:
  - terminal 1: `dotnet run --project .\src\Gdms.Api\Gdms.Api.csproj`
  - terminal 2: `flutter run --dart-define=GDMS_API_BASE_URL=http://localhost:5012`
  - terminal 3: `dotnet run --project .\windows-twain.csproj`

### 8. Validar todo desde VS Code

Cuando el entorno ya esté levantado, podés validar el workspace completo con:

```powershell
cd C:\IA\codex
powershell -ExecutionPolicy Bypass -File .\scripts\quality\validate_workspace.ps1
```

### 9. Detener servicios

- Docker:

```powershell
cd C:\IA\codex
powershell -ExecutionPolicy Bypass -File .\scripts\setup\windows\17-stop-gdms-docker.ps1
```

- API local `.NET` y `windows-twain`:
  detener con `Ctrl + C` en cada terminal.
