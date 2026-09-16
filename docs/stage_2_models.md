# Etapa 2 — Modelos y base de datos

Implementa los seis modelos de [la definición del dominio](stage_1_definition.md).
La instalación y los comandos de verificación están en el [README](../README.md).

## Decisiones de datos

- `Appointment.customer_id` referencia `users`. El rol `customer` y los
  indicadores `active: true` son los valores iniciales.
- Las relaciones tienen claves foráneas y los campos obligatorios,
  `null: false`. Los enums, booleanos, precios y orden de horarios tienen
  restricciones SQL además de las validaciones de Active Record.
- `has_secure_password` usa bcrypt: se asigna `password` y se almacena
  `password_digest`.
- Los emails se normalizan; el email opcional vacío del profesional se guarda
  como `nil`. Los índices sobre `lower(email_address)` y `lower(name)`
  impiden duplicados sin distinguir mayúsculas.
- La pareja de profesional y servicio es única. Una oferta con turnos no puede
  cambiar esa asignación.
- `price` usa decimal de precisión 10 y escala 2. `duration_minutes` exige
  un entero positivo.
- `Availability.day_of_week` coincide con `Date#wday`: domingo es 0 y sábado,
  6. Desde Ruby se pueden usar nombres como `:monday`.
- Las franjas semanales son horas locales, sin conversión a UTC. Los instantes
  de los turnos se guardan en UTC y se evalúan en la zona del negocio.
- `ends_at` se calcula al crear el turno o cambiar su inicio u oferta. Editar
  notas o cancelar conserva la duración original aunque el servicio haya cambiado.
- Los turnos no se borran mediante `destroy`. Los registros con historial se
  desactivan. Para borrar un servicio o profesional hay que retirar primero sus
  ofertas sin historial; borrar personal sin ofertas elimina sus disponibilidades.

Las reglas de reserva están en la etapa 1. Las validaciones se complementan con
[la transacción de reserva de la etapa 3](stage_3_back_office.md#concurrencia).

## Ejemplo de consola

Ejecutar `bin/rails console --sandbox` y pegar:

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
staff.availabilities.create!(
  day_of_week: starts_at.wday, start_time: "09:00", end_time: "18:00"
)
appointment = Appointment.create!(
  customer: customer, service_offering: offering, starts_at: starts_at
)
customer.appointments.pluck(:id, :status, :starts_at, :ends_at)
appointment.ends_at == starts_at + 30.minutes # true
```

Salir con `exit` revierte estos datos. El ejemplo muestra las asociaciones;
los flujos del back-office utilizan `AppointmentBooking`. Operaciones como
`delete`, `update_columns` o SQL directo omiten callbacks y validaciones de
modelo y no deben utilizarse para esos flujos.
