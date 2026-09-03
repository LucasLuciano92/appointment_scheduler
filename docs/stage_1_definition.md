# Etapa 1 — Definición del dominio

## Temática y alcance

El proyecto consiste en un sistema de reserva de turnos para un salón o centro de estética de una sola sede.

Está pensado como una aplicación comercial. Por ese motivo, el dominio utiliza conceptos generales que permitirán adaptarlo en el futuro a otros negocios que trabajan con turnos, sin agregar ahora la complejidad de una plataforma genérica.

La primera versión administra un único negocio y una única sede. No incluye múltiples sucursales ni múltiples organizaciones.

Todos los nombres técnicos —models, attributes, associations, roles, statuses, methods, controllers y routes— estarán en inglés. Los textos visibles para el usuario y la documentación pueden estar en español.

El nombre técnico propuesto para la aplicación es AppointmentScheduler y su forma snake_case será appointment_scheduler.

## 1. Objetivo general

Desarrollar un backend en Ruby on Rails que centralice la administración y la reserva de turnos de un salón o centro de estética.

El sistema ofrecerá:

- un back-office autenticado para administrar el negocio;
- una API JSON para que el frontend público pueda autenticar clientes, mostrar servicios y horarios disponibles, y gestionar reservas.

El diseño deberá resolver las necesidades actuales del salón y, al mismo tiempo, mantener conceptos centrales reutilizables por otros negocios que ofrecen servicios con turno.

## 2. Problema concreto

Cuando los turnos se coordinan manualmente mediante llamadas, mensajes y agendas separadas, los clientes no pueden consultar la disponibilidad actual por sí mismos y el personal administrativo debe comparar continuamente profesionales, servicios y horarios.

Este proceso puede provocar:

- turnos superpuestos para un mismo miembro del personal;
- reservas fuera del horario de trabajo;
- reservas de servicios que un miembro del personal no realiza;
- información incompleta o inconsistente de los clientes;
- dificultad para seguir cancelaciones y turnos completados;
- trabajo administrativo repetitivo para responder consultas de disponibilidad.

La aplicación proporcionará una única fuente de información para clientes, miembros del personal, servicios, disponibilidades y turnos.

## 3. Tipos de usuario

El sistema tendrá dos roles autenticados, representados por un único model User.

### admin

Un admin utilizará el back-office renderizado por Rails. Podrá administrar el catálogo del negocio, el personal, las disponibilidades, los clientes y todos los turnos.

La creación del primer admin y la promoción de otros usuarios a ese rol no estarán disponibles mediante la API pública. Su mecanismo se definirá en una etapa posterior.

### customer

Un customer utilizará el frontend público a través de la API JSON. Podrá administrar su propio perfil, consultar disponibilidad, reservar turnos y acceder únicamente a sus propias reservas.

### StaffMember

StaffMember será una entidad del dominio, pero no un usuario autenticado en la primera versión. Incorporar un portal para el personal agregaría un tercer contexto de uso y queda fuera del alcance inicial.

## 4. Responsabilidad de cada modelo

### User

Representa a una persona autenticada. Conserva los datos comunes de identidad y autenticación, y diferencia administradores de clientes mediante role.

### StaffMember

Representa a una persona que realiza servicios en el salón. Contiene información profesional y de activación, pero no credenciales de acceso.

### Service

Representa un tipo de servicio que los clientes pueden reservar, junto con su duración estándar y su precio actual.

### ServiceOffering

Representa que un StaffMember está habilitado para realizar un Service determinado. Es un concepto real del negocio y no una asociación creada solamente para aumentar la cantidad de models.

Esta relación explícita evita que un Appointment combine un miembro del personal con un servicio que no realiza.

### Availability

Representa una franja horaria semanal recurrente en la que un StaffMember trabaja. Un miembro del personal puede tener más de una franja el mismo día.

No representa turnos libres materializados ni excepciones para fechas particulares.

### Appointment

Representa la reserva de un customer para un ServiceOffering concreto, en una fecha y franja horaria determinadas. También registra el estado del turno durante su ciclo de vida.

## 5. Atributos mínimos de cada modelo

Todos los models tendrán además id, created_at y updated_at, provistos convencionalmente por Rails.

### User

| Attribute | Type | Required | Responsabilidad |
| --- | --- | --- | --- |
| first_name | string | sí | Nombre de la persona |
| last_name | string | sí | Apellido de la persona |
| email_address | string | sí | Identificador de acceso y destino de emails |
| phone | string | no | Teléfono de contacto |
| password_digest | string | sí | Resumen seguro de la contraseña |
| role | integer enum | sí | admin o customer |
| active | boolean | sí | Permite deshabilitar el acceso sin borrar el historial |

### StaffMember

| Attribute | Type | Required | Responsabilidad |
| --- | --- | --- | --- |
| first_name | string | sí | Nombre del miembro del personal |
| last_name | string | sí | Apellido del miembro del personal |
| email_address | string | no | Email de contacto profesional |
| phone | string | no | Teléfono de contacto profesional |
| active | boolean | sí | Indica si puede recibir nuevas reservas |

### Service

| Attribute | Type | Required | Responsabilidad |
| --- | --- | --- | --- |
| name | string | sí | Nombre comercial del servicio |
| description | text | no | Información que se mostrará en el catálogo |
| duration_minutes | integer | sí | Duración estándar del turno |
| price | decimal | sí | Precio actual en la moneda configurada para el negocio |
| active | boolean | sí | Indica si puede recibir nuevas reservas |

Más adelante se adjuntará una imagen a Service mediante Active Storage. Esa imagen no será un atributo común de la tabla.

### ServiceOffering

| Attribute | Type | Required | Responsabilidad |
| --- | --- | --- | --- |
| staff_member_id | reference | sí | StaffMember que realiza el servicio |
| service_id | reference | sí | Service que puede realizar |
| active | boolean | sí | Permite deshabilitar la oferta sin perder su historial |

La duración y el precio estándar pertenecerán a Service. La primera versión no permitirá valores diferentes para cada StaffMember.

### Availability

| Attribute | Type | Required | Responsabilidad |
| --- | --- | --- | --- |
| staff_member_id | reference | sí | StaffMember al que pertenece la franja |
| day_of_week | integer enum | sí | monday a sunday |
| start_time | time | sí | Inicio de la franja semanal |
| end_time | time | sí | Fin de la franja semanal |
| active | boolean | sí | Permite deshabilitar la franja sin borrarla |

### Appointment

| Attribute | Type | Required | Responsabilidad |
| --- | --- | --- | --- |
| customer_id | reference to users | sí | Customer propietario del turno |
| service_offering_id | reference | sí | Combinación elegida de StaffMember y Service |
| starts_at | datetime | sí | Inicio del turno |
| ends_at | datetime | sí | Fin del turno |
| status | integer enum | sí | scheduled, cancelled o completed |
| notes | text | no | Información opcional relacionada con el turno |

ends_at se calculará a partir de starts_at y Service.duration_minutes cuando se cree o reprograme el turno. Se almacenará para que una reserva existente conserve la duración acordada si posteriormente cambia el Service.

El precio histórico no se almacenará en Appointment en esta primera versión porque no se implementarán pagos ni facturación.

## 6. Relaciones

- User tendrá muchos appointments mediante la asociación customer.
- Appointment pertenecerá a customer, utilizando User como class.
- StaffMember tendrá muchas availabilities.
- StaffMember tendrá muchos service_offerings.
- StaffMember tendrá muchos services a través de service_offerings.
- Service tendrá muchos service_offerings.
- Service tendrá muchos staff_members a través de service_offerings.
- ServiceOffering pertenecerá a un staff_member.
- ServiceOffering pertenecerá a un service.
- ServiceOffering tendrá muchos appointments.
- Appointment pertenecerá a un service_offering.

Appointment no pertenecerá directamente a Availability. Availability describe una regla semanal recurrente, mientras que Appointment representa una fecha y hora específicas. Al crear o reprogramar una reserva, su horario se validará contra las franjas de disponibilidad correspondientes.

## 7. Validaciones principales

### User

- first_name, last_name, email_address, password_digest y role serán obligatorios.
- email_address se normalizará y será único sin distinguir mayúsculas de minúsculas.
- email_address deberá tener un formato válido básico.
- La contraseña tendrá un mínimo de ocho caracteres.
- role solo admitirá admin o customer.
- role tendrá customer como valor predeterminado.
- active será boolean y tendrá true como valor predeterminado.

### StaffMember

- first_name y last_name serán obligatorios.
- email_address deberá tener un formato válido cuando esté presente.
- email_address será único entre los registros de StaffMember cuando esté presente.
- active será boolean y tendrá true como valor predeterminado.

### Service

- name, duration_minutes y price serán obligatorios.
- name será único sin distinguir mayúsculas de minúsculas.
- duration_minutes será un número entero mayor que cero.
- price será mayor o igual que cero.
- active será boolean y tendrá true como valor predeterminado.

### ServiceOffering

- staff_member y service serán obligatorios.
- La combinación de staff_member y service será única.
- active será boolean y tendrá true como valor predeterminado.

### Availability

- staff_member, day_of_week, start_time y end_time serán obligatorios.
- day_of_week solo admitirá valores entre monday y sunday.
- start_time deberá ser anterior a end_time.
- Una franja no podrá atravesar la medianoche.
- Las franjas activas de un mismo StaffMember en un mismo day_of_week no podrán superponerse.
- active será boolean y tendrá true como valor predeterminado.

### Appointment

- customer, service_offering, starts_at, ends_at y status serán obligatorios.
- Al crear o reprogramar, customer deberá tener role customer y estar activo.
- status solo admitirá scheduled, cancelled o completed.
- status tendrá scheduled como valor predeterminado.
- starts_at deberá ser anterior a ends_at.
- starts_at deberá estar en el futuro al crear o reprogramar un turno.
- Al crear o reprogramar, ServiceOffering, StaffMember y Service deberán estar activos.
- El intervalo completo deberá quedar dentro de una Availability activa del StaffMember.
- La duración deberá coincidir con Service.duration_minutes al crear o reprogramar.
- Un Appointment con status scheduled no podrá superponerse con otro Appointment scheduled del mismo StaffMember.

En la Etapa 2, estas validaciones de aplicación se complementarán con constraints e indexes de base de datos cuando corresponda.

## 8. Reglas de negocio

1. La aplicación operará para un negocio, una sede, una moneda y una zona horaria configuradas globalmente.
2. Las fechas y horas se almacenarán de forma consistente y se presentarán en la zona horaria del negocio.
3. Los registros públicos crearán únicamente users con role customer.
4. El role admin no podrá obtenerse mediante la API pública.
5. Solo un customer activo podrá crear un Appointment.
6. Un customer podrá acceder únicamente a su perfil y a sus propios appointments.
7. Un nuevo Appointment solo podrá utilizar un ServiceOffering activo cuyo StaffMember y Service también estén activos.
8. La duración de Appointment se copiará desde Service cuando se cree o reprograme la reserva.
9. Cambiar posteriormente Service.duration_minutes no modificará los appointments existentes.
10. Availability será semanal y recurrente. Feriados, vacaciones y excepciones por fecha quedarán fuera de la primera versión.
11. Un Appointment deberá quedar completamente contenido en una única Availability activa.
12. Solo los appointments con status scheduled bloquearán horarios.
13. Los appointments scheduled de un mismo StaffMember no podrán superponerse. Los intervalos serán semiabiertos: un turno podrá comenzar exactamente cuando termine el anterior.
14. scheduled significará que la reserva fue aceptada por el sistema y está confirmada.
15. Las transiciones iniciales válidas serán de scheduled a cancelled y de scheduled a completed. cancelled y completed serán estados terminales.
16. Un customer solo podrá cancelar un Appointment propio, futuro y scheduled. Para cambiarlo, deberá cancelar y crear uno nuevo.
17. Un admin podrá crear y cancelar appointments en nombre de customers, reprogramar appointments scheduled y marcar como completed los appointments cuyo horario ya haya finalizado.
18. Modificar o desactivar una Availability no cambiará ni cancelará automáticamente appointments existentes.
19. Desactivar un User, StaffMember, Service o ServiceOffering impedirá nuevas operaciones, pero conservará el historial existente.
20. Los appointments no se eliminarán físicamente: su ciclo de vida se representará mediante status.
21. Los demás registros referenciados por appointments se desactivarán en lugar de eliminarse. El borrado físico solo se permitirá cuando no exista historial relacionado.
22. Crear un Appointment enviará posteriormente un email de confirmación mediante Action Mailer.
23. La prevención de reservas simultáneas para el mismo horario será una regla obligatoria que deberá implementarse y probarse en etapas posteriores.

Quedarán fuera de la primera versión:

- pagos, facturación, señas, promociones y múltiples monedas;
- múltiples negocios, sucursales o locations;
- autenticación y portal de StaffMember;
- feriados, vacaciones y excepciones de disponibilidad;
- lista de espera y turnos recurrentes;
- reservas grupales;
- recordatorios por email, SMS o mensajería;
- notificaciones en tiempo real;
- sincronización con calendarios externos;
- inventario, reseñas y programas de fidelización.

## 9. Diagrama de clases

~~~mermaid
classDiagram
    class User {
        +string first_name
        +string last_name
        +string email_address
        +string phone
        +string password_digest
        +enum role
        +boolean active
    }

    class StaffMember {
        +string first_name
        +string last_name
        +string email_address
        +string phone
        +boolean active
    }

    class Service {
        +string name
        +text description
        +integer duration_minutes
        +decimal price
        +boolean active
    }

    class ServiceOffering {
        +reference staff_member_id
        +reference service_id
        +boolean active
    }

    class Availability {
        +reference staff_member_id
        +enum day_of_week
        +time start_time
        +time end_time
        +boolean active
    }

    class Appointment {
        +reference customer_id
        +reference service_offering_id
        +datetime starts_at
        +datetime ends_at
        +enum status
        +text notes
    }

    User "1" --> "0..*" Appointment : customer
    StaffMember "1" --> "0..*" Availability : has
    StaffMember "1" --> "0..*" ServiceOffering : provides
    Service "1" --> "0..*" ServiceOffering : offered through
    ServiceOffering "1" --> "0..*" Appointment : booked as
~~~

## 10. Funcionalidades del admin

El admin utilizará el back-office autenticado para:

- iniciar y cerrar sesión;
- crear, consultar, actualizar, activar y desactivar registros de StaffMember;
- crear, consultar, actualizar, activar y desactivar registros de Service;
- adjuntar y reemplazar la imagen de un Service;
- asignar un Service a un StaffMember mediante ServiceOffering;
- activar y desactivar registros de ServiceOffering;
- crear, consultar, actualizar, activar y desactivar registros semanales de Availability;
- eliminar registros sin historial relacionado y desactivar los que deban conservarse;
- listar y consultar customers;
- crear y actualizar customers cuando sea necesario;
- activar y desactivar el acceso de customers;
- listar y filtrar todos los registros de Appointment;
- crear un Appointment en nombre de un customer;
- reprogramar o cancelar un Appointment scheduled;
- marcar como completed un Appointment pasado.

Los controllers y views administrativos se agruparán posteriormente bajo el namespace Admin.

## 11. Funcionalidades del customer

El customer utilizará el frontend público a través de la API JSON para:

- registrar una cuenta;
- iniciar y cerrar sesión;
- consultar y actualizar su propio perfil;
- consultar los registros activos de Service y sus imágenes;
- consultar los registros activos de StaffMember que ofrecen un Service;
- consultar horarios disponibles para un service_offering y una fecha;
- crear un Appointment;
- listar y consultar únicamente sus propios registros de Appointment;
- cancelar un Appointment propio, futuro y scheduled;
- recibir el email de confirmación de la reserva.

Los controllers públicos y autenticados de la API se agruparán posteriormente bajo el namespace Api::V1. El mecanismo exacto de autenticación y el contrato de endpoints se definirán durante la etapa de API.

## Criterios de finalización de la Etapa 1

La Etapa 1 se considerará completa cuando:

- la temática, el problema concreto y el objetivo general estén aprobados;
- las responsabilidades de admin y customer sean inequívocas;
- los seis models tengan una responsabilidad real dentro del dominio;
- se hayan acordado sus atributos mínimos, relaciones, validaciones y reglas de negocio;
- todo el vocabulario técnico esté en inglés;
- el diagrama coincida con las relaciones escritas;
- se comprenda qué funcionalidades fueron excluidas intencionalmente;
- no se generen migrations, models, controllers ni routes antes de aceptar esta definición.
