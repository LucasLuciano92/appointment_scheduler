# Etapa 2 — Modelos y base de datos

Esta etapa implementa los seis modelos definidos en
[la etapa 1](stage_1_definition.md), con sus migraciones, asociaciones de Active
Record, validaciones y pruebas. Los generadores de Rails ya fueron ejecutados:
no es necesario volver a generar los modelos.

## Preparar la base de datos

```bash
bundle install
bin/rails db:prepare
bin/rails db:migrate:status
```

`bcrypt` permite utilizar `has_secure_password`: se asigna `password` y se guarda
`password_digest`. No se guardan contraseñas en texto plano. Las cuentas nuevas
tienen `role: customer` y `active: true` por defecto. El mecanismo de acceso y
los permisos por usuario se implementarán en el back-office y la API.

## Decisiones de implementación

- `Appointment.customer_id` apunta a `users`, no a una tabla `customers`.
- Las claves foráneas protegen las relaciones. Los campos obligatorios tienen
  `null: false`; los enums y los indicadores `active` tienen restricciones de
  valores en la base de datos.
- Los emails se normalizan; el email opcional vacío de `StaffMember` se guarda
  como `nil`. Los índices sobre `lower(email_address)` y `lower(name)` impiden
  duplicados aunque se omitan las validaciones de Active Record.
- La pareja de personal y servicio tiene un índice único. Una oferta con
  historial no puede cambiar de personal ni de servicio.
- `Service.price` es decimal de precisión 10 y escala 2; su valor no puede ser
  negativo. La duración debe ser un entero positivo.
- `Availability.day_of_week` utiliza `sunday: 0` hasta `saturday: 6`, compatible
  con `Date#wday`. Se recomienda asignar nombres como `:monday` desde Ruby.
- `Availability.start_time` y `end_time` son horas locales semanales; no se
  convierten a UTC. `Appointment.starts_at` y `ends_at` son instantes almacenados
  en UTC y evaluados en la zona horaria del negocio.
- `BUSINESS_TIME_ZONE` tiene como valor inicial `America/Argentina/Buenos_Aires`;
  `BUSINESS_CURRENCY`, `ARS`. Definirlos antes de cargar datos. Cambiar la zona
  horaria después modifica la interpretación de las disponibilidades semanales.
- Al crear un turno o cambiar su inicio u oferta, se calcula `ends_at` desde la
  duración del servicio. Modificar notas o cancelar no recalcula esa duración.
- Crear o reprogramar exige un cliente activo, una oferta y catálogo activos,
  una fecha futura y el intervalo completo dentro de una sola franja activa.
- Las superposiciones se comprueban para todo el personal, incluso entre ofertas
  de servicios diferentes. Se permiten intervalos contiguos.
- Solo `scheduled` bloquea horarios. Se permite pasar a `cancelled` o a
  `completed`, este último solo una vez finalizado el horario. Los estados
  terminales no permiten reprogramar ni reabrir el turno.
- `destroy` no permite borrar turnos. Los clientes y ofertas con turnos tampoco
  pueden borrarse. Para eliminar un servicio o miembro del personal hay que
  eliminar primero sus ofertas sin historial; si hay historial, se desactivan.
  Eliminar personal sin ofertas elimina sus franjas semanales.

## Prueba desde rails console

Usar el modo sandbox para que los registros de este ejemplo se reviertan al salir:

```bash
bin/rails console --sandbox
```

Pegar en la consola:

```ruby
customer = User.create!(
  first_name: "Ana", last_name: "Perez",
  email_address: "demo-#{SecureRandom.hex(4)}@example.com",
  password: "example-password-123"
)
staff = StaffMember.create!(first_name: "Laura", last_name: "Gomez")
service = Service.create!(
  name: "Haircut #{SecureRandom.hex(4)}", duration_minutes: 30, price: 15000
)
offering = ServiceOffering.create!(staff_member: staff, service: service)
starts_at = Time.zone.tomorrow.in_time_zone.change(hour: 10)
availability = staff.availabilities.create!(
  day_of_week: starts_at.wday, start_time: "09:00", end_time: "18:00"
)
appointment = Appointment.create!(
  customer: customer, service_offering: offering, starts_at: starts_at
)

customer.authenticate("example-password-123") == customer # true
customer.appointments.pluck(:id, :status, :starts_at, :ends_at)
staff.services.pluck(:name)
appointment.ends_at == starts_at + 30.minutes # true

duplicate = Appointment.new(
  customer: customer, service_offering: offering, starts_at: starts_at
)
duplicate.valid? # false
duplicate.errors.full_messages # incluye la superposicion

appointment.update!(status: :cancelled)
duplicate.save! # ahora el horario esta libre
duplicate.destroy # false: se conserva el historial
```

Salir con `exit`. No se agregan datos de demostración ni administradores mediante
`db:seed` en esta etapa.

## Verificación y pendientes

```bash
bin/rails test
bin/rubocop
bin/rails zeitwerk:check
```

Las pruebas incluyen autenticación del modelo, unicidad, relaciones,
restricciones SQL, disponibilidades, superposiciones, reprogramación, duración
histórica, estados y protección del historial.

La validación de superposiciones de esta etapa consulta registros existentes.
La protección contra dos solicitudes concurrentes debe implementarse y probarse
antes de habilitar reservas desde el back-office o la API, según la regla 23
de la etapa 1. No se debe considerar esta validación una garantía de concurrencia.

Actualización de la etapa 3: el back-office utiliza `AppointmentBooking` para
guardar y reprogramar dentro de una transacción de escritura de SQLite. Se
agregaron pruebas con conexiones simultáneas; ver
[la documentación de la etapa 3](stage_3_back_office.md).

Los permisos específicos del actor (por ejemplo, un cliente solo puede cancelar
sus propios turnos futuros) pertenecen a las próximas etapas. Las operaciones
directas de base de datos como `delete`, `update_columns` o SQL omiten callbacks
y validaciones de modelo; los flujos de la aplicación deben usar las operaciones
validadas de Active Record.

Quedan para las siguientes etapas el back-office, la API, Active Storage, el
envío de emails y la ampliación de las pruebas a esos componentes.
