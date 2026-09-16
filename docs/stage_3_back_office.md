# Etapa 3 — Back-office

Administración bajo `/admin`, con controllers, vistas ERB y formularios de Rails.
La instalación, creación del administrador y ejecución de pruebas están en el
[README](../README.md).

## Operaciones

| Sección | Funcionalidad |
| --- | --- |
| Resumen | Indicadores del negocio y próximos ocho turnos. |
| Servicios y personal | Crear, consultar, editar, activar, desactivar y eliminar sin ofertas. |
| Ofertas | Asignar servicios a profesionales; editar, activar, desactivar y eliminar sin historial. |
| Disponibilidad | Administrar franjas semanales y validar superposiciones. |
| Clientes | Gestionar datos, contraseña y activación; eliminar sin turnos. |
| Turnos | Reservar, consultar, reprogramar, editar notas, cancelar y completar. |

Las listas muestran 25 registros por página. La agenda se filtra por fecha
local, estado y profesional. `AppointmentFilter` valida los filtros: las entradas
inválidas muestran un aviso; una página inválida vuelve a la primera.
`with_booking_details` precarga las relaciones utilizadas en los listados.

Las transiciones siguen las [reglas de la etapa 1](stage_1_definition.md).
Los turnos terminales solo permiten editar notas. No hay una ruta para borrarlos.

## Sesiones y permisos

- `AdminSession` guarda el usuario y un vencimiento de 12 horas. Su identificador
  viaja en la cookie cifrada de Rails con `HttpOnly`, `SameSite=Lax` y `Secure`
  en producción.
- Cada petición exige una sesión vigente y un usuario activo con rol `admin`.
  Cerrar sesión, cambiar la contraseña, desactivar la cuenta o retirar el rol
  administrativo revoca las sesiones correspondientes.
- El login limita los intentos a diez por IP cada tres minutos mediante el cache
  de Rails: memoria en desarrollo y Solid Cache en producción.
- Se mantiene la protección CSRF y las páginas usan `Cache-Control: no-store`.
- Los parámetros permitidos son explícitos. Las rutas de clientes solo acceden
  a `User.customer` y no admiten cambiar `role`.
- La reserva no acepta `status` ni `ends_at` desde el formulario. Las
  transiciones de estado tienen acciones separadas.
- `admin:create` crea cuentas nuevas y no promueve ni sobrescribe usuarios.
  No hay registro público ni recuperación por email en esta etapa.

## Concurrencia

`AppointmentBooking.save` asigna, valida y guarda dentro de una transacción,
sin cache de consultas. Al actualizar recarga el registro antes de aplicar los
cambios.

El adaptador SQLite de Rails 8.1 usa `BEGIN IMMEDIATE`: las escrituras se
serializan y la segunda reserva valida contra el resultado confirmado de la
primera. Si se agota la espera de SQLite, se informa que debe reintentarse.

Las pruebas usan conexiones independientes con datos confirmados y un tiempo
límite para detectar bloqueos. Comprueban creación y reprogramación simultáneas:
un intento se guarda y el otro recibe un error de superposición.

Esta garantía depende del adaptador SQLite actual. Cambiar el motor requiere
revisar el bloqueo. La futura API debe usar el mismo servicio de reserva.

## Rutas

| Método y ruta | Uso |
| --- | --- |
| `GET /admin` | Resumen. |
| `GET /admin/session/new` | Formulario de acceso. |
| `POST /admin/session` | Iniciar sesión. |
| `DELETE /admin/session` | Cerrar sesión. |
| CRUD `/admin/services`, `/admin/staff_members`, `/admin/service_offerings`, `/admin/availabilities`, `/admin/customers` | Catálogo y clientes. |
| `GET/POST /admin/appointments` | Listar o reservar. |
| `GET/PATCH /admin/appointments/:id` | Consultar o actualizar. |
| `PATCH /admin/appointments/:id/cancel` | Cancelar. |
| `PATCH /admin/appointments/:id/complete` | Completar. |

Las rutas incluyen los formularios `new` y `edit`.
`bin/rails routes -g admin` muestra el detalle completo.

## Pruebas y pendientes

Las pruebas HTTP cubren permisos, sesiones, CSRF, parámetros, filtros,
paginación y errores. Las pruebas de sistema usan Chrome para recorrer alta,
edición y borrado de servicios, reserva y cancelación de turnos, navegación móvil
y cierre de sesión.

Quedan para las próximas etapas la API, Active Storage y Action Mailer.
