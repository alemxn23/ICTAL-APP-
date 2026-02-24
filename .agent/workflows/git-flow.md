# Estándar de Git Flow y Control de Versiones
## Descripción
Este workflow define la arquitectura estricta de repositorios para el equipo. Agente, tu objetivo es automatizar y forzar el cumplimiento de estas reglas implacablemente al interactuar con Git a través de la terminal.

## 1. Arquitectura de Ramas (Reglas Inquebrantables)
- `main`: Producción. Código inmaculado. NUNCA ejecutes un commit directo aquí. Solo acepta fusiones mediante Pull Requests aprobados.
- `develop`: Entorno principal de integración y pruebas.
- `feature/<nombre-corto>`: Para desarrollar nuevas características (ej. `feature/supabase-auth`). Siempre nacen de `develop`.
- `bugfix/<nombre-corto>`: Para solucionar errores detectados durante el desarrollo.
- `hotfix/<nombre-corto>`: Para emergencias críticas en producción. Siempre nacen de `main`.

## 2. Convención Estricta de Commits
Redacta todos los mensajes de commit usando el formato "Conventional Commits":
`<tipo>(<alcance opcional>): <descripción corta y en imperativo>`
Tipos estrictamente permitidos:
- `feat`: Nueva característica.
- `fix`: Corrección de un error.
- `refactor`: Cambio de código que no corrige errores ni añade características.
- `chore`: Tareas de mantenimiento (actualización de dependencias, scripts).

## 3. Instrucciones de Ejecución para el Agente
Cuando el usuario invoque `/git-flow`, ejecuta secuencialmente:
1. **Diagnóstico:** Usa la terminal para ejecutar `git status` y `git branch --show-current`. Analiza el estado del árbol de trabajo.
2. **Interacción:** Pregunta al desarrollador qué desea hacer: ¿Iniciar una nueva tarea, hacer un commit del trabajo actual, o preparar un PR?
3. **Acción - Nueva Tarea:** Si inician trabajo, ejecuta los comandos para asegurar que están en la rama correcta (haz un `git pull` previo) y crea la nueva rama con la nomenclatura del Paso 1.
4. **Acción - Commit:** Si piden guardar cambios, analiza el `git diff`, redacta automáticamente un mensaje de commit lógico según el Paso 2, y pide confirmación al usuario antes de ejecutar `git commit`.
5. **Prevención de Desastres:** Si detectas cambios en archivos críticos de configuración propensos a corromperse (como `project.pbxproj` en Xcode, `pubspec.lock` en Flutter o `package-lock.json` en Node), advierte explícitamente al usuario sobre posibles conflictos de fusión (merge conflicts) antes de proceder.
