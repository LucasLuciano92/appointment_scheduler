# Trabajo Práctico Nº 1 - Programación IV

## Tecnología
- Ruby on Rails
- Git
- Repositorio accesible
- Los commits deben reflejar la evolución del proyecto

## Requisitos generales
- Proyecto individual
- Backend en Ruby on Rails
- El frontend se desarrollará en el TP Nº 2
- Todos los nombres técnicos deben estar en inglés:
  - Models
  - Controllers
  - Attributes
  - Routes
  - Methods
  - Associations

## Modelo de datos
- Mínimo 5 modelos principales relacionados entre sí
- Deben representar entidades reales del dominio
- Deben incluir validaciones
- Deben utilizar asociaciones de Active Record

## Back-office
- Debe existir una sección administrativa
- Debe utilizar:
  - Controllers
  - Views
  - Templates
  - Forms
  - Routing
  - Active Record
- Debe permitir operaciones CRUD
- Debe estar protegido con autenticación
- Solo usuarios autorizados pueden acceder

Se recomienda usar namespace:

namespace :admin do
  ...
end

## API
- Debe existir una API JSON separada del back-office
- Se recomienda versionar los endpoints

Ejemplo:

/api/v1/...

## Usuarios
Debe haber al menos dos contextos:

### Admin user
- Accede al back-office
- Administra el sistema

### Final user
- Consume el frontend público
- Se autentica mediante la API
- Puede utilizar token para requests protegidos

No es obligatorio que admin y usuario final sean modelos separados.

## Active Storage
Debe existir al menos un uso real de Active Storage.

Ejemplos:
- Imagen
- Avatar
- Documento
- Archivo adjunto

## Action Mailer
Debe existir al menos un envío real de email.

Ejemplos:
- Bienvenida
- Confirmación
- Recuperación de contraseña

## Testing
Debe haber tests automatizados como mínimo para:
- Models
- Validations
- Alguna lógica de negocio

## Calidad
Usar Rubocop y ejecutar la validación antes de entregar.

## Seguridad
Usar Brakeman y analizar las advertencias antes de entregar.

## Opcionales
- Swagger
- Active Job
- Action Cable
- Hotwire / Turbo
- Deploy

## Etapas recomendadas
1. Definición de temática
2. Modelos y base de datos
3. Back-office
4. API
5. Active Storage, Action Mailer y Tests
6. Rubocop y Brakeman
7. Deploy

## Entrega
Debe incluir README.md con:
- Cómo instalar y ejecutar
- Cómo preparar la base de datos
- Cómo acceder al back-office
- Endpoints principales de la API
- Modelo de datos
- URL de deploy, si existe