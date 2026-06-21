---
name: frontend-design/dark-mode-theming
description: >
  Implementa el sistema de theming unificado (modo claro/oscuro y theming por tenant)
  como estrategia CSS-first. Úsala cuando la spec involucre dashboards, PWA, o
  contextos donde el usuario puede cambiar el tema. Garantiza que ningún componente
  hardcodee colores y que el cambio de tema sea instantáneo sin re-render.
stack: Angular 17+ · React 18+ · CSS Custom Properties · localStorage
contexts: PWA · Dashboard · Admin panel · Multi-tenant
---

# SKILL: Dark Mode & Theming — Sistema Unificado

## Cuándo usar esta skill

Actívala cuando la spec mencione:
- Dashboards o admin panels (los usuarios de admin panels prefieren modo oscuro)
- PWA instalable (debe respetar `prefers-color-scheme` del sistema)
- Multi-tenant con branding por organización
- Pantallas de seguridad o autenticación (el modo oscuro reduce fatiga visual)

---

## Cómo leer la spec para extraer señales de theming

| Señal en la spec | Implicación para theming |
|---|---|
| Múltiples actores (User, Admin, SystemAdmin) | Considera theming diferenciado por rol (ej: Admin ve sidebar más oscuro) |
| Feature flags por tenant (`Features:Mfa:Totp`) | El tenant puede tener colores de brand propios |
| Datos sensibles (tokens, secretos, credenciales) | `--color-surface-sensitive` debe ser visible en ambos modos |
| Pantallas de autenticación/login | Fondo oscuro funciona mejor para flujos de seguridad |
| Estados de error (400, 401, 403, 404) | Los rojos de error deben cumplir contraste en ambos modos |

---

## Arquitectura del sistema de theming

### Principio único: CSS Custom Properties como única fuente de verdad

```
tokens.css (define :root y [data-theme="dark"])
    ↓
ThemeService (Angular) / ThemeContext (React)
    ↓ aplica clase/atributo en <html>
<html data-theme="dark"> o <html class="dark">
    ↓ CSS cascadea automáticamente
Todos los componentes leen var(--color-*) sin saber el tema actual
```

**Nunca:** dos archivos CSS separados (`theme-light.css` / `theme-dark.css`). Eso requiere cambio de `<link>` y produce FOUC.

---

## Implementación Angular

### 1. ThemeService

```typescript
// src/app/core/services/theme.service.ts
import { Injectable, signal, effect } from '@angular/core';

export type Theme = 'light' | 'dark' | 'system';

@Injectable({ providedIn: 'root' })
export class ThemeService {
  private readonly STORAGE_KEY = 'app-theme';

  // Signal reactivo — componentes se suscriben automáticamente
  readonly theme = signal<Theme>(this.getStoredTheme());

  constructor() {
    // Efecto: aplica el tema al DOM cuando cambia el signal
    effect(() => {
      this.applyTheme(this.theme());
    });

    // Escucha cambios del sistema operativo en tiempo real
    window.matchMedia('(prefers-color-scheme: dark)')
      .addEventListener('change', () => {
        if (this.theme() === 'system') {
          this.applyTheme('system');
        }
      });
  }

  setTheme(theme: Theme): void {
    localStorage.setItem(this.STORAGE_KEY, theme);
    this.theme.set(theme);
  }

  private getStoredTheme(): Theme {
    return (localStorage.getItem(this.STORAGE_KEY) as Theme) ?? 'system';
  }

  private applyTheme(theme: Theme): void {
    const html = document.documentElement;
    const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
    const isDark = theme === 'dark' || (theme === 'system' && prefersDark);

    // Usa data-theme para mayor especificidad y compatibilidad
    html.setAttribute('data-theme', isDark ? 'dark' : 'light');

    // También mantiene clase .dark para compatibilidad con Tailwind (si se usa)
    html.classList.toggle('dark', isDark);
  }
}
```

### 2. Theme Toggle Component (Angular)

```typescript
// src/app/shared/components/theme-toggle/theme-toggle.component.ts
import { Component, inject } from '@angular/core';
import { ThemeService, Theme } from '@core/services/theme.service';

@Component({
  selector: 'app-theme-toggle',
  standalone: true,
  template: `
    <button
      class="theme-toggle"
      [attr.aria-label]="'Cambiar a ' + (isDark() ? 'modo claro' : 'modo oscuro')"
      [attr.aria-pressed]="isDark()"
      (click)="toggle()"
    >
      <span class="theme-toggle__icon" aria-hidden="true">
        {{ isDark() ? '☀️' : '🌙' }}
      </span>
    </button>
  `,
  styles: [`
    .theme-toggle {
      display: flex;
      align-items: center;
      justify-content: center;
      width: 36px;
      height: 36px;
      border-radius: var(--radius-full);
      border: 1px solid var(--color-border-default);
      background: var(--color-surface-card);
      cursor: pointer;
      transition: background var(--duration-normal) var(--ease-standard),
                  border-color var(--duration-normal) var(--ease-standard);

      &:hover {
        background: var(--color-surface-sunken);
        border-color: var(--color-border-strong);
      }
      &:focus-visible {
        outline: none;
        box-shadow: var(--shadow-focus);
      }
    }
  `]
})
export class ThemeToggleComponent {
  private themeService = inject(ThemeService);

  isDark = () => {
    const t = this.themeService.theme();
    if (t === 'system') return window.matchMedia('(prefers-color-scheme: dark)').matches;
    return t === 'dark';
  };

  toggle(): void {
    this.themeService.setTheme(this.isDark() ? 'light' : 'dark');
  }
}
```

### 3. Prevenir FOUC en Angular (index.html)

```html
<!-- index.html — script inline ANTES de cualquier contenido -->
<script>
  (function() {
    var stored = localStorage.getItem('app-theme');
    var prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
    var isDark = stored === 'dark' || ((!stored || stored === 'system') && prefersDark);
    document.documentElement.setAttribute('data-theme', isDark ? 'dark' : 'light');
    if (isDark) document.documentElement.classList.add('dark');
  })();
</script>
```

---

## Implementación React

### 1. ThemeContext + Provider

```tsx
// src/lib/theme/theme-context.tsx
import { createContext, useContext, useEffect, useState } from 'react';

type Theme = 'light' | 'dark' | 'system';

interface ThemeContextValue {
  theme: Theme;
  setTheme: (theme: Theme) => void;
  resolvedTheme: 'light' | 'dark'; // tema efectivo (system → light/dark)
}

const ThemeContext = createContext<ThemeContextValue | null>(null);

export function ThemeProvider({ children }: { children: React.ReactNode }) {
  const [theme, setThemeState] = useState<Theme>(
    () => (localStorage.getItem('app-theme') as Theme) ?? 'system'
  );

  const getResolved = (t: Theme): 'light' | 'dark' => {
    if (t !== 'system') return t;
    return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
  };

  const [resolvedTheme, setResolvedTheme] = useState(() => getResolved(theme));

  useEffect(() => {
    const resolved = getResolved(theme);
    setResolvedTheme(resolved);
    document.documentElement.setAttribute('data-theme', resolved);
    document.documentElement.classList.toggle('dark', resolved === 'dark');
  }, [theme]);

  useEffect(() => {
    const mq = window.matchMedia('(prefers-color-scheme: dark)');
    const handler = () => {
      if (theme === 'system') {
        const resolved = getResolved('system');
        setResolvedTheme(resolved);
        document.documentElement.setAttribute('data-theme', resolved);
        document.documentElement.classList.toggle('dark', resolved === 'dark');
      }
    };
    mq.addEventListener('change', handler);
    return () => mq.removeEventListener('change', handler);
  }, [theme]);

  const setTheme = (t: Theme) => {
    localStorage.setItem('app-theme', t);
    setThemeState(t);
  };

  return (
    <ThemeContext.Provider value={{ theme, setTheme, resolvedTheme }}>
      {children}
    </ThemeContext.Provider>
  );
}

export const useTheme = () => {
  const ctx = useContext(ThemeContext);
  if (!ctx) throw new Error('useTheme must be used within ThemeProvider');
  return ctx;
};
```

### 2. Script anti-FOUC (Next.js / Vite)

```html
<!-- Para Vite: index.html — Para Next.js: _document.tsx -->
<script dangerouslySetInnerHTML={{__html: `
  (function() {
    var stored = localStorage.getItem('app-theme');
    var prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
    var isDark = stored === 'dark' || ((!stored || stored === 'system') && prefersDark);
    document.documentElement.setAttribute('data-theme', isDark ? 'dark' : 'light');
    if (isDark) document.documentElement.classList.add('dark');
  })();
`}} />
```

---

## Theming multi-tenant (extensión del sistema)

Para proyectos con múltiples tenants que tienen branding propio:

```typescript
// Angular — TenantThemeService
import { Injectable } from '@angular/core';

interface TenantBrand {
  primaryColor: string;   // hex
  primaryHover: string;   // hex
  logoUrl: string;
}

@Injectable({ providedIn: 'root' })
export class TenantThemeService {
  applyBrand(brand: TenantBrand): void {
    const root = document.documentElement;
    // Solo sobreescribe tokens de acción — nunca los de feedback ni superficies
    root.style.setProperty('--color-action-primary', brand.primaryColor);
    root.style.setProperty('--color-action-primary-hover', brand.primaryHover);
    // El resto del sistema (modo oscuro, errores, tipografía) permanece intacto
  }

  clearBrand(): void {
    const root = document.documentElement;
    root.style.removeProperty('--color-action-primary');
    root.style.removeProperty('--color-action-primary-hover');
  }
}
```

---

## Regla de contraste obligatoria

Cualquier par de colores texto/fondo debe cumplir:

| Contexto | Ratio mínimo | Herramienta de verificación |
|---|---|---|
| Texto body normal | 4.5:1 | WCAG AA |
| Texto grande (>18px o bold >14px) | 3:1 | WCAG AA |
| Componentes UI (bordes de inputs, iconos) | 3:1 | WCAG AA |
| Texto en badges de estado | 4.5:1 | WCAG AA |

Los tokens del sistema ya están calibrados para cumplir estos ratios en ambos modos. Si se personaliza el tenant color, verificar el contraste antes de aplicar.

---

## ❌ Qué NO hacer

- **No usar `@media (prefers-color-scheme: dark)` directamente en componentes.** Solo el sistema de theming lo usa; los componentes solo leen tokens CSS.
- **No crear dos archivos de variables CSS.** Un solo `tokens.css` con `:root` y `[data-theme="dark"]`.
- **No aplicar el tema en un `useEffect` sin el script anti-FOUC.** El usuario verá un parpadeo en el primer render.
- **No sobreescribir colores de feedback al personalizar el tenant.** Los colores de error, warning y success son del sistema, no del brand.
- **No usar `filter: invert()` como atajo para modo oscuro.** Invierte también imágenes, logos y contenido multimedia.
- **No guardar el tema en estado del servidor.** El tema siempre vive en `localStorage` + clase en `<html>` — es preferencia de cliente, no de usuario de base de datos.

---

## Checklist de verificación

- [ ] El script anti-FOUC está en `index.html` antes del bundle principal
- [ ] El cambio de tema es instantáneo sin re-render de componentes (solo cambia el atributo en `<html>`)
- [ ] La opción `system` responde a cambios del OS en tiempo real
- [ ] Los colores de feedback (error, warning, success) tienen contraste ≥4.5:1 en ambos modos
- [ ] Los datos sensibles (`--color-surface-sensitive`) son visualmente distinguibles en modo oscuro
- [ ] El theming de tenant sobreescribe SOLO los tokens de acción (`--color-action-primary`)
- [ ] `localStorage` persiste la preferencia del usuario entre sesiones
- [ ] Los tests E2E incluyen un caso con `data-theme="dark"` para verificar contraste
