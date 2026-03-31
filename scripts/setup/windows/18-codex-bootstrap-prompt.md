# Prompt de Reingreso para Codex en Nueva PC

Usar este prompt en la nueva PC para que Codex lea el contexto del proyecto, ejecute el setup necesario y continúe el desarrollo.

## Prompt sugerido

```text
Lee primero y usa como fuente de verdad el archivo `C:\IA\codex\contexto_handoff.md`.

Después:
1. revisa el estado real del workspace;
2. verifica qué herramientas ya están instaladas;
3. ejecuta los scripts de `C:\IA\codex\scripts\setup\windows` que falten o correspondan para dejar la nueva PC lista con Docker, .NET, Flutter y el workspace funcional;
4. valida el entorno;
5. levanta el stack Docker del proyecto si el entorno ya quedó listo;
6. resume qué ejecutaste, qué quedó funcionando y qué falta.

Restricciones:
- no reinstales herramientas que ya estén correctamente instaladas;
- usa `C:\IA\codex\contexto_handoff.md` como contexto principal;
- prioriza el flujo Docker;
- si algún paso requiere reinicio o cierre de sesión, indícalo claramente y detente en ese punto;
- si Docker Desktop todavía no está operativo, intenta dejarlo configurado y explica exactamente qué falta;
- si el entorno queda listo, continúa luego con la validación del proyecto y el desarrollo.
```

## Archivo de contexto principal

- `C:\IA\codex\contexto_handoff.md`

## Scripts disponibles

- `C:\IA\codex\scripts\setup\windows\01-system-prereqs.ps1`
- `C:\IA\codex\scripts\setup\windows\02-install-core-dev-tools.ps1`
- `C:\IA\codex\scripts\setup\windows\03-post-install-docker.ps1`
- `C:\IA\codex\scripts\setup\windows\10-base-config.ps1`
- `C:\IA\codex\scripts\setup\windows\11-flutter-android-setup.ps1`
- `C:\IA\codex\scripts\setup\windows\12-vscode-extensions.ps1`
- `C:\IA\codex\scripts\setup\windows\13-local-postgres-optional.ps1`
- `C:\IA\codex\scripts\setup\windows\14-verify-environment.ps1`
- `C:\IA\codex\scripts\setup\windows\15-workspace-bootstrap.ps1`
- `C:\IA\codex\scripts\setup\windows\16-run-gdms-docker.ps1`
- `C:\IA\codex\scripts\setup\windows\17-stop-gdms-docker.ps1`

## Guía complementaria

- `C:\IA\codex\docs\migracion_nueva_pc_windows_docker.md`
