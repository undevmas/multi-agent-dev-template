# SKILL — Security Angular

## Cuándo usar esta skill
Al crear o revisar cualquier componente, servicio, guard o template en Angular
que maneje autenticación, autorización, datos del usuario, o rutas protegidas.

---

## XSS — Cross-Site Scripting en Angular

Angular escapa automáticamente el HTML en templates — esto es seguro por defecto:
```html
<!-- SEGURO — Angular escapa automáticamente -->
<p>{{ userInput }}</p>
<div [textContent]="userInput"></div>
```

El riesgo aparece cuando se bypasea el sistema de seguridad de Angular:

```typescript
// MAL — bypasear DomSanitizer sin justificación
@Component({
  template: `<div [innerHTML]="userContent"></div>`
})
export class PostComponent {
  userContent = this.sanitizer.bypassSecurityTrustHtml(rawHtmlFromUser); // PELIGROSO
}

// BIEN — sanitizar antes de confiar
import { DomSanitizer, SafeHtml } from '@angular/platform-browser';
import * as DOMPurify from 'dompurify';

@Component({
  template: `<div [innerHTML]="safeContent"></div>`
})
export class PostComponent {
  safeContent: SafeHtml;

  constructor(private sanitizer: DomSanitizer) {
    // Primero limpiar con DOMPurify, luego marcar como seguro
    const cleanHtml = DOMPurify.sanitize(rawHtmlFromUser, {
      ALLOWED_TAGS: ['b', 'i', 'em', 'strong', 'p', 'br', 'ul', 'li'],
      ALLOWED_ATTR: [],
    });
    this.safeContent = this.sanitizer.bypassSecurityTrustHtml(cleanHtml);
  }
}

// MAL — URLs dinámicas sin sanitizar
<a [href]="userProvidedUrl">Link</a> // puede ser javascript:alert('xss')

// BIEN — sanitizar URLs
export class SafeLinkComponent {
  constructor(private sanitizer: DomSanitizer) {}

  getSafeUrl(url: string): SafeResourceUrl {
    // Solo permitir http y https
    if (!url.startsWith('https://') && !url.startsWith('http://')) {
      return this.sanitizer.bypassSecurityTrustUrl('about:blank');
    }
    return this.sanitizer.bypassSecurityTrustUrl(url);
  }
}

// Nunca usar estos métodos con input del usuario sin sanitizar primero:
// bypassSecurityTrustHtml()
// bypassSecurityTrustStyle()
// bypassSecurityTrustScript()
// bypassSecurityTrustUrl()
// bypassSecurityTrustResourceUrl()
```

---

## Autenticación — manejo seguro de tokens

### Almacenamiento de JWT
```typescript
// MAL — localStorage es accesible desde JavaScript (vulnerable a XSS)
localStorage.setItem('access_token', token);

// MEJOR — memory storage (se pierde al recargar, pero es más seguro)
@Injectable({ providedIn: 'root' })
export class TokenService {
  private accessToken: string | null = null;

  setToken(token: string): void {
    this.accessToken = token;
  }

  getToken(): string | null {
    return this.accessToken;
  }

  clearToken(): void {
    this.accessToken = null;
  }
}

// ALTERNATIVA ACEPTABLE — sessionStorage (solo dura la sesión del tab)
// Más seguro que localStorage, menos que memory
sessionStorage.setItem('access_token', token);

// MEJOR PRÁCTICA — refresh token en cookie HttpOnly (manejado por el backend)
// El access token vive en memoria, el refresh token en cookie HttpOnly
// La cookie HttpOnly no es accesible desde JavaScript
```

### Interceptor HTTP para adjuntar el token
```typescript
@Injectable()
export class AuthInterceptor implements HttpInterceptor {
  constructor(private tokenService: TokenService) {}

  intercept(req: HttpRequest<unknown>, next: HttpHandler): Observable<HttpEvent<unknown>> {
    const token = this.tokenService.getToken();

    if (token) {
      const authReq = req.clone({
        headers: req.headers.set('Authorization', `Bearer ${token}`),
      });
      return next.handle(authReq);
    }

    return next.handle(req);
  }
}

// Registrar en app.module.ts o app.config.ts
providers: [
  { provide: HTTP_INTERCEPTORS, useClass: AuthInterceptor, multi: true },
]
```

### Manejo de token expirado
```typescript
@Injectable()
export class TokenExpiryInterceptor implements HttpInterceptor {
  constructor(
    private authService: AuthService,
    private router: Router,
  ) {}

  intercept(req: HttpRequest<unknown>, next: HttpHandler): Observable<HttpEvent<unknown>> {
    return next.handle(req).pipe(
      catchError((error: HttpErrorResponse) => {
        if (error.status === 401) {
          // Token expirado — intentar refresh o redirigir a login
          return this.authService.refreshToken().pipe(
            switchMap(newToken => {
              const retryReq = req.clone({
                headers: req.headers.set('Authorization', `Bearer ${newToken}`),
              });
              return next.handle(retryReq);
            }),
            catchError(() => {
              // Refresh también falló — logout y redirigir
              this.authService.logout();
              this.router.navigate(['/login']);
              return throwError(() => error);
            }),
          );
        }
        return throwError(() => error);
      }),
    );
  }
}
```

---

## Route Guards — protección de rutas

### AuthGuard — verificar autenticación
```typescript
@Injectable({ providedIn: 'root' })
export class AuthGuard implements CanActivate, CanActivateChild {
  constructor(
    private authService: AuthService,
    private router: Router,
  ) {}

  canActivate(route: ActivatedRouteSnapshot): boolean | UrlTree {
    return this.checkAuth(route);
  }

  canActivateChild(childRoute: ActivatedRouteSnapshot): boolean | UrlTree {
    return this.checkAuth(childRoute);
  }

  private checkAuth(route: ActivatedRouteSnapshot): boolean | UrlTree {
    if (this.authService.isAuthenticated()) {
      return true;
    }
    // Guardar la URL intentada para redirigir después del login
    return this.router.createUrlTree(['/login'], {
      queryParams: { returnUrl: route.url.join('/') },
    });
  }
}
```

### RoleGuard — verificar autorización
```typescript
@Injectable({ providedIn: 'root' })
export class RoleGuard implements CanActivate {
  constructor(
    private authService: AuthService,
    private router: Router,
  ) {}

  canActivate(route: ActivatedRouteSnapshot): boolean | UrlTree {
    const requiredRoles = route.data['roles'] as UserRole[];

    if (!requiredRoles || requiredRoles.length === 0) {
      return true;
    }

    const userRole = this.authService.getCurrentUserRole();
    const hasRole = requiredRoles.includes(userRole);

    if (!hasRole) {
      // No revelar que la ruta existe — redirigir a 403 o dashboard
      return this.router.createUrlTree(['/forbidden']);
    }

    return true;
  }
}

// Configuración en las rutas
const routes: Routes = [
  {
    path: 'admin',
    component: AdminComponent,
    canActivate: [AuthGuard, RoleGuard],
    data: { roles: [UserRole.Admin] },
  },
  {
    path: 'reports',
    component: ReportsComponent,
    canActivate: [AuthGuard, RoleGuard],
    data: { roles: [UserRole.Admin, UserRole.Manager] },
  },
];
```

### UnsavedChangesGuard — prevenir pérdida de datos
```typescript
export interface HasUnsavedChanges {
  hasUnsavedChanges(): boolean;
}

@Injectable({ providedIn: 'root' })
export class UnsavedChangesGuard implements CanDeactivate<HasUnsavedChanges> {
  canDeactivate(component: HasUnsavedChanges): boolean {
    if (component.hasUnsavedChanges()) {
      return confirm('¿Salir sin guardar los cambios?');
    }
    return true;
  }
}

// En el componente con formulario
export class ContractFormComponent implements HasUnsavedChanges {
  form = this.fb.group({ ... });

  hasUnsavedChanges(): boolean {
    return this.form.dirty;
  }
}
```

---

## Ocultar UI según rol — correctamente

```typescript
// Directiva para mostrar/ocultar según rol
@Directive({ selector: '[appHasRole]' })
export class HasRoleDirective implements OnInit {
  @Input('appHasRole') requiredRoles: UserRole | UserRole[] = [];

  constructor(
    private viewContainer: ViewContainerRef,
    private templateRef: TemplateRef<unknown>,
    private authService: AuthService,
  ) {}

  ngOnInit(): void {
    const roles = Array.isArray(this.requiredRoles)
      ? this.requiredRoles
      : [this.requiredRoles];

    const userRole = this.authService.getCurrentUserRole();

    if (roles.includes(userRole)) {
      this.viewContainer.createEmbeddedView(this.templateRef);
    } else {
      this.viewContainer.clear();
    }
  }
}

// Uso en templates
<button *appHasRole="UserRole.Admin">Eliminar usuario</button>
<nav *appHasRole="[UserRole.Admin, UserRole.Manager]">Panel de control</nav>
```

**Importante:** Ocultar UI es solo UX, NO seguridad.
El backend SIEMPRE debe verificar permisos independientemente de lo que muestre el frontend.

---

## CSRF Protection

Angular tiene protección CSRF automática con `HttpClientXsrfModule`:

```typescript
// app.module.ts — Angular lee el cookie XSRF-TOKEN y lo envía en el header
imports: [
  HttpClientModule,
  HttpClientXsrfModule.withOptions({
    cookieName: 'XSRF-TOKEN',      // nombre del cookie que envía el backend
    headerName: 'X-XSRF-TOKEN',   // nombre del header que Angular adjunta
  }),
]

// El backend debe:
// 1. Enviar el cookie XSRF-TOKEN en cada respuesta
// 2. Verificar el header X-XSRF-TOKEN en cada request POST/PUT/DELETE/PATCH
```

---

## Content Security Policy (CSP) en Angular

```html
<!-- index.html — CSP via meta tag (desarrollo) -->
<meta http-equiv="Content-Security-Policy"
  content="
    default-src 'self';
    script-src 'self';
    style-src 'self' 'unsafe-inline';
    img-src 'self' data: https:;
    connect-src 'self' https://api.midominio.com;
    font-src 'self' https://fonts.gstatic.com;
    frame-ancestors 'none';
  ">

<!-- En producción — configurar CSP en el servidor/CDN, no en meta tag -->
<!-- El header HTTP es más seguro que el meta tag -->
```

---

## Manejo seguro de variables de entorno en Angular

```typescript
// Angular no tiene variables de entorno reales en runtime
// Usar environment.ts para configuración de build

// src/environments/environment.ts (desarrollo)
export const environment = {
  production: false,
  apiUrl: 'http://localhost:5000/api/v1',
  // NUNCA poner aquí: API keys, secretos, passwords
  // El código Angular es público — cualquiera puede verlo
};

// src/environments/environment.prod.ts (producción)
export const environment = {
  production: true,
  apiUrl: 'https://api.midominio.com/api/v1',
};

// Para valores realmente sensibles que no deben estar en el bundle:
// Obtenerlos del backend en el arranque de la app
@Injectable({ providedIn: 'root' })
export class AppConfigService {
  private config: AppConfig | null = null;

  loadConfig(): Promise<void> {
    return this.http.get<AppConfig>('/api/v1/config/public')
      .toPromise()
      .then(config => { this.config = config!; });
  }
}
```

---

## Validación en formularios — doble capa

```typescript
// La validación en Angular es UX, no seguridad
// El backend SIEMPRE valida independientemente

// Reactive Forms — validación del lado cliente
this.form = this.fb.group({
  email: ['', [
    Validators.required,
    Validators.email,
    Validators.maxLength(255),
  ]],
  password: ['', [
    Validators.required,
    Validators.minLength(8),
    Validators.maxLength(128),
  ]],
});

// Prevenir submit con datos inválidos
onSubmit(): void {
  if (this.form.invalid) {
    this.form.markAllAsTouched(); // mostrar errores
    return;
  }
  // proceder con el submit
}

// Deshabilitar botón durante envío
isSubmitting = false;

async onSubmit(): Promise<void> {
  if (this.form.invalid || this.isSubmitting) return;

  this.isSubmitting = true;
  try {
    await this.userService.create(this.form.value).toPromise();
  } finally {
    this.isSubmitting = false;
  }
}
```

---

## Checklist seguridad Angular antes de PR

### XSS
- [ ] Sin uso de bypassSecurityTrust* sin sanitizar con DOMPurify primero
- [ ] Sin [innerHTML] con datos del usuario sin sanitizar
- [ ] URLs dinámicas validadas (solo http/https)

### Autenticación
- [ ] Token no guardado en localStorage (usar memory o sessionStorage)
- [ ] Interceptor HTTP adjunta token en requests
- [ ] Interceptor maneja 401 con refresh o logout

### Autorización
- [ ] Rutas protegidas tienen AuthGuard
- [ ] Rutas con roles tienen RoleGuard con data.roles definido
- [ ] Ocultar UI con directiva HasRole (recordar: solo es UX, el backend valida)

### Formularios
- [ ] Validaciones client-side implementadas (Validators)
- [ ] Botón deshabilitado durante submit (prevenir doble envío)
- [ ] UnsavedChangesGuard en formularios con datos importantes

### Configuración
- [ ] Sin secretos ni API keys en environment.ts
- [ ] CSRF habilitado con HttpClientXsrfModule
- [ ] CSP configurado en el servidor para producción
