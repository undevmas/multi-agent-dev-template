# SKILL — Impeccable (Calidad de código frontend)

## Cuándo usar esta skill
Al revisar o generar código frontend (Angular o React).
Al hacer code review de componentes, servicios, templates o estilos.
Complementa SKILL-frontend-design.md (estética) y SKILL-ux-pro.md (comportamiento)
— esta skill se enfoca en calidad, consistencia y mantenibilidad del código.

---

## Principios de código frontend impecable

### 1. Un componente, una responsabilidad
```typescript
// MAL — componente hace demasiado
@Component({ selector: 'app-user-page' })
export class UserPageComponent {
  // lógica de auth
  // lógica de fetch de datos
  // lógica de transformación
  // lógica de formulario
  // lógica de navegación
  // template con 300 líneas
}

// BIEN — separar responsabilidades
// UserPageComponent    → layout y coordinación
// UserFormComponent    → formulario y validaciones
// UserListComponent    → listado y paginación
// UserService          → fetch y transformación
```

### 2. Componentes pequeños y enfocados
```
Señales de que un componente es demasiado grande:
- Template con más de 100 líneas
- Clase con más de 150 líneas
- Más de 5 @Input() o @Output()
- Más de 3 servicios inyectados
- Hace más de una cosa reconocible
```

### 3. Consistencia sobre creatividad
```
En un equipo, la consistencia importa más que el estilo personal.
Seguir los patrones establecidos en el proyecto aunque
"se te ocurra algo mejor" — proponer el cambio primero.
```

---

## Angular — calidad de código

### Naming conventions estrictas
```typescript
// Componentes: kebab-case selector, PascalCase clase
@Component({ selector: 'app-user-list' })
export class UserListComponent { }

// Servicios: siempre con sufijo Service
export class UserService { }
export class AuthService { }

// Guards: sufijo Guard
export class AuthGuard { }
export class RoleGuard { }

// Pipes: sufijo Pipe
export class DateFormatPipe { }
export class CurrencyMxPipe { }

// Directivas: prefijo app, sufijo Directive
@Directive({ selector: '[appAutoFocus]' })
export class AutoFocusDirective { }

// Interfaces/Models: sufijo Model o sin sufijo (no prefijo I)
export interface User { }
export interface UserModel { }
// evitar: IUser, UserInterface

// Archivos: kebab-case con sufijo del tipo
// user-list.component.ts
// user.service.ts
// auth.guard.ts
// date-format.pipe.ts
```

### Template — reglas de calidad
```html
<!-- MAL — lógica compleja en el template -->
<div *ngIf="users.length > 0 && !loading && currentUser?.role === 'admin'">

<!-- BIEN — lógica en el componente, nombre descriptivo -->
<div *ngIf="canShowUserList">

<!-- MAL — múltiples responsabilidades en un template grande -->
<!-- 200 líneas de HTML en un solo archivo -->

<!-- BIEN — componentes más pequeños y reutilizables -->
<app-user-filter (filterChange)="onFilterChange($event)" />
<app-user-table [users]="users" [loading]="loading" />
<app-pagination [total]="total" [(page)]="currentPage" />

<!-- MAL — strings hardcodeados en el template -->
<button>Guardar cambios</button>

<!-- BIEN — constantes o i18n desde el componente -->
<button>{{ labels.save }}</button>

<!-- Usar trackBy en ngFor para performance -->
<!-- MAL -->
<li *ngFor="let user of users">

<!-- BIEN -->
<li *ngFor="let user of users; trackBy: trackByUserId">
```

```typescript
// trackBy function en el componente
trackByUserId(index: number, user: User): string {
  return user.id;
}

// Getter para lógica compleja del template
get canShowUserList(): boolean {
  return this.users.length > 0 &&
    !this.loading &&
    this.currentUser?.role === UserRole.Admin;
}
```

### Manejo de subscripciones — evitar memory leaks
```typescript
// MAL — suscripción sin desuscribir
export class UserListComponent implements OnInit {
  ngOnInit() {
    this.userService.getUsers().subscribe(users => {
      this.users = users; // memory leak si el componente se destruye
    });
  }
}

// BIEN — opción 1: takeUntilDestroyed (Angular 16+)
export class UserListComponent {
  private destroyRef = inject(DestroyRef);

  ngOnInit() {
    this.userService.getUsers()
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe(users => this.users = users);
  }
}

// BIEN — opción 2: AsyncPipe (preferida cuando es posible)
export class UserListComponent {
  users$ = this.userService.getUsers();
  // En el template: *ngFor="let user of users$ | async"
}

// BIEN — opción 3: Subject para componentes complejos
export class UserListComponent implements OnDestroy {
  private destroy$ = new Subject<void>();

  ngOnInit() {
    this.userService.getUsers()
      .pipe(takeUntil(this.destroy$))
      .subscribe(users => this.users = users);
  }

  ngOnDestroy() {
    this.destroy$.next();
    this.destroy$.complete();
  }
}
```

### Change Detection — optimización
```typescript
// Usar OnPush para componentes que reciben datos por @Input
@Component({
  selector: 'app-user-card',
  changeDetection: ChangeDetectionStrategy.OnPush, // solo re-renderiza cuando inputs cambian
})
export class UserCardComponent {
  @Input() user!: User;
}

// Con OnPush, los Observables deben usar async pipe o markForCheck
@Component({ changeDetection: ChangeDetectionStrategy.OnPush })
export class UserListComponent {
  constructor(private cdr: ChangeDetectorRef) {}

  updateData() {
    this.data = newData;
    this.cdr.markForCheck(); // notificar que hay cambios
  }
}
```

---

## React — calidad de código

### Componentes funcionales limpios
```typescript
// MAL — componente hace demasiado
export function UserPage() {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(false);
  const [filter, setFilter] = useState('');
  const [selectedUser, setSelectedUser] = useState(null);
  const [isModalOpen, setIsModalOpen] = useState(false);
  // ... 200 líneas más
}

// BIEN — extraer lógica a hooks, UI a componentes
export function UserPage() {
  const { users, loading, filter, setFilter } = useUsers();
  const { selectedUser, isModalOpen, openModal, closeModal } = useUserModal();

  return (
    <div>
      <UserFilter value={filter} onChange={setFilter} />
      <UserList users={users} loading={loading} onSelect={openModal} />
      {isModalOpen && <UserModal user={selectedUser} onClose={closeModal} />}
    </div>
  );
}
```

### Custom hooks — extraer lógica reutilizable
```typescript
// Hook para lógica de usuarios
function useUsers(filter?: string) {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    setError(null);

    userService.getAll(filter)
      .then(data => {
        if (!cancelled) setUsers(data);
      })
      .catch(err => {
        if (!cancelled) setError(err.message);
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });

    return () => { cancelled = true; }; // cleanup
  }, [filter]);

  return { users, loading, error };
}
```

### Props — tipado estricto
```typescript
// MAL — props sin tipar o con any
function UserCard({ user, onDelete }: any) { }

// BIEN — interfaz explícita
interface UserCardProps {
  user: User;
  onDelete: (userId: string) => void;
  isSelected?: boolean; // opcional con ?
  className?: string;
}

function UserCard({ user, onDelete, isSelected = false, className }: UserCardProps) {
  return (
    <div className={`user-card ${isSelected ? 'selected' : ''} ${className ?? ''}`}>
      {/* ... */}
    </div>
  );
}
```

### Keys en listas — siempre estables
```typescript
// MAL — key con índice del array
{users.map((user, index) => (
  <UserCard key={index} user={user} /> // problemático si el array cambia
))}

// BIEN — key con ID único estable
{users.map(user => (
  <UserCard key={user.id} user={user} />
))}
```

---

## CSS / Estilos — calidad

### Evitar estilos globales no intencionados
```scss
// MAL — selector demasiado genérico que puede afectar otros componentes
button { color: red; }
.container { width: 100%; }

// BIEN — scoped con clase específica del componente
.user-list__button { color: red; }
.user-list__container { width: 100%; }

// En Angular — ViewEncapsulation protege automáticamente
// En React — CSS Modules o styled-components para aislamiento
```

### Nombrar clases con BEM (Block Element Modifier)
```scss
// Block
.user-card { }

// Element
.user-card__name { }
.user-card__avatar { }
.user-card__actions { }

// Modifier
.user-card--selected { }
.user-card--loading { }
.user-card__button--primary { }
.user-card__button--danger { }
```

### Variables CSS — no hardcodear valores
```scss
// MAL — valores magic hardcodeados
.user-card {
  color: #1a2b3c;
  font-size: 14px;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

// BIEN — variables del design system del proyecto
.user-card {
  color: var(--color-text-primary);
  font-size: var(--font-size-sm);
  border-radius: var(--border-radius-md);
  box-shadow: var(--shadow-sm);
}
```

---

## Accesibilidad — no negociable

```html
<!-- Imágenes siempre con alt -->
<img src="avatar.jpg" alt="Foto de perfil de Juan García">
<img src="decorative.svg" alt=""> <!-- decorativa: alt vacío -->

<!-- Botones con texto descriptivo -->
<!-- MAL -->
<button><icon-delete /></button>
<!-- BIEN -->
<button aria-label="Eliminar usuario Juan García">
  <icon-delete />
</button>

<!-- Formularios con labels asociados -->
<!-- MAL -->
<input placeholder="Correo electrónico">
<!-- BIEN -->
<label for="email">Correo electrónico</label>
<input id="email" type="email" placeholder="usuario@example.com">

<!-- Roles ARIA para navegación -->
<nav aria-label="Navegación principal">
<main aria-label="Contenido principal">
<aside aria-label="Panel de filtros">

<!-- Estados dinámicos comunicados a lectores de pantalla -->
<div aria-live="polite" aria-atomic="true">
  {{ statusMessage }} <!-- se anuncia cuando cambia -->
</div>

<!-- Foco visible para navegación con teclado -->
/* CSS — nunca eliminar outline sin reemplazarlo */
:focus-visible {
  outline: 2px solid var(--color-primary);
  outline-offset: 2px;
}
```

---

## Code review checklist frontend

### Estructura y organización
- [ ] Componente tiene una sola responsabilidad
- [ ] Template tiene menos de 100 líneas
- [ ] Clase del componente tiene menos de 150 líneas
- [ ] Lógica compleja extraída a getters o métodos privados
- [ ] Naming conventions seguidas (sufijos, kebab-case, etc.)

### Performance
- [ ] trackBy en todos los *ngFor / key en React lists
- [ ] OnPush donde aplique (Angular)
- [ ] Sin suscripciones sin desuscribir
- [ ] AsyncPipe preferida sobre subscribe manual
- [ ] Sin lógica pesada en el template (usar getters o pipes)

### Calidad de código
- [ ] Sin lógica en templates que pertenece al componente
- [ ] Sin strings hardcodeados que deberían ser constantes
- [ ] Props/Inputs tipados estrictamente
- [ ] Sin `any` en TypeScript

### Estilos
- [ ] Sin valores magic (usar variables CSS)
- [ ] Clases con nombres descriptivos (BEM recomendado)
- [ ] Sin estilos globales no intencionados

### Accesibilidad
- [ ] Imágenes con alt apropiado
- [ ] Botones con texto o aria-label
- [ ] Inputs con label asociado
- [ ] outline visible en focus (no eliminado sin reemplazo)
