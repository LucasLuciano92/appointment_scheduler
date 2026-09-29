# Etapa 6 — RuboCop y Brakeman

Esta etapa consolida los controles automáticos de calidad y seguridad antes del
deploy. No se generó un archivo de exclusiones de RuboCop ni una lista de
advertencias ignoradas de Brakeman: el código debe superar las reglas activas
sin excepciones específicas del proyecto.

## Calidad de código

RuboCop hereda la configuración de `rubocop-rails-omakase`, la convención de
estilo recomendada para esta aplicación Rails. El análisis se ejecuta con:

```bash
bin/rubocop
```

La revisión de cierre inspeccionó 82 archivos y no encontró infracciones.

## Seguridad

Brakeman analiza estáticamente controladores, modelos, vistas, rutas y
configuración. Tanto la verificación local agrupada en `bin/ci` como GitHub
Actions usan `--exit-on-warn` y `--exit-on-error`, por lo que cualquier hallazgo
o error del analizador bloquea el pipeline.

```bash
bin/brakeman --no-pager --exit-on-warn --exit-on-error
```

El wrapper `bin/brakeman` también comprueba que la versión instalada esté
actualizada, lo que requiere acceso a RubyGems. Si se necesita revisar el código
sin conexión, se puede omitir únicamente esa consulta remota ejecutando:

```bash
bundle exec brakeman --no-pager --exit-on-warn --exit-on-error
```

La revisión de cierre ejecutó 79 controles sobre 18 controladores, 9 modelos y
39 templates. El resultado fue 0 errores y 0 advertencias de seguridad.

Las dependencias Ruby y JavaScript se revisan además con:

```bash
bin/bundler-audit
bin/importmap audit
```

Ambas auditorías finalizaron sin vulnerabilidades conocidas.

## Integración continua

GitHub Actions ejecuta trabajos separados para Brakeman, `bundler-audit`, la
auditoría de importmap, RuboCop, los specs de aplicación y los specs de sistema.
El comando `bin/ci` reúne los mismos controles para una revisión local completa.

Además de los analizadores, al cerrar esta etapa pasaron 82 specs no-system, los
3 specs de sistema y la comprobación de carga de Zeitwerk. Los specs de sistema
requieren que el entorno permita iniciar ChromeDriver y abrir sockets locales.
