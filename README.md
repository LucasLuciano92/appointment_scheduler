# Appointment Scheduler

Backend desarrollado en Ruby on Rails para la gestión de turnos de un salón o centro de estética.

## Estado del proyecto

Etapas implementadas:

- Etapa 1: definición del dominio.
- Etapa 2: modelos, base de datos, asociaciones y validaciones.
- Etapa 3: back-office autenticado y gestión administrativa.

## Tecnologías

- Ruby 3.4.10
- Ruby on Rails 8.1.3.1
- SQLite
- Git

## Dominio

Modelos principales definidos:

- User
- StaffMember
- Service
- ServiceOffering
- Availability
- Appointment

La documentación detallada de la Etapa 1 se encuentra en:

`docs/stage_1_definition.md`

## Instalación

Con Ruby 3.4.10 y Bundler instalados, desde la carpeta del proyecto:

```bash
bundle install
bin/rails db:prepare
bin/rails server
```

La aplicación utiliza SQLite, sin un servidor de base de datos adicional. La
página inicial dirige al back-office en `/admin`; `/up` permite comprobar que
Rails está funcionando. Para trabajar con los modelos: `bin/rails console`.

La zona horaria predeterminada es `America/Argentina/Buenos_Aires` y la moneda es
`ARS`. Se pueden configurar con `BUSINESS_TIME_ZONE` y `BUSINESS_CURRENCY` al
iniciar Rails. Los horarios semanales se interpretan en la zona del negocio.

La [guía de la etapa 2](docs/stage_2_models.md) explica las decisiones de datos y
contiene un ejemplo completo para probar desde la consola.

## Testing

```bash
bin/rails test
bin/rubocop
bin/rails zeitwerk:check
bin/brakeman --no-pager
```

Hay pruebas para los seis modelos, las restricciones de base de datos y las
reglas de disponibilidad, superposición, duración y conservación del historial.
También se verifican los formularios y permisos del back-office, las sesiones,
CSRF y las reservas concurrentes usando conexiones independientes a SQLite.

## API

La API será versionada bajo:

`/api/v1`

Los endpoints serán documentados cuando se implemente la Etapa 4.

## Back-office

El back-office administrativo está disponible en `/admin`. Para crear tu primera
cuenta, ejecutá desde una terminal:

```bash
bin/rails admin:create
```

El comando solicita nombre, apellido, email y contraseña; la contraseña no se
muestra al escribirla. No hay credenciales predeterminadas. Luego iniciá Rails
con `bin/rails server` y abrí `http://localhost:3000/admin`.

Permite administrar servicios, personal, ofertas, disponibilidades, clientes y
turnos. La sesión vence después de 12 horas. En producción se exige HTTPS.

La [guía de la etapa 3](docs/stage_3_back_office.md) detalla los flujos, rutas,
controles de acceso y verificaciones realizadas.
