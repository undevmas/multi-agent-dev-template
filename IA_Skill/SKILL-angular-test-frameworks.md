# SKILL — Angular Test Frameworks

## Cuándo usar esta skill
Al escribir, revisar o estructurar tests en el proyecto Angular.
Leer antes de crear cualquier archivo `.spec.ts` en el frontend Angular.

Framework: Jest (no Karma)
Módulo de testing: @angular/core/testing (TestBed, ComponentFixture)
HTTP mocking: HttpClientTestingModule
Assertions: expect() nativo de Jest

---

## Estructura de archivos de test

```
src/
└── app/
    ├── core/
    │   ├── guards/
    │   │   ├── auth.guard.ts
    │   │   └── auth.guard.spec.ts
    │   └── interceptors/
    │       ├── auth.interceptor.ts
    │       └── auth.interceptor.spec.ts
    └── features/
        └── [feature]/
            ├── services/
            │   ├── [feature].service.ts
            │   └── [feature].service.spec.ts
            └── components/
                └── [feature]-list/
                    ├── [feature]-list.component.ts
                    └── [feature]-list.component.spec.ts
```

Convención de nombres:
- Archivo: `[clase].spec.ts` junto al archivo que testea
- Describe: nombre de la clase o componente
- It: descripción del comportamiento esperado en español

---

## Tests de Services

```typescript
// users.service.spec.ts
describe('UsersService', () => {
  let service: UsersService;
  let httpMock: HttpTestingController;

  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [HttpClientTestingModule],
      providers: [UsersService],
    });

    service = TestBed.inject(UsersService);
    httpMock = TestBed.inject(HttpTestingController);
  });

  afterEach(() => httpMock.verify()); // sin requests pendientes sin verificar

  it('getAll retorna lista de usuarios', () => {
    const mockResponse = {
      success: true,
      data: { items: [{ id: 'uuid-1', email: 'a@test.com', fullName: 'Test' }], total: 1 },
      message: 'Operación exitosa',
      errors: [],
    };

    service.getAll().subscribe(result => {
      expect(result.data.items.length).toBe(1);
      expect(result.data.items[0].email).toBe('a@test.com');
    });

    const req = httpMock.expectOne('/api/v1/users');
    expect(req.request.method).toBe('GET');
    req.flush(mockResponse);
  });

  it('getById con ID válido retorna el usuario', () => {
    const mockUser = { id: 'uuid-1', email: 'test@test.com', fullName: 'Test' };

    service.getById('uuid-1').subscribe(result => {
      expect(result.data).toEqual(mockUser);
    });

    const req = httpMock.expectOne('/api/v1/users/uuid-1');
    expect(req.request.method).toBe('GET');
    req.flush({ success: true, data: mockUser, message: '', errors: [] });
  });

  it('create envía POST con el body correcto', () => {
    const dto = { email: 'nuevo@test.com', password: 'Pass123!', fullName: 'Nuevo' };

    service.create(dto).subscribe();

    const req = httpMock.expectOne('/api/v1/users');
    expect(req.request.method).toBe('POST');
    expect(req.request.body).toEqual(dto);
    req.flush({ success: true, data: { id: 'new-uuid', ...dto }, message: '', errors: [] });
  });

  it('cuando el servidor retorna 401 lanza error', () => {
    service.getAll().subscribe({
      error: (err) => {
        expect(err.status).toBe(401);
      },
    });

    const req = httpMock.expectOne('/api/v1/users');
    req.flush('Unauthorized', { status: 401, statusText: 'Unauthorized' });
  });
});
```

---

## Tests de Componentes con TestBed

```typescript
// user-list.component.spec.ts
describe('UserListComponent', () => {
  let component: UserListComponent;
  let fixture: ComponentFixture<UserListComponent>;
  let usersService: jest.Mocked<UsersService>;

  beforeEach(async () => {
    const usersServiceMock = {
      getAll: jest.fn().mockReturnValue(of({
        success: true,
        data: { items: [], total: 0, page: 1, pageSize: 20 },
        message: '',
        errors: [],
      })),
    };

    await TestBed.configureTestingModule({
      imports: [UserListComponent], // standalone component
      providers: [
        { provide: UsersService, useValue: usersServiceMock },
      ],
    }).compileComponents();

    fixture = TestBed.createComponent(UserListComponent);
    component = fixture.componentInstance;
    usersService = TestBed.inject(UsersService) as jest.Mocked<UsersService>;
  });

  it('se crea correctamente', () => {
    expect(component).toBeTruthy();
  });

  it('llama a getAll al inicializar', () => {
    fixture.detectChanges(); // ngOnInit
    expect(usersService.getAll).toHaveBeenCalledTimes(1);
  });

  it('muestra mensaje de lista vacía cuando no hay usuarios', () => {
    fixture.detectChanges();
    const compiled = fixture.nativeElement as HTMLElement;
    expect(compiled.querySelector('[data-testid="empty-state"]')).toBeTruthy();
  });

  it('muestra spinner durante la carga', () => {
    component.loading = true;
    fixture.detectChanges();
    const compiled = fixture.nativeElement as HTMLElement;
    expect(compiled.querySelector('[data-testid="loading-spinner"]')).toBeTruthy();
  });

  it('muestra los usuarios cuando la carga termina', () => {
    const mockUsers = [
      { id: 'uuid-1', email: 'a@test.com', fullName: 'Usuario A' },
      { id: 'uuid-2', email: 'b@test.com', fullName: 'Usuario B' },
    ];
    usersService.getAll.mockReturnValue(of({
      success: true,
      data: { items: mockUsers, total: 2, page: 1, pageSize: 20 },
      message: '',
      errors: [],
    }));

    fixture.detectChanges();
    const rows = fixture.nativeElement.querySelectorAll('[data-testid="user-row"]');
    expect(rows.length).toBe(2);
  });
});
```

---

## Tests de Forms reactivos

```typescript
// login-form.component.spec.ts
describe('LoginFormComponent', () => {
  let component: LoginFormComponent;
  let fixture: ComponentFixture<LoginFormComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [LoginFormComponent, ReactiveFormsModule],
      providers: [
        { provide: AuthService, useValue: { login: jest.fn().mockReturnValue(of({})) } },
        { provide: Router, useValue: { navigate: jest.fn() } },
      ],
    }).compileComponents();

    fixture = TestBed.createComponent(LoginFormComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('el formulario es inválido cuando está vacío', () => {
    expect(component.form.invalid).toBe(true);
  });

  it('el campo email es inválido con formato incorrecto', () => {
    component.form.patchValue({ email: 'no-es-email' });
    const emailControl = component.form.get('email');
    expect(emailControl?.errors?.['email']).toBeTruthy();
  });

  it('el botón de submit está deshabilitado con formulario inválido', () => {
    fixture.detectChanges();
    const button = fixture.nativeElement.querySelector('[data-testid="submit-btn"]');
    expect(button.disabled).toBe(true);
  });

  it('el submit con datos válidos llama al servicio de auth', () => {
    const authService = TestBed.inject(AuthService) as jest.Mocked<AuthService>;
    component.form.patchValue({ email: 'user@test.com', password: 'Password123!' });
    fixture.detectChanges();

    component.onSubmit();

    expect(authService.login).toHaveBeenCalledWith({
      email: 'user@test.com',
      password: 'Password123!',
    });
  });
});
```

---

## Tests de Guards

```typescript
// auth.guard.spec.ts
describe('AuthGuard', () => {
  let guard: AuthGuard;
  let authService: jest.Mocked<AuthService>;
  let router: jest.Mocked<Router>;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [
        AuthGuard,
        { provide: AuthService, useValue: { isAuthenticated: jest.fn() } },
        { provide: Router, useValue: { createUrlTree: jest.fn(), navigate: jest.fn() } },
      ],
    });

    guard = TestBed.inject(AuthGuard);
    authService = TestBed.inject(AuthService) as jest.Mocked<AuthService>;
    router = TestBed.inject(Router) as jest.Mocked<Router>;
  });

  it('permite acceso cuando el usuario está autenticado', () => {
    authService.isAuthenticated.mockReturnValue(true);
    const result = guard.canActivate({} as ActivatedRouteSnapshot, {} as RouterStateSnapshot);
    expect(result).toBe(true);
  });

  it('redirige a /login cuando el usuario no está autenticado', () => {
    authService.isAuthenticated.mockReturnValue(false);
    router.createUrlTree.mockReturnValue({ toString: () => '/login' } as UrlTree);

    const result = guard.canActivate({} as ActivatedRouteSnapshot, {} as RouterStateSnapshot);

    expect(router.createUrlTree).toHaveBeenCalledWith(['/login'], expect.any(Object));
    expect(result).not.toBe(true);
  });
});
```

---

## Tests de Pipes

```typescript
// date-format.pipe.spec.ts
describe('DateFormatPipe', () => {
  const pipe = new DateFormatPipe();

  it('formatea fecha en formato DD/MM/YYYY', () => {
    const date = new Date('2025-05-27');
    expect(pipe.transform(date)).toBe('27/05/2025');
  });

  it('retorna cadena vacía para valor null', () => {
    expect(pipe.transform(null)).toBe('');
  });

  it('retorna cadena vacía para undefined', () => {
    expect(pipe.transform(undefined)).toBe('');
  });
});
```

---

## Tests con Signals (Angular 17+)

```typescript
// counter.component.spec.ts — componente con signals
describe('CounterComponent', () => {
  let fixture: ComponentFixture<CounterComponent>;
  let component: CounterComponent;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [CounterComponent],
    }).compileComponents();

    fixture = TestBed.createComponent(CounterComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('el valor inicial del signal es 0', () => {
    expect(component.count()).toBe(0);
  });

  it('increment actualiza el signal y re-renderiza', () => {
    component.increment();
    fixture.detectChanges();

    expect(component.count()).toBe(1);
    const display = fixture.nativeElement.querySelector('[data-testid="count-display"]');
    expect(display.textContent).toContain('1');
  });
});
```

---

## Ejecutar tests

```bash
# Todos los tests
npm test

# Un archivo específico
npx jest user-list.component.spec.ts

# Con cobertura
npm test -- --coverage

# Watch mode durante desarrollo
npm test -- --watch
```

---

## Cobertura mínima requerida

- Services: 80% (happy path + errores HTTP principales)
- Components con lógica compleja: 70%
- Guards: 100% (todos los casos: autenticado, no autenticado, por rol)
- Pipes: 100% (cada transformación y caso borde)
- Interceptors: 80%
