# Etapa 5 — Active Storage, Action Mailer y tests

Esta etapa incorpora una imagen opcional al catálogo de servicios y un correo de
confirmación para cada nueva reserva.

## Imágenes de servicios

`Service` usa `has_one_attached :image`. El back-office permite cargar,
reemplazar y quitar el archivo desde el formulario del servicio. Se aceptan JPEG,
PNG y WebP de hasta 5 MB; tanto el tipo como el tamaño se validan en el modelo.

La API agrega `image_url` a cada representación de servicio. Su valor es una URL
absoluta de Active Storage cuando existe un adjunto y `null` cuando no existe. La
descarga se sirve mediante las rutas firmadas de Active Storage.

Los archivos se guardan en disco local en desarrollo y producción, y bajo
`tmp/storage` durante las pruebas. Antes de usar otro proveedor debe definirse el
servicio correspondiente en `config/storage.yml`.

## Confirmación de reservas

Al confirmar por primera vez un `Appointment`, un callback posterior al commit
encola `AppointmentConfirmationMailer#confirmation`. Actualizar, cancelar o
completar el turno no genera otro mensaje. El correo tiene versiones HTML y texto
y detalla servicio, profesional, fecha, hora y duración.

En desarrollo los mensajes usan la configuración local de Rails. Para un envío
SMTP en producción se configuran estas variables:

| Variable | Uso |
| --- | --- |
| `MAILER_FROM` | Remitente; por defecto `turnos@example.com` |
| `APP_HOST` | Host público usado por los mailers |
| `SMTP_ADDRESS` | Activa SMTP e indica el servidor |
| `SMTP_PORT` | Puerto; por defecto `587` |
| `SMTP_DOMAIN` | Dominio HELO; por defecto `APP_HOST` |
| `SMTP_USERNAME` / `SMTP_PASSWORD` | Credenciales del proveedor |
| `SMTP_AUTHENTICATION` | Método; por defecto `plain` |

En producción el envío se encola en Solid Queue, por lo que debe estar activo el
proceso de jobs además del servidor web.

## Verificación

Los specs nuevos cubren las validaciones de tipo y tamaño, la carga y eliminación
desde el back-office, la URL entregada por la API, el encolado único y ambas
versiones del correo.

En la revisión previa de la etapa 4 pasaron 76 specs no-system, RuboCop, Zeitwerk
y Brakeman sin advertencias. Las tres pruebas de navegador quedaron inicialmente
pendientes por ausencia de Chrome/ChromeDriver en ese entorno. Antes de cerrar
esta etapa se preparó un entorno temporal con Chrome for Testing 154 y
ChromeDriver 154: los tres ejemplos system pasaron sin fallos, junto con los
specs nuevos de adjuntos y correo de confirmación. La corrida final unificada
terminó con 85 ejemplos y 0 fallos.
