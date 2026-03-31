# Migración a Nueva PC Windows 11 con Docker

## Objetivo

Dejar una nueva PC lista para continuar el desarrollo y levantar el proyecto GDMS con Docker, Flutter y `.NET 10`.

## Ubicación de scripts

Todos los scripts de setup quedaron en:

- `C:\IA\codex\scripts\setup\windows`

## Flujo recomendado

### 1. Copiar el workspace

Copiar la carpeta completa del proyecto a la nueva PC manteniendo la ruta esperada, por ejemplo:

```text
C:\IA\codex
```

### 2. Preparar Windows para Docker

Ejecutar como administrador:

```powershell
C:\IA\codex\scripts\setup\windows\01-system-prereqs.ps1
```

Reiniciar Windows al finalizar.

### 3. Instalar herramientas base

Ejecutar como administrador:

```powershell
C:\IA\codex\scripts\setup\windows\02-install-core-dev-tools.ps1
```

Esto instala:

- Docker Desktop
- .NET 10 SDK
- Git
- VS Code
- Node.js LTS
- Android Studio
- OpenJDK 21
- Android Platform Tools
- Puro
- Firebase CLI
- DBeaver
- PowerShell 7

### 4. Configurar Docker Desktop y WSL2

Ejecutar como administrador:

```powershell
C:\IA\codex\scripts\setup\windows\03-post-install-docker.ps1
```

Si Docker Desktop solicita permisos o reinicio de sesión, aplicarlos antes de seguir.

### 5. Configuración general del stack

Ejecutar:

```powershell
C:\IA\codex\scripts\setup\windows\10-base-config.ps1
C:\IA\codex\scripts\setup\windows\11-flutter-android-setup.ps1
C:\IA\codex\scripts\setup\windows\12-vscode-extensions.ps1
```

Si Flutter lo pide:

```powershell
flutter doctor --android-licenses
```

Y para Firebase:

```powershell
firebase login
```

### 6. Verificar el entorno

Ejecutar:

```powershell
C:\IA\codex\scripts\setup\windows\14-verify-environment.ps1
```

### 7. Bootstrap del workspace

Ejecutar:

```powershell
C:\IA\codex\scripts\setup\windows\15-workspace-bootstrap.ps1
```

### 8. Levantar el backend con Docker

Ejecutar:

```powershell
C:\IA\codex\scripts\setup\windows\16-run-gdms-docker.ps1
```

URLs esperadas:

- Swagger: [http://localhost:8080/swagger](http://localhost:8080/swagger)
- PostgreSQL: `localhost:5432`

Para detener:

```powershell
C:\IA\codex\scripts\setup\windows\17-stop-gdms-docker.ps1
```

## Validación mínima esperada

- `docker --version`
- `docker compose version`
- `dotnet --list-sdks`
- `flutter doctor`
- `firebase --version`
- `dotnet build C:\IA\codex\server\Gdms.sln`
- `docker compose up --build`

## Notas

- Si Docker Desktop queda instalado pero no arranca, verificar virtualización habilitada en BIOS/UEFI.
- Si `docker` no aparece en terminal, cerrar sesión de Windows y volver a entrar.
- Si Android SDK no quedó listo, abrir Android Studio una vez y completar su setup.
