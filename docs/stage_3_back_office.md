# Etapa 3 — Back-office

Esta etapa agrega la administración web al dominio implementado en la etapa 2.
Se utilizan controllers, vistas ERB, layouts, formularios de Rails y asociaciones
de Active Record. Todas las rutas administrativas están bajo `/admin`.

## Preparación y acceso

```bash
bundle install
bin/rails db:prepare
bin/rails admin:create
bin/rails server
```

El generador de `AdminSession` y su migración ya están incluidos. No hay que
volver a ejecutarlo. `db:prepare` aplica las migraciones pendientes.

`admin:create` solicita nombre, apellido, email y contraseña desde una terminal;
la contraseña no aparece en pantalla. Crea una cuenta nueva con rol `admin` y
valida su email y contraseña. No promueve ni sobrescribe cuentas existentes.
No se incluye una contraseña predeterminada ni se crean administradores en seeds.

Para automatización, el mismo comando admite `ADMIN_FIRST_NAME`,
`ADMIN_LAST_NAME`, `ADMIN_EMAIL` y `ADMIN_PASSWORD` mediante variables de entorno.

Ingresar en `http://localhost:3000/admin`. La raíz `/` también redirige allí.
El email se normaliza y la contraseña se verifica con `has_secure_password`.

## Funcionalidades implementadas

| Sección | Operaciones |
| --- | --- |
| Resumen | Cantidad de turnos de hoy, próximas reservas, clientes y profesionales activos; próximos ocho turnos. |
| Servicios | Crear, listar, consultar, editar, activar, desactivar y eliminar cuando no tenga ofertas. |
| Personal | Crear, listar, consultar, editar, activar, desactivar y eliminar cuando no tenga ofertas. |
| Ofertas | Asociar un servicio a un profesional; consultar, editar, activar, desactivar y eliminar sin historial. |
| Disponibilidad | Administrar franjas semanales con control de horarios y superposiciones. |
| Clientes | Crear, listar, consultar, editar, cambiar contraseña, activar, desactivar y eliminar sin turnos. |
| Turnos | Reservar para un cliente, listar, consultar, reprogramar, editar notas, cancelar y completar. |

Las listas tienen páginas de 25 registros. Los turnos se pueden filtrar por fecha
local del salón, estado y profesional. Se muestran estados vacíos cuando no hay
datos, errores junto a los formularios y avisos después de cada operación.

Para cargar el negocio por primera vez:

1. Crear los servicios y miembros del personal.
2. Crear las ofertas que asignan servicios a profesionales.
3. Configurar las disponibilidades semanales de cada profesional.
4. Crear un cliente y reservar su turno.

Las reservas requieren cliente, oferta, servicio y profesional activos. Un turno
debe quedar completamente dentro de una única franja semanal activa.

El administrador puede cancelar turnos confirmados y reprogramarlos a una fecha
futura válida. Solo puede marcar como completado un turno cuyo horario terminó.
Los estados terminales conservan sus datos de reserva y permiten editar notas.
El borrado físico de turnos no tiene ruta administrativa.

Las ofertas con turnos no permiten cambiar de profesional o servicio. Para
eliminar personal o servicios se retiran primero las ofertas sin historial; si
existe historial, se desactivan los registros. Los errores explican por qué no
se pudo completar la operación.

## Sesiones y autorización

- `AdminSession` guarda el usuario y el vencimiento en la base de datos. Es un
  modelo de infraestructura; el dominio principal sigue teniendo seis modelos.
- El identificador de la sesión se guarda en la cookie cifrada de Rails, con
  `HttpOnly`, `SameSite=Lax` y vencimiento de 12 horas. En producción se utiliza
  `Secure` y Rails exige HTTPS; `/up` queda disponible para el health check.
- Cada petición comprueba que la sesión no haya vencido y que el usuario siga
  activo y tenga rol `admin`.
- Cerrar sesión elimina el registro del servidor y reinicia la sesión del
  navegador. Cambiar la contraseña, desactivar la cuenta o retirar el rol de
  administrador revoca sus sesiones.
- Se limita el login a diez intentos por IP en tres minutos mediante el cache
  de Rails: memoria en desarrollo y Solid Cache en producción. En producción
  hay que preparar también las bases de datos de Rails con `db:prepare`.
- Las operaciones mantienen la protección CSRF de Rails. Las páginas
  administrativas utilizan `Cache-Control: no-store`.
- Los parámetros permitidos son explícitos. Los formularios de clientes no
  aceptan `role`, y las rutas de clientes solo consultan `User.customer`, por lo
  que no permiten modificar cuentas administradoras.
- La reserva no acepta `status` ni `ends_at` desde el formulario. La duración se
  calcula en el modelo y las transiciones usan acciones separadas.

No se incorpora registro público ni recuperación de contraseña por email en
esta etapa. La API y Action Mailer se implementarán más adelante.

## Reservas concurrentes

`AppointmentBooking.save` agrupa la asignación, las validaciones y el guardado
en una transacción. Al actualizar, recarga y bloquea el registro antes de aplicar
los cambios; también desactiva la caché de consultas para esta operación.

El adaptador SQLite de Rails 8.1 utiliza `BEGIN IMMEDIATE` para las transacciones
de escritura. Dos operaciones concurrentes se serializan: la segunda valida
contra el resultado confirmado de la primera. Si el tiempo de espera de SQLite
se agota, se devuelve un error para que el usuario vuelva a intentar.

Las pruebas usan dos hilos con conexiones independientes y datos confirmados
fuera de las transacciones automáticas de tests. Comprueban que al crear reservas
para el mismo profesional, incluso con servicios diferentes, o al reprogramar
dos turnos al mismo horario, exactamente uno se guarda y el otro recibe el error
de superposición.

Esta solución depende del adaptador SQLite actual. Un cambio a PostgreSQL u otro
motor requiere revisar el mecanismo de bloqueo. Los futuros endpoints de reserva
deben utilizar este mismo servicio; no deben omitir las validaciones.

## Rutas principales

| Método y ruta | Uso |
| --- | --- |
| `GET /admin` | Resumen autenticado. |
| `GET /admin/session/new` | Formulario de acceso. |
| `POST /admin/session` | Iniciar sesión. |
| `DELETE /admin/session` | Cerrar sesión. |
| CRUD `/admin/services` | Servicios. |
| CRUD `/admin/staff_members` | Personal. |
| CRUD `/admin/service_offerings` | Ofertas. |
| CRUD `/admin/availabilities` | Franjas semanales. |
| CRUD `/admin/customers` | Clientes. |
| `GET/POST /admin/appointments` | Listar o reservar turnos. |
| `GET/PATCH /admin/appointments/:id` | Consultar o actualizar un turno. |
| `PATCH /admin/appointments/:id/cancel` | Cancelar. |
| `PATCH /admin/appointments/:id/complete` | Marcar completado. |

Las rutas CRUD incluyen los formularios `new` y `edit`. El listado completo se
puede consultar con `bin/rails routes -g admin`.

## Verificación

```bash
bin/rails test
bin/rubocop
bin/rails zeitwerk:check
bin/brakeman --no-pager
```

Se verifican las páginas y los formularios mediante pruebas de integración HTTP,
incluyendo los seis recursos, los errores de validación, los permisos, el
vencimiento de sesiones, CSRF, parámetros no permitidos, filtros y paginación.
Estas pruebas se suman a las de modelos y concurrencia. No se realizó una prueba
visual en un navegador real en este entorno.

La interfaz está en español, con navegación adaptable, etiquetas en los campos,
avisos accesibles y confirmación antes de eliminar registros o cancelar turnos.

Quedan para las próximas etapas la API JSON, las imágenes de servicios con
Active Storage, Action Mailer y las pruebas específicas de esas funcionalidades.
