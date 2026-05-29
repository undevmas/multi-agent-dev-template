# SKILL — Frontend Design

## Cuándo usar esta skill
Antes de crear o modificar cualquier componente visual (Angular o React).

---

## Principios base

- **Consistencia primero**: usar siempre los componentes del design system establecido
- **Mobile-first**: diseñar para 320px y escalar hacia arriba
- **Accesibilidad mínima**: contraste AA, labels en formularios, roles ARIA en navegación
- **Performance**: lazy loading de imágenes, evitar re-renders innecesarios

---
## Proceso antes de codificar

Antes de escribir código, definir:

1. **Propósito** — ¿Qué problema resuelve? ¿Quién lo usa?
2. **Tono visual** — Elegir UNA dirección y ejecutarla con precisión:
   - Minimalista brutal / Maximalista / Retro-futurista
   - Orgánico / Lujo refinado / Juguetón / Editorial
   - Brutalista / Art deco / Suave/pastel / Industrial
3. **Restricciones** — Framework, performance, accesibilidad
4. **Lo memorable** — ¿Qué va a recordar el usuario de esta pantalla?

**Regla crítica:** Elegir una dirección y ejecutarla con intención.
Tanto el maximalismo como el minimalismo funcionan — lo que importa es coherencia.

---

## Guía de estética frontend

### Tipografía
- Evitar fuentes genéricas: Arial, Inter, Roboto, system fonts
- Elegir fuentes con carácter y personalidad
- Combinar una display font distintiva con una body font refinada

### Color y tema
- Usar CSS variables para consistencia
- Paleta con colores dominantes y acentos definidos
- Evitar gradientes púrpura sobre fondo blanco (cliché de IA)

### Movimiento y animaciones
- CSS-only para HTML, Motion library para React
- Un page load bien orquestado > muchas micro-interacciones dispersas
- Staggered reveals, hover states que sorprendan

### Composición espacial
- Layouts inesperados: asimetría, solapamiento, flujo diagonal
- Romper el grid en momentos clave
- Espacio negativo generoso O densidad controlada

### Fondos y detalles visuales
- Crear atmósfera: gradient meshes, noise textures, geometric patterns
- Sombras dramáticas, bordes decorativos, grain overlays
- Nunca fondo sólido por defecto

---

## Para Angular

```scss
// tokens.scss — definir antes de cualquier componente
:root {
  --color-primary: [definir];
  --color-accent: [definir];
  --font-display: '[fuente display]', serif;
  --font-body: '[fuente body]', sans-serif;
}
```

Reglas Angular:
- Standalone components en Angular 17+
- OnPush change detection en listas y tablas
- Lazy loading en todos los feature modules
- Angular Material como base, extender con CSS custom

## Para React

- Tailwind CSS para utilidades, CSS custom para efectos
- Componentes funcionales con hooks
- shadcn/ui como base cuando aplique

---

## Lo que NUNCA hacer
- Convergir en los mismos componentes de siempre
- Usar Inter/Roboto/Space Grotesk automáticamente
- Layouts predecibles sin considerar el contexto
- Gradientes púrpura/azul genéricos
- Código sin punto de vista estético definido

## Angular — Convenciones de estructura

```
src/
├── app/
│   ├── core/           # Servicios singleton, guards, interceptors
│   ├── shared/         # Componentes, pipes y directivas reutilizables
│   ├── features/       # Un módulo por feature (lazy loaded)
│   │   └── [feature]/
│   │       ├── components/
│   │       ├── pages/
│   │       ├── services/
│   │       └── [feature].module.ts
│   └── layout/         # Shell, navbar, sidebar
```

**Naming:**
- Componentes: `kebab-case` en selector, `PascalCase` en clase
- Servicios: `[Nombre]Service`
- Guards: `[nombre].guard.ts`
- Interfaces: `[Nombre]Model` o `I[Nombre]`

**Reglas Angular:**
- Lazy loading obligatorio en todos los feature modules
- Standalone components en Angular 17+ (preferir sobre NgModules para componentes nuevos)
- OnPush change detection en componentes de lista/tabla
- Unsubscribe obligatorio: usar `takeUntilDestroyed()` o `AsyncPipe`

---

## React — Convenciones de estructura

```
src/
├── components/         # Componentes reutilizables (átomos/moléculas)
├── pages/              # Páginas completas (una por ruta)
├── hooks/              # Custom hooks
├── services/           # Llamadas a API
├── store/              # Estado global (Zustand)
├── utils/              # Helpers y funciones puras
└── types/              # TypeScript interfaces y types
```

**Naming:**
- Componentes: `PascalCase.tsx`
- Hooks: `use[Nombre].ts`
- Servicios: `[nombre].service.ts`

**Reglas React:**
- Solo componentes funcionales con hooks
- Props tipadas con TypeScript (no `any`)
- Keys estables en listas (nunca índice del array como key)
- Evitar useEffect para lógica que puede ir en el render

---

## Patrones de formularios (Angular y React)

Siempre incluir:
- Label visible asociado al input (no solo placeholder)
- Mensaje de error bajo el campo con ícono visual
- Estado de loading en botón de submit
- Deshabilitar botón durante envío (evitar doble submit)
- Confirmación antes de acciones destructivas

**Angular Reactive Forms:**
```typescript
// Siempre tipado
form = this.fb.group<LoginForm>({
  email: ['', [Validators.required, Validators.email]],
  password: ['', [Validators.required, Validators.minLength(8)]]
});
```

---

## Librerías aprobadas

| Propósito | Angular | React |
|---|---|---|
| UI Components | Angular Material | shadcn/ui o Radix UI |
| Estilos | Angular Material + CSS vars | Tailwind CSS |
| Formularios | Reactive Forms (nativo) | React Hook Form |
| HTTP | HttpClient (nativo) | Axios o fetch nativo |
| Estado | NgRx (complejo) / signals (simple) | Zustand |
| Tablas | Angular Material Table | TanStack Table |
| Fechas | date-fns | date-fns |

**NO usar:** Bootstrap nuevo, jQuery, moment.js (deprecated)
