# TP2 - Etapa 3: primera integración y checkpoint

## Resultado

El frontend Angular consume la API Rails real para los primeros recorridos del
cliente. La implementación de interfaz vive en el repositorio separado
`appointment_scheduler_frontend`; este documento registra el checkpoint desde
el backend.

## Recorridos integrados

- registro de cliente y creación automática de sesión;
- login y logout mediante token opaco;
- consulta pública del catálogo;
- consulta de profesionales y horarios disponibles;
- creación autenticada de una reserva;
- eliminación de la sesión local y redirección al login ante un `401`.

Angular conserva la sesión en `sessionStorage`, agrega el encabezado bearer
solamente a la URL configurada de la API y protege las rutas de turnos y perfil.

## Verificación del contrato

- `spec/requests/api_v1_spec.rb` verifica éxito, permisos y errores de los
  endpoints consumidos.
- Las pruebas Angular cubren sesión, login exitoso y rechazado, bearer y
  expiración de sesión.
- El frontend se verifica con formato y compilación de producción.
- El recorrido integrado usa las cuentas y el catálogo de `demo:setup`.

## Pendiente para la Etapa 4

- listar, filtrar y consultar el detalle de turnos;
- cancelar turnos futuros;
- consultar y editar el perfil;
- completar estados compartidos, accesibilidad y revisión responsive;
- ejecutar el control final y actualizar las instrucciones de entrega.
