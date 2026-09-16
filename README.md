# Appointment Scheduler

Backend en Ruby on Rails para gestionar turnos de un salón o centro de estética
de una sola sede.

## Estado

Implementadas: definición del dominio (etapa 1), modelos y base de datos
(etapa 2) y back-office (etapa 3). La API, Active Storage y Action Mailer quedan
para las próximas etapas. No hay un deploy publicado.

## Instalación y acceso

Requisitos: Ruby 3.4.10, Bundler y herramientas de compilación para las gems
nativas. La aplicación usa Rails 8.1.3.1 y SQLite, sin servidor de base de datos
adicional.

```bash
git clone https://github.com/LucasLuciano92/appointment_scheduler.git
cd appointment_scheduler
bundle install
bin/rails db:prepare
bin/rails admin:create
bin/rails server
```

Abrir **http://localhost:3000/admin**. El comando `admin:create` solicita nombre,
apellido, email y contraseña; esta última no se muestra al escribirla. No hay
credenciales predeterminadas ni datos de demostración en seeds. Para automatizar
la creación admite `ADMIN_FIRST_NAME`, `ADMIN_LAST_NAME`, `ADMIN_EMAIL` y
`ADMIN_PASSWORD` como variables de entorno.

`db:prepare` crea la base o aplica las migraciones pendientes. Volver a ejecutarlo
si una actualización incluye migraciones. `/up` es el endpoint de salud;
`bin/rails console` permite consultar los modelos.

## Configuración

| Variable | Valor predeterminado |
| --- | --- |
| `BUSINESS_TIME_ZONE` | `America/Argentina/Buenos_Aires` |
| `BUSINESS_CURRENCY` | `ARS` |

Configurar estos valores antes de cargar disponibilidades. Cambiar la zona
horaria modifica la interpretación de las franjas semanales. En producción se
exige HTTPS; el despliegue necesita su propia configuración de secretos y bases
de datos.

## Modelo de datos y uso

`User` representa clientes y administradores. `StaffMember` y `Service` se
relacionan mediante `ServiceOffering`. `Availability` define las franjas
semanales del personal y `Appointment` reserva una oferta para un cliente.
`AdminSession` gestiona las sesiones administrativas.

El back-office administra esas entidades y permite reservar, reprogramar,
cancelar y completar turnos. Para comenzar: cargar servicios y personal,
asignar ofertas, definir disponibilidades y crear clientes.

La futura API utilizará `/api/v1`; todavía no hay endpoints públicos de negocio.

## Verificación

```bash
bundle exec rspec --exclude-pattern 'spec/system/**/*_spec.rb'
bundle exec rspec spec/system
bin/rubocop
bin/rails zeitwerk:check
bin/brakeman --no-pager
```

Las pruebas de sistema requieren Chrome y sus bibliotecas del sistema.
Selenium Manager obtiene el driver; puede necesitar conexión la primera vez.
Si Chrome no está en una ubicación habitual, indicar su ejecutable con
`CHROME_BIN`.

La suite usa RSpec y cubre modelos, restricciones SQL, permisos, sesiones,
filtros, reservas concurrentes y flujos de navegador. GitHub Actions ejecuta
los specs, RuboCop y análisis de seguridad en los PR. `bin/ci` reúne las
verificaciones locales, incluyendo auditorías de dependencias que requieren
conexión.

## Documentación

- [Requisitos del TP](docs/tp1_requirements.md): resumen del enunciado.
- [Etapa 1](docs/stage_1_definition.md): dominio, alcance, reglas y diagrama.
- [Etapa 2](docs/stage_2_models.md): decisiones de datos y ejemplo de consola.
- [Etapa 3](docs/stage_3_back_office.md): operaciones, sesiones y concurrencia.

Los comentarios del código explican decisiones que no son evidentes. Los cambios
se registran en commits y cada etapa cierra con un PR.
