# SKILL — Tests Angular con Vitest (PersonalCripto)

## Alcance

Usar únicamente para `Codigo/personal-cripto/src/Frontend/gestion-pwa`. El proyecto declara Vitest 4, JSDOM 28 y Angular 22; no instalar ni configurar Jest/Karma.

## Reglas

- Conservar archivos `[unidad].spec.ts` junto al archivo probado.
- Usar `TestBed` y las utilidades de testing de Angular.
- Importar mocks desde `vitest`: `import { describe, expect, it, beforeEach, vi } from 'vitest';`.
- Sustituir `jest.fn()` por `vi.fn()` y `jest.Mocked<T>` por `Mocked<T>` importado desde Vitest cuando sea necesario.
- Para HTTP, usar las APIs de testing vigentes de Angular; no agregar paquetes de mocking externos.

## Ejecución

```bash
npm test
npx vitest run src/app/ruta/al-archivo.spec.ts
npx vitest --watch
```

Las versiones de `package.json` y `package-lock.json` del frontend son la fuente de verdad.
