# Etapa 7 — Deploy

La aplicación queda preparada para desplegarse en un único servidor Linux con
Docker mediante Kamal 2. El servidor conserva SQLite, Solid Queue, Solid Cache y
los archivos de Active Storage en el volumen Docker
`appointment_scheduler_storage`. Kamal Proxy publica la aplicación con HTTPS,
gestiona el certificado de Let's Encrypt y verifica `/up` antes de reemplazar
una versión activa.

## Infraestructura requerida

- Un servidor AMD64 con una IP pública y acceso SSH.
- Un dominio cuyo registro `A` apunte a esa IP. Los puertos 80 y 443 deben estar
  abiertos para Kamal Proxy y Let's Encrypt.
- Docker instalado en la máquina local desde la que se despliega.
- Un token personal de GitHub con permisos `read:packages` y `write:packages`
  para publicar la imagen en GitHub Container Registry.
- El valor de `RAILS_MASTER_KEY`, disponible localmente en `config/master.key` o
  inyectado como variable de entorno.

El host remoto puede comenzar vacío: `bin/kamal setup` instala Docker cuando el
usuario SSH tiene los permisos necesarios. Por defecto se conecta como `root`;
`DEPLOY_USER` permite elegir otro usuario con acceso a Docker.

## Variables de despliegue

Las credenciales no se almacenan en Git. Antes del primer deploy:

```bash
export DEPLOY_HOST=203.0.113.10
export APP_HOST=turnos.example.com
export KAMAL_REGISTRY_USERNAME=usuario-de-github
export KAMAL_REGISTRY_PASSWORD=token-de-github
export RAILS_MASTER_KEY=contenido-de-config/master.key
```

`API_ALLOWED_ORIGINS` adopta `https://$APP_HOST`; si el frontend vive en otro
dominio debe definirse explícitamente. También se pueden ajustar
`MAILER_FROM`, `BUSINESS_TIME_ZONE`, `BUSINESS_CURRENCY` y `DEPLOY_USER`.

El correo SMTP es opcional. Para habilitar el envío real de confirmaciones:

```bash
export SMTP_ADDRESS=smtp.example.com
export SMTP_PORT=587
export SMTP_DOMAIN=example.com
export SMTP_USERNAME=usuario
export SMTP_PASSWORD=secreto
```

## Primer despliegue y actualizaciones

Comprobar primero que Kamal resuelve la configuración sin mostrar ni compartir
su salida, porque `bin/kamal config` incluye secretos:

```bash
bin/kamal config > /dev/null
bin/kamal setup
```

`setup` construye la imagen, la publica en GHCR, prepara el servidor, crea el
volumen persistente y arranca la aplicación. El entrypoint ejecuta
`bin/rails db:prepare` antes de iniciar Rails. Las siguientes versiones se
publican con:

```bash
bin/kamal deploy
```

Tras el primer deploy se debe crear el administrador inicial:

```bash
bin/kamal app exec --interactive --reuse "bin/rails admin:create"
```

La comprobación externa de cierre es:

```bash
curl --fail --show-error https://$APP_HOST/up
```

Los comandos `bin/kamal logs`, `bin/kamal console` y `bin/kamal dbc` sirven para
diagnóstico. `bin/kamal rollback VERSION` revierte el contenedor; una migración
de datos incompatible requiere además su propio procedimiento de restauración.

## Persistencia y copias de seguridad

El volumen Docker sobrevive a cada reemplazo del contenedor, pero no protege
frente a la pérdida del servidor. Se debe programar una copia remota y cifrada
de todo `/var/lib/docker/volumes/appointment_scheduler_storage/_data`, que
contiene las cuatro bases SQLite y los adjuntos. Antes de copiar bases en uso,
crear snapshots coherentes con `sqlite3 ... '.backup destino'` o detener
brevemente la aplicación.

La restauración se valida en otro servidor: crear el volumen con el mismo
nombre, recuperar todo su contenido, ejecutar `bin/kamal setup` y comprobar
`/up`, el acceso administrativo y una imagen previamente cargada.

## Estado de publicación

La configuración y el contenedor pueden verificarse localmente sin conocer la
infraestructura final. La URL pública solo se incorpora al README después de
completar un deploy real y comprobar su endpoint de salud.
