# TP2 - Contrato de la API v1

Este documento es el contrato entre el backend Rails de Appointment Scheduler y
el frontend Angular. Describe únicamente operaciones disponibles en
`/api/v1`.

## Configuración general

| Concepto | Valor |
| --- | --- |
| URL local | `http://localhost:3000/api/v1` |
| Formato | JSON UTF-8 |
| Escrituras | `Content-Type: application/json` |
| Autenticación | `Authorization: Bearer <token>` |
| Fecha civil | `YYYY-MM-DD` |
| Instante | ISO 8601 con zona horaria, por ejemplo `2030-01-08T10:00:00-03:00` |

Registro y login entregan un token opaco. El backend conserva solamente su hash
y lo acepta durante 30 días, mientras el cliente siga activo. Logout revoca el
token actual. Un cambio de contraseña, rol o estado de acceso revoca todas las
sesiones API de la cuenta.

Las rutas protegidas devuelven `401` si falta el encabezado, el esquema no es
`Bearer`, el token venció o la cuenta perdió acceso. El frontend conservará el
token en `sessionStorage`: sobrevive una recarga en la misma pestaña y se elimina
al cerrar la pestaña o cerrar sesión. Ante cualquier `401` deberá borrar la
sesión local y redirigir al login.

## Formatos compartidos

### Usuario

| Campo | Tipo | Opcional | Descripción |
| --- | --- | --- | --- |
| `id` | integer | no | identificador |
| `first_name` | string | no | nombre |
| `last_name` | string | no | apellido |
| `email_address` | string | no | email normalizado en minúsculas |
| `phone` | string | sí | teléfono libre o `null` |

### Servicio

| Campo | Tipo | Opcional | Descripción |
| --- | --- | --- | --- |
| `id` | integer | no | identificador |
| `name` | string | no | nombre único |
| `description` | string | sí | descripción o `null` |
| `duration_minutes` | integer | no | duración positiva |
| `price` | string decimal | no | precio, por ejemplo `"15000.0"` |
| `image_url` | string URL | sí | URL absoluta o `null` |

### Profesional

| Campo | Tipo | Opcional | Descripción |
| --- | --- | --- | --- |
| `id` | integer | no | identificador |
| `first_name` | string | no | nombre |
| `last_name` | string | no | apellido |
| `service_offering_id` | integer | según respuesta | oferta requerida para horarios y reserva |

### Turno

| Campo | Tipo | Opcional | Descripción |
| --- | --- | --- | --- |
| `id` | integer | no | identificador |
| `starts_at` | string ISO 8601 | no | inicio |
| `ends_at` | string ISO 8601 | no | fin calculado por el backend |
| `status` | enum string | no | `scheduled`, `cancelled` o `completed` |
| `notes` | string | sí | notas o `null` |
| `service` | Servicio | no | servicio asociado |
| `staff_member` | Profesional | no | profesional, sin `service_offering_id` |
| `created_at` | string ISO 8601 | no | creación |
| `updated_at` | string ISO 8601 | no | última modificación |

### Errores

Todos los errores usan esta forma:

```json
{
  "error": {
    "code": "validation_failed",
    "message": "No se pudo guardar el recurso.",
    "details": {
      "starts_at": ["debe estar en el futuro"]
    }
  }
}
```

`details` es opcional. Sus claves son campos o `base`; sus valores son listas de
mensajes localizados. Códigos comunes:

| HTTP | `code` | Cuándo ocurre |
| --- | --- | --- |
| 400 | `bad_request` | falta el objeto raíz requerido |
| 400 | `invalid_date`, `invalid_page`, `invalid_status` | consulta inválida |
| 401 | `unauthorized`, `invalid_credentials` | sesión inválida o login rechazado |
| 404 | `not_found` | recurso inexistente, inactivo o perteneciente a otro cliente |
| 422 | `validation_failed`, `not_cancellable` | validación o regla de negocio |
| 429 | `rate_limited` | demasiados registros o logins |

Las respuestas incluyen `Cache-Control: no-store`.

## Cuenta y sesión

### Registrar cliente

`POST /registration` — público. Máximo cinco intentos por minuto.

Entrada bajo `user`:

| Campo | Tipo | Obligatorio | Validación |
| --- | --- | --- | --- |
| `first_name` | string | sí | no vacío |
| `last_name` | string | sí | no vacío |
| `email_address` | string | sí | email válido y único |
| `phone` | string | no | sin validación de formato en v1 |
| `password` | string | sí | mínimo 8 caracteres |
| `password_confirmation` | string | no | si se envía, debe coincidir |

No se aceptan `role` ni `active`; toda cuenta creada es un cliente activo.

```http
POST /api/v1/registration
Content-Type: application/json

{"user":{"first_name":"Ana","last_name":"Pérez","email_address":"ana@example.com","phone":"1112345678","password":"password123","password_confirmation":"password123"}}
```

Respuesta `201`:

```json
{
  "data": {"id": 12, "first_name": "Ana", "last_name": "Pérez", "email_address": "ana@example.com", "phone": "1112345678"},
  "token": "TOKEN_OPACO"
}
```

Errores: `400 bad_request`, `422 validation_failed`, `429 rate_limited`.

### Iniciar sesión

`POST /session` — público. Máximo diez intentos cada tres minutos.

Entrada bajo `session`: `email_address` y `password`, ambos string obligatorios.
Sólo una cuenta customer activa puede iniciar sesión.

```http
POST /api/v1/session
Content-Type: application/json

{"session":{"email_address":"ana@example.com","password":"password123"}}
```

Respuesta `201`:

```json
{
  "data": {"id": 12, "first_name": "Ana", "last_name": "Pérez", "email_address": "ana@example.com", "phone": "1112345678"},
  "token": "TOKEN_OPACO"
}
```

Errores: `400 bad_request`, `401 invalid_credentials`, `429 rate_limited`.

### Cerrar sesión

`DELETE /session` — token requerido. Revoca solamente el token enviado.

```http
DELETE /api/v1/session
Authorization: Bearer TOKEN_OPACO
```

Respuesta `204`, sin cuerpo. Error: `401 unauthorized`.

### Consultar perfil

`GET /profile` — token requerido.

```http
GET /api/v1/profile
Authorization: Bearer TOKEN_OPACO
```

Respuesta `200`:

```json
{"data":{"id":12,"first_name":"Ana","last_name":"Pérez","email_address":"ana@example.com","phone":"1112345678"}}
```

Error: `401 unauthorized`.

### Editar perfil

`PATCH /profile` — token requerido. Entrada parcial bajo `user`.

Campos admitidos: `first_name`, `last_name`, `email_address`, `phone`,
`password` y `password_confirmation`, con las mismas reglas del registro. No se
aceptan `role` ni `active`. Cambiar la contraseña revoca todas las sesiones; el
frontend debe pedir login nuevamente después de recibir la respuesta.

```http
PATCH /api/v1/profile
Authorization: Bearer TOKEN_OPACO
Content-Type: application/json

{"user":{"first_name":"Anita","phone":"1198765432"}}
```

Respuesta `200`:

```json
{"data":{"id":12,"first_name":"Anita","last_name":"Pérez","email_address":"ana@example.com","phone":"1198765432"}}
```

Errores: `400 bad_request`, `401 unauthorized`, `422 validation_failed`.

## Catálogo y disponibilidad

### Listar servicios

`GET /services` — público. Devuelve únicamente servicios activos, ordenados por
nombre e id.

```http
GET /api/v1/services
```

Respuesta `200`:

```json
{"data":[{"id":3,"name":"Corte","description":"Corte y peinado","duration_minutes":30,"price":"15000.0","image_url":null}]}
```

Una colección sin resultados devuelve `{"data":[]}`.

### Consultar servicio

`GET /services/:id` — público. `id` es un integer de ruta. Un servicio inactivo
se trata como inexistente.

```http
GET /api/v1/services/3
```

Respuesta `200`:

```json
{"data":{"id":3,"name":"Corte","description":"Corte y peinado","duration_minutes":30,"price":"15000.0","image_url":null}}
```

Error: `404 not_found`.

### Listar profesionales por servicio

`GET /services/:service_id/staff_members` — público. `service_id` es un integer
de ruta. Devuelve sólo ofertas, profesionales y servicios activos.

```http
GET /api/v1/services/3/staff_members
```

Respuesta `200`:

```json
{"data":[{"id":7,"first_name":"Laura","last_name":"Gómez","service_offering_id":9}]}
```

Una colección válida sin profesionales devuelve `{"data":[]}`. Error:
`404 not_found` si el servicio no existe o está inactivo.

### Consultar horarios libres

`GET /service_offerings/:id/available_slots?date=YYYY-MM-DD` — público. `id` es
el `service_offering_id` recibido en el endpoint anterior. `date` es obligatorio
y debe ser una fecha real con formato estricto.

```http
GET /api/v1/service_offerings/9/available_slots?date=2030-01-08
```

Respuesta `200`:

```json
{
  "data": [
    {"starts_at":"2030-01-08T09:00:00-03:00","ends_at":"2030-01-08T09:30:00-03:00"},
    {"starts_at":"2030-01-08T09:30:00-03:00","ends_at":"2030-01-08T10:00:00-03:00"}
  ]
}
```

Sólo incluye horarios futuros, contenidos en la disponibilidad semanal y sin
superposición con turnos confirmados del profesional. Sin horarios devuelve
`{"data":[]}`. Errores: `400 invalid_date`, `404 not_found`.

## Turnos del cliente

Todas las operaciones de esta sección requieren token. El backend obtiene el
cliente desde la sesión e ignora cualquier `customer_id` enviado.

### Listar turnos propios

`GET /appointments` — parámetros de consulta opcionales:

| Parámetro | Tipo | Valores |
| --- | --- | --- |
| `status` | string | `scheduled`, `cancelled`, `completed` |
| `page` | integer | 1 a 1.000.000; predeterminado 1 |

Cada página tiene hasta 25 registros, ordenados desde el inicio más reciente.

```http
GET /api/v1/appointments?status=scheduled&page=1
Authorization: Bearer TOKEN_OPACO
```

Respuesta `200`:

```json
{
  "data": [
    {
      "id": 21,
      "starts_at": "2030-01-08T09:00:00-03:00",
      "ends_at": "2030-01-08T09:30:00-03:00",
      "status": "scheduled",
      "notes": "Sin perfume",
      "service": {"id":3,"name":"Corte","description":"Corte y peinado","duration_minutes":30,"price":"15000.0","image_url":null},
      "staff_member": {"id":7,"first_name":"Laura","last_name":"Gómez"},
      "created_at": "2029-12-01T12:00:00Z",
      "updated_at": "2029-12-01T12:00:00Z"
    }
  ],
  "meta": {"page":1,"per_page":25,"next_page":null}
}
```

Errores: `400 invalid_status`, `400 invalid_page`, `401 unauthorized`.

### Crear turno

`POST /appointments` — entrada bajo `appointment`:

| Campo | Tipo | Obligatorio | Validación |
| --- | --- | --- | --- |
| `service_offering_id` | integer | sí | oferta, servicio y profesional activos |
| `starts_at` | string ISO 8601 | sí | futuro, dentro de disponibilidad y sin superposición |
| `notes` | string | no | texto libre o `null` |

La duración y `ends_at` se calculan en el servidor.

```http
POST /api/v1/appointments
Authorization: Bearer TOKEN_OPACO
Content-Type: application/json

{"appointment":{"service_offering_id":9,"starts_at":"2030-01-08T09:00:00-03:00","notes":"Sin perfume"}}
```

Respuesta `201`: `data` contiene un Turno con el formato mostrado en el listado.

Errores: `400 bad_request`, `401 unauthorized`, `422 validation_failed`. Las
validaciones incluyen cliente u oferta inactivos, fecha pasada, horario fuera de
disponibilidad, duración inválida, superposición y base ocupada temporalmente.

### Consultar turno propio

`GET /appointments/:id` — `id` es un integer de ruta.

```http
GET /api/v1/appointments/21
Authorization: Bearer TOKEN_OPACO
```

Respuesta `200`: `data` contiene un Turno. Error `404 not_found` tanto para un id
inexistente como para un turno de otro cliente; también puede devolver
`401 unauthorized`.

### Cancelar turno propio

`PATCH /appointments/:id/cancel` — cancela sólo un turno `scheduled` cuyo inicio
sea futuro.

```http
PATCH /api/v1/appointments/21/cancel
Authorization: Bearer TOKEN_OPACO
```

Respuesta `200`: `data` contiene el Turno con `status: "cancelled"`.

Errores: `401 unauthorized`, `404 not_found`, `422 not_cancellable` y, ante una
falla de persistencia, `422 validation_failed`.

## CORS y ejecución local

En desarrollo el origen permitido predeterminado es `http://localhost:4200`.
Para otros orígenes se configura una lista exacta separada por comas:

```bash
API_ALLOWED_ORIGINS=http://localhost:4200,https://frontend.example.com bin/rails server
```

En producción no se habilita ningún origen implícito. El preflight acepta los
métodos `GET`, `POST`, `PUT`, `PATCH`, `DELETE`, `OPTIONS` y `HEAD`, y encabezados
incluido `Authorization`.
