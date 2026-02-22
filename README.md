# MedTech Project - Engineering Standards

Este repositorio utiliza un flujo de trabajo profesional diseñado para evitar colisiones entre el frontend (React/Vite), el backend (Node/Supabase) y la App iOS (Xcode).

## 🚀 Workflow de Desarrollo (Git Flow)

Para mantener la integridad del código, utilizamos un flujo de ramas estricto manejado por **Antigravity AI**.

### Cómo contribuir:
1. **Inicia el Agente:** Abre el panel de Antigravity en el repositorio.
2. **Comando Mágico:** Escribe `/git-flow`.
3. **Sigue las instrucciones:** El agente te preguntará qué estás haciendo y creará la rama con la nomenclatura correcta:
   - `feat/`: Nuevas funcionalidades.
   - `fix/`: Corrección de errores.
   - `refactor/`: Mejoras de código sin cambio de lógica.

### Reglas de Oro:
- **Prohibido `git push --force`**: Si rompes la historia, rompes el trabajo de todos.
- **Conventional Commits**: Todos los commits deben seguir el estándar (ej. `feat(ui): add login button`).
- **Xcode Safety**: El `.gitignore` está configurado para ignorar `DerivedData` y `UserInterfaceState`. Si Xcode te pide "Save changes" en archivos que no tocaste, no los incluyas en el commit.

## 🛠 Stack Tecnológico
- **Frontend:** React + Vite + Tailwind (TypeScript)
- **Mobile:** iOS Nativo (SwiftUI / Xcode)
- **Backend:** Node.js + Supabase
