# SKILL — SEO

## Cuándo usar esta skill
Al crear o modificar vistas públicas (login, landing, páginas indexables).
Las vistas protegidas detrás de autenticación NO necesitan SEO.

---

## Checklist por página pública

### Meta tags obligatorios
```html
<title>[Título único, máx 60 chars] | [Nombre App]</title>
<meta name="description" content="[Descripción, 120-160 chars]">
<meta name="robots" content="index, follow">
<link rel="canonical" href="[URL canónica completa]">
```

### Open Graph (compartir en redes sociales)
```html
<meta property="og:title" content="...">
<meta property="og:description" content="...">
<meta property="og:image" content="[URL imagen 1200x630px]">
<meta property="og:url" content="[URL canónica]">
<meta property="og:type" content="website">
```

### Vistas privadas / detrás de login
```html
<meta name="robots" content="noindex, nofollow">
```

---

## Estructura semántica HTML

- Un solo `<h1>` por página (el título principal de la página)
- Jerarquía lógica sin saltar niveles: h1 → h2 → h3
- `<nav>` para navegación principal con `aria-label`
- `<main>` para el contenido principal (un solo por página)
- `<header>` y `<footer>` para cabecera y pie
- Listas de navegación dentro de `<ul>` / `<li>`

---

## Performance (afecta ranking de Google)

- Imágenes con atributo `alt` siempre (descriptivo si es informativa, vacío si es decorativa)
- Formato WebP para imágenes cuando sea posible
- `loading="lazy"` en imágenes fuera del viewport inicial
- `loading="eager"` solo en la imagen principal (above-the-fold)
- Evitar CSS bloqueante en el render inicial

---

## Angular — Consideraciones SEO

### SSR obligatorio para páginas públicas indexables
Sin Angular Universal (SSR), los bots de Google no pueden leer el contenido
renderizado por JavaScript.

```bash
# Agregar SSR a proyecto Angular existente
ng add @angular/ssr
```

### Gestión de meta tags en Angular
```typescript
// En cada componente de página pública
constructor(private meta: Meta, private title: Title) {}

ngOnInit() {
  this.title.setTitle('Título de la página | Mi App');
  this.meta.updateTag({ name: 'description', content: '...' });
}
```

---

## Palabras clave

- Investigar términos que usa el usuario final (no jerga técnica interna)
- Incluir palabra clave principal en: título, primera oración, al menos un h2
- No repetir la misma palabra clave más de 3-4 veces en la página (keyword stuffing penaliza)

---

## Verificación rápida antes de publicar

- [ ] Título único y descriptivo (máx 60 chars)
- [ ] Meta description que invita a hacer clic (máx 160 chars)
- [ ] Un solo h1 por página
- [ ] Todas las imágenes con alt
- [ ] URL limpia (sin parámetros innecesarios)
- [ ] `noindex` en páginas de admin/privadas
- [ ] SSR activo si el contenido es renderizado por JS
