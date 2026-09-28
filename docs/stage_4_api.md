# Etapa 4 — API JSON

La API versionada permite que el frontend público registre y autentique clientes,
consulte el catálogo y la disponibilidad, y gestione reservas. Todas las rutas
comienzan con `/api/v1` y reciben y producen JSON.

## Autenticación

`POST /registration` crea siempre un `User` con rol `customer` y estado activo,
aunque el cliente envíe otros valores. `POST /session` acepta únicamente una
cuenta customer activa. Ambos endpoints devuelven:

```json
{
  "data": {
    "id": 12,
    "first_name": "Ana",
    "last_name": "Pérez",
    "email_address": "ana@example.com",
    "phone": null
  },
  "token": "TOKEN_OPACO"
}
```

El token se envía como `Authorization: Bearer TOKEN_OPACO`. En la base se guarda
solo su SHA-256, nunca el valor utilizable. Cada token vence a los 30 días y
`DELETE /session` revoca solamente la sesión actual. Cambiar la contraseña,
desactivar el usuario o cambiar su rol revoca todas sus sesiones de API.

`GET /profile` y `PATCH /profile` operan exclusivamente sobre el usuario del
token. Los atributos editables son `first_name`, `last_name`, `email_address`,
`phone`, `password` y `password_confirmation`; no se admiten `role` ni `active`.

Ejemplo de registro:

```bash
curl -X POST http://localhost:3000/api/v1/registration \
  -H 'Content-Type: application/json' \
  -d '{"user":{"first_name":"Ana","last_name":"Pérez","email_address":"ana@example.com","password":"password123","password_confirmation":"password123"}}'
```

## Catálogo y horarios

- `GET /services` y `GET /services/:id` exponen solo servicios activos.
- `GET /services/:service_id/staff_members` expone profesionales activos con una
  oferta activa. Cada elemento incluye `service_offering_id`, necesario para
  consultar disponibilidad y reservar.
- `GET /service_offerings/:id/available_slots?date=YYYY-MM-DD` devuelve intervalos
  futuros alineados con la duración del servicio, contenidos en la disponibilidad
  semanal. Omite los intervalos ocupados por cualquier turno confirmado del
  profesional, incluso si pertenece a otra oferta.

Ejemplo de un horario:

```json
{
  "starts_at": "2030-01-08T09:00:00-03:00",
  "ends_at": "2030-01-08T09:30:00-03:00"
}
```

## Turnos del cliente

Todas estas rutas exigen token:

| Método y ruta | Operación |
| --- | --- |
| `GET /appointments` | Lista únicamente turnos propios; acepta `status` y `page` |
| `POST /appointments` | Reserva mediante `service_offering_id`, `starts_at` y `notes` |
| `GET /appointments/:id` | Muestra únicamente un turno propio |
| `PATCH /appointments/:id/cancel` | Cancela un turno propio, futuro y confirmado |

El servidor toma el customer del token e ignora cualquier `customer_id` enviado.
La creación reutiliza la transacción de reserva del back-office, por lo que aplica
las mismas reglas de actividad, disponibilidad, duración y no superposición.

El listado devuelve 25 registros por página e incluye metadatos para avanzar sin
cargar el historial completo:

```json
{
  "data": [],
  "meta": { "page": 1, "per_page": 25, "next_page": 2 }
}
```

```bash
curl -X POST http://localhost:3000/api/v1/appointments \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer TOKEN_OPACO' \
  -d '{"appointment":{"service_offering_id":4,"starts_at":"2030-01-08T09:00:00-03:00","notes":"Sin perfume"}}'
```

## Respuestas y errores

Los recursos exitosos se envuelven en `data`. Las colecciones usan un array y
los recursos individuales un objeto. Los errores tienen una forma estable:

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

Los estados principales son `201` para registro, login y reserva; `204` para
logout; `400` para parámetros o filtros inválidos; `401` para autenticación;
`404` para recursos inexistentes o ajenos; `422` para reglas de negocio; y `429`
para límites de intentos de registro o login.

Las respuestas llevan `Cache-Control: no-store`. No se exponen email ni teléfono
del personal, credenciales, roles, estados internos de activación ni datos de
otros clientes.

## Acceso desde el frontend

CORS se limita a los orígenes indicados en `API_ALLOWED_ORIGINS`, separados por
comas. Fuera de producción el valor predeterminado es
`http://localhost:5173`. En producción no se habilita ningún origen de manera
implícita: el deploy debe definir la URL exacta del frontend.

## Verificación

Los specs cubren emisión, hash, expiración y revocación de tokens; registro y
login; rate limiting; atributos permitidos; CORS; visibilidad del catálogo;
cálculo de horarios, incluso en cambios DST; paginación; creación, listado,
consulta y cancelación de turnos; filtros; y aislamiento entre clientes.

Como mejoras operativas posteriores quedan la purga periódica de sesiones
vencidas y el uso de caché HTTP en los endpoints públicos del catálogo. No
afectan el contrato ni las reglas funcionales de esta etapa.

Active Storage para imágenes de servicios y el email de confirmación mediante
Action Mailer se incorporarán en la etapa 5.
