# TP2 - Etapa 1: revisión y definición del alcance

## Decisiones de partida

- **Proyecto base:** Appointment Scheduler, continuación del backend Rails del
  TP1 alojado en `LucasLuciano92/appointment_scheduler`.
- **Backend:** este repositorio, Ruby on Rails 8.1 y API JSON bajo `/api/v1`.
- **Frontend:** aplicación independiente en Angular y TypeScript, en un
  repositorio separado llamado provisionalmente `appointment_scheduler_frontend`.
- **Arquitectura del frontend:** componentes standalone, Angular Router,
  `HttpClient`, interceptor de autenticación y Reactive Forms.
- **Integración local:** frontend en `http://localhost:4200` y backend en
  `http://localhost:3000`. El origen de Angular deberá agregarse a
  `API_ALLOWED_ORIGINS`.
- **Modalidad e integrantes:** pendientes de confirmar. Se mantendrá un contrato
  completo de API aunque la modalidad individual no lo exija.

## Estado recibido del TP1

El repositorio contiene las siete etapas entregadas del TP1: definición del
dominio, persistencia, back-office, API JSON, archivos y correo, controles de
calidad y seguridad, y preparación de deploy.

El back-office Rails continuará funcionando como contexto administrativo. El
frontend Angular será un contexto separado para clientes y consumirá la API
existente.

La API ya ofrece:

| Área | Operaciones disponibles | Acceso |
| --- | --- | --- |
| Cuenta | registro, login, logout, consulta y edición del perfil | mixto |
| Catálogo | listado y detalle de servicios activos | público |
| Profesionales | profesionales y ofertas activas por servicio | público |
| Disponibilidad | horarios libres por oferta y fecha | público |
| Turnos | crear, listar, consultar y cancelar turnos propios | token Bearer |

La autenticación usa tokens opacos con vencimiento a 30 días. En la base se
persiste únicamente su hash. La API tiene respuestas de error estructuradas,
paginación del historial, límites de intentos para registro y login, aislamiento
entre clientes y CORS configurable.

## Alcance funcional acordado

El producto del TP2 permitirá a un cliente completar estos recorridos desde el
frontend Angular:

1. Registrarse, iniciar sesión, mantener la sesión y cerrarla.
2. Explorar el catálogo de servicios con imagen, duración y precio.
3. Elegir servicio, profesional, fecha y horario disponible.
4. Confirmar una reserva y visualizar el resultado persistido por Rails.
5. Consultar el historial propio, filtrar por estado y avanzar por páginas.
6. Ver el detalle de un turno futuro y cancelarlo.
7. Consultar y editar el perfil.

Cada pantalla deberá mostrar estados de carga, vacío, error y confirmación.
Los formularios tendrán validación local y mostrarán los errores de Rails. Las
acciones de escritura deshabilitarán envíos repetidos y permitirán reintentar
cuando corresponda. La navegación y los controles deberán ser utilizables con
teclado y adaptarse a computadora y pantallas pequeñas.

## Pantallas previstas

| Ruta propuesta | Pantalla | Protección |
| --- | --- | --- |
| `/servicios` | catálogo público | pública |
| `/servicios/:id/reservar` | selección de profesional, fecha y horario | login al confirmar |
| `/registro` | alta de cliente | sólo visitante |
| `/login` | inicio de sesión | sólo visitante |
| `/turnos` | historial paginado y filtrable | autenticada |
| `/turnos/:id` | detalle y cancelación | autenticada |
| `/perfil` | consulta y edición de datos | autenticada |

Las rutas protegidas conservarán la URL solicitada para continuar el flujo
después del login. Un `401` de la API cerrará la sesión local y llevará al login.

## Contrato inicial de integración

- URL local base: `http://localhost:3000/api/v1`.
- Formato: JSON y encabezado `Content-Type: application/json` en escrituras.
- Credencial: `Authorization: Bearer <token>` en operaciones protegidas.
- Éxitos: recursos y colecciones dentro de `data`; listados paginados incluyen
  `meta`.
- Errores: objeto `error` con `code`, `message` y `details` cuando existen
  errores por campo.
- Fechas de disponibilidad: `YYYY-MM-DD`.
- Instantes de turnos: ISO 8601 con zona horaria.

El contrato detallado se completará endpoint por endpoint en la Etapa 2, con
tipos, obligatoriedad, permisos, códigos HTTP y ejemplos reproducibles.

## Brechas y riesgos detectados

1. `docs/stage_4_api.md` describe el comportamiento general, pero no contiene
   todavía todos los campos, tipos, validaciones y ejemplos de error que exige
   el TP2.
2. CORS usa por defecto el origen de Vite (`http://localhost:5173`); para Angular
   se debe documentar y probar `http://localhost:4200`.
3. `db/seeds.rb` no prepara datos ni credenciales de demostración. La entrega
   necesita un mecanismo reproducible sin secretos reales.
4. Falta el repositorio independiente del frontend, su CI y sus pruebas.
5. La modalidad, los integrantes y el autor formal del backend deben confirmarse
   antes del checkpoint.
6. La persistencia del token en el navegador y la política ante recarga o
   expiración deben definirse explícitamente antes de implementar autenticación.

## Verificación del estado inicial

Ejecutada el 28 de octubre de 2026 sobre `origin/main` (`80c0e16`):

- `bundle exec rspec spec/requests/api_v1_spec.rb`: 19 ejemplos, 0 fallos.
- `bundle exec brakeman --no-pager --exit-on-warn --exit-on-error`: 0 alertas.
- `bin/rails zeitwerk:check`: correcto.
- El PR #13 del TP1 pasó `test`, `system-test`, `lint`, escaneos de Ruby y
  JavaScript, y construcción de la imagen de producción.

## Plan por etapas

### Etapa 2 - Plan técnico y contrato

- completar el contrato de todos los endpoints consumidos;
- definir modelos TypeScript y mapa de errores;
- definir navegación, estado de sesión y almacenamiento del token;
- preparar datos de demostración y CORS para Angular;
- crear el repositorio del frontend y su estructura inicial.

### Etapa 3 - Primera integración y checkpoint

- implementar layout, navegación, registro y login;
- integrar token, interceptor, guardas y manejo global de `401`;
- conectar catálogo y un primer flujo de reserva contra Rails real;
- agregar pruebas automatizadas de éxito y error.

### Etapa 4 - Integración completa y entrega

- completar reserva, historial, cancelación y perfil;
- revisar accesibilidad y adaptación responsive;
- ejecutar pruebas, compilación, RuboCop, Brakeman y CI;
- actualizar contrato, README e instrucciones de demostración.

Cada etapa se desarrollará en una rama y cerrará con commits y un pull request.
Los PR no se fusionarán sin indicación expresa.
