# TP2 - Etapa 2: plan técnico y contrato inicial

## Resultado

La integración queda preparada para que el frontend Angular se desarrolle
contra un contrato verificable y un entorno local reproducible.

- El contrato completo está en [tp2_api_contract.md](tp2_api_contract.md).
- El origen local predeterminado de CORS es `http://localhost:4200`.
- `demo:setup` crea cuentas, catálogo, oferta y disponibilidad idempotentes.
- El frontend se organizará en un repositorio separado llamado
  `appointment_scheduler_frontend`.

## Arquitectura prevista del frontend

Angular utilizará componentes standalone y separación por funcionalidades:

```text
src/app/
├── core/       # API, autenticación, interceptor, guards y configuración
├── shared/     # componentes de carga, vacío, error y confirmación
└── features/
    ├── auth/
    ├── services/
    ├── booking/
    ├── appointments/
    └── profile/
```

Las rutas públicas serán catálogo, login y registro. Turnos y perfil serán rutas
protegidas. El flujo de reserva podrá comenzar sin sesión, pero exigirá login
antes de persistir el turno y conservará la URL de retorno.

## Sesión y errores

- El token se guardará en `sessionStorage`.
- Un interceptor añadirá `Authorization: Bearer` sólo a la URL configurada de la
  API.
- Un `401` eliminará la sesión local y redirigirá a `/login`.
- Los errores `validation_failed` se mapearán a los controles por las claves de
  `details`; los errores generales se mostrarán en un resumen accesible.
- Las mutaciones ignorarán envíos repetidos mientras estén en curso.

## Modelos TypeScript previstos

El frontend definirá tipos para `User`, `Service`, `StaffMember`, `Slot`,
`Appointment`, `ApiError`, `ApiResponse<T>` y `PaginatedResponse<T>`. Los campos
opcionales y enums respetarán exactamente el contrato, sin inferir datos del
back-office.

## Preparación local del backend

```powershell
$env:DEMO_ADMIN_PASSWORD = "admin-pass-123"
$env:DEMO_CUSTOMER_PASSWORD = "customer-pass-123"
bundle exec rails db:prepare demo:setup
bundle exec rails server
```

El comando se puede repetir sin duplicar los registros. Se niega a ejecutarse
en producción. Crea:

- `admin.demo@example.com` como administrador;
- `cliente.demo@example.com` como cliente API;
- un servicio `Corte demo` de 30 minutos;
- una profesional y su oferta activa;
- disponibilidad de lunes a viernes de 09:00 a 18:00.

Las contraseñas nunca se guardan en el repositorio y deben proporcionarse por
variables de entorno.

## Verificación prevista

- specs del servicio de datos demo y de CORS;
- suite Rails sin pruebas de sistema;
- RuboCop, Zeitwerk, Brakeman y bundler-audit;
- CI completo del pull request.

## Pendiente para la Etapa 3

- integrar registro y login reales;
- implementar sesión, interceptor y guards;
- mostrar el catálogo desde Rails;
- conectar la selección de profesional y horario;
- persistir una primera reserva real;
- cubrir un caso exitoso y uno de error en el frontend.
