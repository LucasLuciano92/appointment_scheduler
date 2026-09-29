# Appointment Scheduler

Backend en Ruby on Rails para gestionar turnos de un salón o centro de estética
de una sola sede.

## Estado

Implementadas: definición del dominio (etapa 1), modelos y base de datos
(etapa 2), back-office (etapa 3), API JSON (etapa 4), imágenes de servicios con
Active Storage y confirmaciones por email con Action Mailer (etapa 5). No hay un
deploy publicado.

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
| `API_ALLOWED_ORIGINS` | `http://localhost:5173` fuera de producción; vacío en producción |
| `MAILER_FROM` | `turnos@example.com` |
| `APP_HOST` | `example.com` en producción |

Configurar estos valores antes de cargar disponibilidades. Cambiar la zona
horaria modifica la interpretación de las franjas semanales. En producción se
exige HTTPS; el despliegue necesita su propia configuración de secretos y bases
de datos. `API_ALLOWED_ORIGINS` acepta una lista de orígenes separados por comas;
en producción debe declarar explícitamente la URL del frontend.

## Modelo de datos y uso

`User` representa clientes y administradores. `StaffMember` y `Service` se
relacionan mediante `ServiceOffering`. `Availability` define las franjas
semanales del personal y `Appointment` reserva una oferta para un cliente.
`AdminSession` gestiona las sesiones administrativas.

El back-office administra esas entidades y permite reservar, reprogramar,
cancelar y completar turnos. Para comenzar: cargar servicios y personal,
asignar ofertas, definir disponibilidades y crear clientes.

## API JSON

La API vive bajo `/api/v1`. Registro e inicio de sesión devuelven un token que
debe enviarse en las operaciones protegidas:

```http
Authorization: Bearer TOKEN
Content-Type: application/json
```

Los tokens duran 30 días, se guardan como hashes y se invalidan al cerrar sesión,
cambiar la contraseña, desactivar la cuenta o cambiar su rol. No hay registro
público de administradores.

Los servicios pueden tener una imagen JPEG, PNG o WebP de hasta 5 MB. La API
expone su URL en `image_url`. Cada reserva nueva encola un correo de confirmación
para el cliente; la configuración SMTP de producción se describe en la
[documentación de la etapa 5](docs/stage_5_storage_mailer.md).

| Método y ruta | Acceso | Uso |
| --- | --- | --- |
| `POST /api/v1/registration` | Público | Registrar un customer y obtener un token |
| `POST /api/v1/session` | Público | Iniciar sesión |
| `DELETE /api/v1/session` | Token | Cerrar la sesión actual |
| `GET/PATCH /api/v1/profile` | Token | Consultar o editar el perfil propio |
| `GET /api/v1/services` | Público | Listar servicios activos |
| `GET /api/v1/services/:id` | Público | Consultar un servicio activo |
| `GET /api/v1/services/:service_id/staff_members` | Público | Listar profesionales y ofertas activas |
| `GET /api/v1/service_offerings/:id/available_slots?date=YYYY-MM-DD` | Público | Consultar horarios libres |
| `GET/POST /api/v1/appointments` | Token | Listar turnos propios por páginas o reservar |
| `GET /api/v1/appointments/:id` | Token | Consultar un turno propio |
| `PATCH /api/v1/appointments/:id/cancel` | Token | Cancelar un turno propio futuro |

Los cuerpos de escritura agrupan atributos bajo `user`, `session` o
`appointment`. Las respuestas exitosas usan `data`; los errores usan `error`
con `code`, `message` y, para validaciones, `details`. El contrato completo y
ejemplos están en [la documentación de la etapa 4](docs/stage_4_api.md).

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
- [Etapa 4](docs/stage_4_api.md): contrato JSON, autenticación y permisos.
- [Etapa 5](docs/stage_5_storage_mailer.md): imágenes, emails y pruebas.

Los comentarios del código explican decisiones que no son evidentes. Los cambios
se registran en commits y cada etapa cierra con un PR.
