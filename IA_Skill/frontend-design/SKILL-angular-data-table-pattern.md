---
name: frontend-design/angular-data-table-pattern
description: >
  Implementa tablas de datos server-side en Angular combinando CdkTable
  (estructura, sin estilos de fábrica) con MatPaginator/MatSort de Angular
  Material (widgets de interacción ya resueltos), re-temeados con
  mat.theme() para heredar la paleta del proyecto en vez de la M3 default.
  Úsala para cualquier tabla con paginación, ordenamiento o selección de
  filas en Angular — reemplaza tanto el uso de mat-table "as-is" (se ve
  Material genérico) como construir todo a mano con CDK puro (reinventa
  paginador/sort que Material ya resuelve).
stack: Angular 17+ · @angular/cdk · @angular/material (re-temeado)
contexts: Dashboards con datos server-side · Listados con filtros/paginación · Admin panels
---

# SKILL: Tabla de Datos Angular — CDK (estructura) + Material (interacción), re-temeado

## Por qué esta combinación y no una sola librería

| Necesidad | Si usaras solo CDK | Si usaras solo Material | Esta skill (híbrido) |
|---|---|---|---|
| Estructura de tabla, binding de datos | ✅ `CdkTable` | ✅ `mat-table` (mismo motor por debajo) | ✅ `CdkTable` |
| Estilo visual | Tuyo, 100% libre | M3 de fábrica — genérico si no se re-temea | Tuyo, 100% libre |
| Paginador con lógica lista | ❌ no existe en CDK puro, hay que construirlo | ✅ `MatPaginator` | ✅ `MatPaginator` re-temeado |
| Ordenamiento de columnas | ❌ hay que construirlo | ✅ `MatSort` | ✅ `MatSort` re-temeado |

Construir paginación/sort a mano con CDK puro es reinventar algo que
Material ya resuelve con accesibilidad y edge cases cubiertos (i18n de
"items por página", teclado, ARIA). El problema real de Material no es su
lógica, es su estética de fábrica — por eso se re-temea, no se reconstruye.

---

## 1. Re-temear Angular Material con los tokens del proyecto (M3, no M2)

```scss
// styles/_material-theme.scss
@use '@angular/material' as mat;

$app-theme: mat.define-theme((
  color: (
    theme-type: light,
    primary: mat.$blue-palette,     // placeholder — el paso clave es el override de abajo
  ),
));

html {
  @include mat.core-theme($app-theme);
  @include mat.all-component-themes($app-theme);

  // Override directo con los tokens del proyecto — esto es lo que evita
  // el look "Material genérico". Angular Material 18+ expone estas
  // variables system-level y las respeta en todos sus componentes.
  --mat-sys-primary: var(--color-action-primary);
  --mat-sys-on-primary: #fff;
  --mat-sys-surface: var(--color-surface-card);
  --mat-sys-on-surface: var(--color-text-primary);
  --mat-sys-outline: var(--color-border-default);
  --mat-sys-corner-medium: var(--radius-md);
}
```

No usar la sintaxis vieja `mat.define-palette()` con paletas M2 completas
para esto — el sistema de variables `--mat-sys-*` de M3 es lo que permite
mapear un solo token del proyecto y que se propague a paginador, sort,
inputs, etc. sin tocar cada componente por separado.

---

## 2. `CdkTable` — estructura, cero estilos de fábrica

```typescript
// bugs-table.component.ts
import { CdkTableModule } from '@angular/cdk/table';
import { MatPaginatorModule, PageEvent } from '@angular/material/paginator';
import { MatSortModule, Sort } from '@angular/material/sort';

@Component({
  selector: 'app-bugs-table',
  standalone: true,
  imports: [CdkTableModule, MatPaginatorModule, MatSortModule],
  template: `
    <table cdk-table [dataSource]="bugs()" matSort (matSortChange)="onSort($event)" class="data-table">
      <ng-container cdkColumnDef="id">
        <th cdk-header-cell *cdkHeaderCellDef mat-sort-header>ID</th>
        <td cdk-cell *cdkCellDef="let row">{{ row.id }}</td>
      </ng-container>

      <ng-container cdkColumnDef="titulo">
        <th cdk-header-cell *cdkHeaderCellDef>Título</th>
        <td cdk-cell *cdkCellDef="let row">{{ row.titulo }}</td>
      </ng-container>

      <ng-container cdkColumnDef="severidad">
        <th cdk-header-cell *cdkHeaderCellDef mat-sort-header>Severidad</th>
        <td cdk-cell *cdkCellDef="let row">
          <span class="badge" [class]="'badge-' + row.severidad">{{ row.severidadLabel }}</span>
        </td>
      </ng-container>

      <tr cdk-header-row *cdkHeaderRowDef="displayedColumns"></tr>
      <tr cdk-row *cdkRowDef="let row; columns: displayedColumns"></tr>
    </table>

    <mat-paginator
      [length]="totalItems()"
      [pageSize]="pageSize()"
      [pageSizeOptions]="[10, 25, 50]"
      (page)="onPage($event)">
    </mat-paginator>
  `,
  styleUrl: './bugs-table.component.scss',
})
export class BugsTableComponent {
  displayedColumns = ['id', 'titulo', 'severidad'];
  bugs = signal<Bug[]>([]);
  totalItems = signal(0);
  pageSize = signal(10);

  // Server-side: cada cambio de página/sort dispara una nueva petición,
  // nunca se pagina/ordena en el cliente sobre el array completo.
  onPage(event: PageEvent) {
    this.pageSize.set(event.pageSize);
    this.fetchPage(event.pageIndex, event.pageSize);
  }

  onSort(sort: Sort) {
    this.fetchPage(0, this.pageSize(), sort.active, sort.direction);
  }

  private fetchPage(pageIndex: number, pageSize: number, sortField?: string, sortDir?: string) {
    // llamada al servicio — reemplaza este stub por el HttpClient real
  }
}
```

```scss
// bugs-table.component.scss — el CSS es tuyo, no hereda nada de Material aquí
.data-table {
  width: 100%;
  border-collapse: collapse;
  background: var(--color-surface-card);
  border-radius: var(--radius-md);
  overflow: hidden;
}
.data-table th {
  text-align: left;
  padding: var(--space-3) var(--space-4);
  font: 600 12px var(--font-sans);
  text-transform: uppercase;
  letter-spacing: .04em;
  color: var(--color-text-secondary);
  background: var(--color-surface-sunken);
}
.data-table td {
  padding: var(--space-3) var(--space-4);
  border-top: 1px solid var(--color-border-default);
}
.data-table tr:hover td { background: var(--color-surface-sunken); }
```

El `<table cdk-table>` no trae ni un borde por defecto — todo el CSS de
arriba es necesario y es exactamente el mismo patrón de
`SKILL-frontend-design.md`, solo que ahora conectado al binding de
`CdkTable`. El `<mat-paginator>`, en cambio, sí trae su propio look — por
eso el paso 1 (re-temeado global) es obligatorio antes de usarlo, si no,
el paginador se ve Material-azul-default mientras la tabla se ve con tu
paleta — inconsistencia visual entre dos partes del mismo componente.

---

## 3. Formularios — `mat-form-field` re-temeado (misma lógica)

```html
<mat-form-field appearance="outline">
  <mat-label>Buscar por título</mat-label>
  <input matInput [(ngModel)]="filtro" (ngModelChange)="onFiltroChange()">
</mat-form-field>
```

`appearance="outline"` + el override de `--mat-sys-*` del paso 1 ya
resuelve que no se vea Material genérico. No reconstruir el form field a
mano con CDK — la validación, el estado de error, el label flotante y el
manejo de foco que trae `mat-form-field` son justo el tipo de lógica que
no vale la pena reinventar.

---

## 4. Menús de navegación — CDK puro (`cdk/menu`, `cdk/overlay`)

Para dropdowns de navegación (no widgets de datos), usar CDK puro sin
Material — no necesitan la lógica de validación/paginación que sí justifica
usar Material en los casos anteriores.

```html
<button [cdkMenuTriggerFor]="menu">Acciones</button>
<ng-template #menu>
  <div cdkMenu class="dropdown-menu">
    <button cdkMenuItem (click)="onEditar()">Editar</button>
    <button cdkMenuItem (click)="onEliminar()">Eliminar</button>
  </div>
</ng-template>
```

```scss
.dropdown-menu {
  background: var(--color-surface-card);
  border: 1px solid var(--color-border-default);
  border-radius: var(--radius-sm);
  box-shadow: var(--shadow-card);
  padding: var(--space-1);
}
```

---

## ❌ Qué NO hacer

- No usar `mat-table` "as-is" sin el override de `--mat-sys-*` — es la
  causa directa del look "Material genérico" que se quiere evitar.
- No reconstruir paginación/sort a mano con `CdkTable` puro — ya está
  resuelto en `MatPaginator`/`MatSort`, reinventarlo es esfuerzo sin
  beneficio.
- No mezclar `mat.define-palette()` (API M2 vieja) con el override
  `--mat-sys-*` (M3) en el mismo proyecto — elegir uno, preferir M3.
- No usar Material para menús de navegación simples — ahí CDK puro basta
  y evita cargar lógica de Material innecesaria.

---

## Checklist antes de dar por terminada una tabla server-side

- [ ] El tema de Angular Material está re-temeado con `--mat-sys-*` apuntando a los tokens del proyecto, no a la paleta M3 default
- [ ] `CdkTable` maneja la estructura/datos; el CSS de celdas/filas es propio, sigue `SKILL-frontend-design.md`
- [ ] `MatPaginator`/`MatSort` disparan peticiones al servidor en cada cambio — no se pagina/ordena sobre el array completo en cliente
- [ ] Los badges de estado/severidad dentro de las celdas usan las clases ya definidas en `SKILL-frontend-design.md`, no el estilo de fábrica de Material
- [ ] Los menús de navegación usan `cdk/menu`, no `mat-menu`, salvo que se necesite lógica adicional de Material
