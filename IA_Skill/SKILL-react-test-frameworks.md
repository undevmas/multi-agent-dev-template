# SKILL — React Test Frameworks

## Cuándo usar esta skill
Al escribir, revisar o estructurar tests en el proyecto React.
Leer antes de crear cualquier archivo de test en el frontend React.

Framework: Jest
Librería de testing: React Testing Library (@testing-library/react)
Interacciones: @testing-library/user-event
Mocking HTTP: msw (Mock Service Worker) o jest.fn()
Assertions: expect() nativo de Jest

---

## Estructura de archivos de test

```
src/
├── components/
│   └── UserCard/
│       ├── UserCard.tsx
│       └── UserCard.test.tsx
├── pages/
│   └── UsersPage/
│       ├── UsersPage.tsx
│       └── UsersPage.test.tsx
├── hooks/
│   └── useUsers/
│       ├── useUsers.ts
│       └── useUsers.test.ts
├── services/
│   └── users.service.test.ts
└── __mocks__/
    └── [mocks de módulos externos]
```

Convención de nombres:
- Archivos: `[componente].test.tsx` junto al componente que testea
- Describe: nombre del componente o hook
- It/Test: comportamiento esperado en español

---

## Setup de testing

```json
// package.json
{
  "jest": {
    "testEnvironment": "jsdom",
    "setupFilesAfterFramework": ["@testing-library/jest-dom"],
    "transform": {
      "^.+\\.(ts|tsx)$": "ts-jest"
    },
    "moduleNameMapper": {
      "\\.(css|scss)$": "identity-obj-proxy"
    }
  }
}
```

```typescript
// src/setupTests.ts
import '@testing-library/jest-dom';
```

---

## Tests de Componentes

```typescript
// UserCard.test.tsx
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { UserCard } from './UserCard';

describe('UserCard', () => {
  const mockUser: User = {
    id: 'uuid-1',
    email: 'test@example.com',
    fullName: 'Juan García',
    createdAt: new Date('2025-01-15'),
  };

  it('muestra el nombre y email del usuario', () => {
    render(<UserCard user={mockUser} onDelete={jest.fn()} />);

    expect(screen.getByText('Juan García')).toBeInTheDocument();
    expect(screen.getByText('test@example.com')).toBeInTheDocument();
  });

  it('llama a onDelete con el ID correcto al hacer click en eliminar', async () => {
    const handleDelete = jest.fn();
    render(<UserCard user={mockUser} onDelete={handleDelete} />);

    await userEvent.click(screen.getByRole('button', { name: /eliminar/i }));

    expect(handleDelete).toHaveBeenCalledWith('uuid-1');
    expect(handleDelete).toHaveBeenCalledTimes(1);
  });

  it('aplica clase "selected" cuando isSelected es true', () => {
    const { container } = render(
      <UserCard user={mockUser} onDelete={jest.fn()} isSelected={true} />
    );

    expect(container.firstChild).toHaveClass('selected');
  });

  it('no muestra botón de eliminar cuando el usuario no tiene permisos', () => {
    render(<UserCard user={mockUser} onDelete={jest.fn()} canDelete={false} />);

    expect(screen.queryByRole('button', { name: /eliminar/i })).not.toBeInTheDocument();
  });
});
```

---

## Los 4 estados — testing obligatorio

```typescript
// UsersPage.test.tsx — testear todos los estados de la UI
describe('UsersPage', () => {
  it('estado loading — muestra skeleton mientras carga', () => {
    // Mock del hook en estado de carga
    jest.spyOn(useUsersModule, 'useUsers').mockReturnValue({
      users: [], loading: true, error: null,
    });

    render(<UsersPage />);
    expect(screen.getByTestId('loading-skeleton')).toBeInTheDocument();
    expect(screen.queryByTestId('users-table')).not.toBeInTheDocument();
  });

  it('estado empty — muestra mensaje y CTA cuando no hay usuarios', () => {
    jest.spyOn(useUsersModule, 'useUsers').mockReturnValue({
      users: [], loading: false, error: null,
    });

    render(<UsersPage />);
    expect(screen.getByText(/no hay usuarios/i)).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /crear usuario/i })).toBeInTheDocument();
  });

  it('estado error — muestra mensaje con opción de reintentar', () => {
    jest.spyOn(useUsersModule, 'useUsers').mockReturnValue({
      users: [], loading: false, error: 'Sin conexión con el servidor.',
    });

    render(<UsersPage />);
    expect(screen.getByText(/sin conexión/i)).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /intentar de nuevo/i })).toBeInTheDocument();
  });

  it('estado success — muestra la tabla con los usuarios', () => {
    const mockUsers = [
      { id: 'uuid-1', email: 'a@test.com', fullName: 'Usuario A' },
      { id: 'uuid-2', email: 'b@test.com', fullName: 'Usuario B' },
    ];
    jest.spyOn(useUsersModule, 'useUsers').mockReturnValue({
      users: mockUsers, loading: false, error: null,
    });

    render(<UsersPage />);
    expect(screen.getAllByRole('row')).toHaveLength(3); // 1 header + 2 datos
    expect(screen.getByText('Usuario A')).toBeInTheDocument();
  });
});
```

---

## Tests de Custom Hooks

```typescript
// useUsers.test.ts
import { renderHook, act, waitFor } from '@testing-library/react';
import { useUsers } from './useUsers';
import * as usersService from '@/services/users.service';

describe('useUsers', () => {
  afterEach(() => jest.restoreAllMocks());

  it('retorna loading=true mientras carga', () => {
    jest.spyOn(usersService, 'getAll').mockReturnValue(new Promise(() => {})); // nunca resuelve

    const { result } = renderHook(() => useUsers());

    expect(result.current.loading).toBe(true);
    expect(result.current.users).toEqual([]);
  });

  it('retorna los usuarios cuando la petición es exitosa', async () => {
    const mockUsers = [{ id: 'uuid-1', email: 'a@test.com', fullName: 'Test' }];
    jest.spyOn(usersService, 'getAll').mockResolvedValue({
      success: true,
      data: { items: mockUsers, total: 1 },
      message: '',
      errors: [],
    });

    const { result } = renderHook(() => useUsers());

    await waitFor(() => expect(result.current.loading).toBe(false));

    expect(result.current.users).toEqual(mockUsers);
    expect(result.current.error).toBeNull();
  });

  it('retorna error cuando la petición falla', async () => {
    jest.spyOn(usersService, 'getAll').mockRejectedValue(new Error('Sin conexión'));

    const { result } = renderHook(() => useUsers());

    await waitFor(() => expect(result.current.loading).toBe(false));

    expect(result.current.error).toBe('Sin conexión');
    expect(result.current.users).toEqual([]);
  });

  it('refetch vuelve a cargar los datos', async () => {
    const getSpy = jest.spyOn(usersService, 'getAll').mockResolvedValue({
      success: true, data: { items: [], total: 0 }, message: '', errors: [],
    });

    const { result } = renderHook(() => useUsers());
    await waitFor(() => expect(result.current.loading).toBe(false));

    act(() => result.current.refetch());
    await waitFor(() => expect(result.current.loading).toBe(false));

    expect(getSpy).toHaveBeenCalledTimes(2);
  });
});
```

---

## Tests de formularios

```typescript
// LoginForm.test.tsx
describe('LoginForm', () => {
  it('el botón de submit está deshabilitado hasta que el formulario es válido', () => {
    render(<LoginForm onSubmit={jest.fn()} />);

    const submitButton = screen.getByRole('button', { name: /iniciar sesión/i });
    expect(submitButton).toBeDisabled();
  });

  it('muestra error de validación al salir del campo email con valor inválido', async () => {
    render(<LoginForm onSubmit={jest.fn()} />);

    const emailInput = screen.getByLabelText(/correo electrónico/i);
    await userEvent.type(emailInput, 'no-es-email');
    await userEvent.tab(); // blur

    expect(screen.getByText(/correo no válido/i)).toBeInTheDocument();
  });

  it('llama a onSubmit con los datos correctos', async () => {
    const handleSubmit = jest.fn();
    render(<LoginForm onSubmit={handleSubmit} />);

    await userEvent.type(screen.getByLabelText(/correo electrónico/i), 'user@test.com');
    await userEvent.type(screen.getByLabelText(/contraseña/i), 'Password123!');
    await userEvent.click(screen.getByRole('button', { name: /iniciar sesión/i }));

    expect(handleSubmit).toHaveBeenCalledWith({
      email: 'user@test.com',
      password: 'Password123!',
    });
  });

  it('deshabilita el botón durante el envío para evitar doble submit', async () => {
    // onSubmit que nunca resuelve — simula carga
    const handleSubmit = jest.fn(() => new Promise(() => {}));
    render(<LoginForm onSubmit={handleSubmit} />);

    await userEvent.type(screen.getByLabelText(/correo electrónico/i), 'user@test.com');
    await userEvent.type(screen.getByLabelText(/contraseña/i), 'Password123!');
    await userEvent.click(screen.getByRole('button', { name: /iniciar sesión/i }));

    expect(screen.getByRole('button', { name: /iniciando/i })).toBeDisabled();
  });
});
```

---

## Mocking de servicios HTTP con MSW

```typescript
// src/mocks/handlers.ts — definir mocks una vez, usar en todos los tests
import { http, HttpResponse } from 'msw';

export const handlers = [
  http.get('/api/v1/users', () => {
    return HttpResponse.json({
      success: true,
      data: { items: [{ id: 'uuid-1', email: 'a@test.com', fullName: 'Test' }], total: 1 },
      message: 'Operación exitosa',
      errors: [],
    });
  }),

  http.post('/api/v1/auth/login', () => {
    return HttpResponse.json({
      success: true,
      data: { accessToken: 'mock-token', expiresIn: 28800 },
      message: 'Login exitoso',
      errors: [],
    });
  }),

  http.post('/api/v1/auth/login', async ({ request }) => {
    const body = await request.json() as { email: string; password: string };
    if (body.password === 'wrong') {
      return HttpResponse.json(
        { success: false, data: null, message: 'Credenciales inválidas', errors: [] },
        { status: 401 }
      );
    }
    return HttpResponse.json({ success: true, data: { accessToken: 'token' }, message: '', errors: [] });
  }),
];

// src/mocks/server.ts
import { setupServer } from 'msw/node';
import { handlers } from './handlers';

export const server = setupServer(...handlers);

// src/setupTests.ts
import { server } from './mocks/server';
beforeAll(() => server.listen());
afterEach(() => server.resetHandlers());
afterAll(() => server.close());
```

---

## Utilidades de testing frecuentes

```typescript
// test-utils.tsx — wrapper con providers globales
import { render, RenderOptions } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';

const queryClient = new QueryClient({
  defaultOptions: { queries: { retry: false } }, // sin reintentos en tests
});

function AllProviders({ children }: { children: React.ReactNode }) {
  return (
    <QueryClientProvider client={queryClient}>
      {children}
    </QueryClientProvider>
  );
}

// Exportar render con providers incluidos
export function renderWithProviders(ui: React.ReactElement, options?: RenderOptions) {
  return render(ui, { wrapper: AllProviders, ...options });
}

// Selectores semánticos preferidos (en orden de preferencia)
// 1. getByRole         — botones, inputs, headings, etc.
// 2. getByLabelText    — inputs con label
// 3. getByText         — texto visible
// 4. getByTestId       — último recurso, usar data-testid="x"

// EVITAR: getByClassName, getByTagName — frágiles ante cambios de estilo
```

---

## Ejecutar tests

```bash
# Todos los tests
npm test

# Un archivo específico
npx jest UserCard.test.tsx

# Con cobertura
npm test -- --coverage

# Watch mode
npm test -- --watch

# Solo archivos modificados
npm test -- --onlyChanged
```

---

## Cobertura mínima requerida

- Componentes con lógica (forms, tablas, modales): 75%
- Custom hooks: 80% (happy path + error + loading)
- Páginas completas: cubiertos por tests de componentes hijos
- Utilities y helpers: 90%
- Los 4 estados (loading, empty, error, success): obligatorio en cada componente que carga datos
