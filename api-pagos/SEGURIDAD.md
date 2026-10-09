# Seguridad.

## Medidas de seguridad.
- Se va a aplicar la ejecución de contenedores con **usuarios sin privilegios**.
- Aseguramos que ningún archivo de configuración sensibles se incluyan en el build context ni en los repositorios Git.
- Usuario "no-root" para la ejecución de contenedores: **Medida de seguridad crucial.** Por defecto, los contenedores corren como root. Si un atacante lograra vulnerar nuestro servicio api-clientes, tendría acceso de root en ese contenedor. Al crear y ejecutar todo con el usuario appuser, mitigamos drásticamente el impacto de un posible ataque o vulnerabilidad de ejecución remota de código en Flask.
- **Superficie de ataque reducida en la imagen base**
- **Dependencias exclusivas de producción**
- **Protección del Build Context**

## Explicación de medidas.
- ¿Por qué se recomienda crear un usuario "no-root"?
    - Si no se define un usuario en el Dockerfile, Docker va a ejecutar todos los procesos internos como `root`. Esto es porque ayuda a la **mitigación de escape de contenedor**, que aunque los contenedores usen *namespaces* y *cgroups* para aislarse ya que comparten el mismo SO que el host. Si un atacante explota una vulnerabilidad en la aplicación y escapa del contenedor siendo `root`, va a tener privilegios de superusuario directos sobre la máquina anfitriona. 
- ¿Comó se logra una Superficie reducida en la imagen base?
    - Se utiliza una imagen base de **Alpine Linux**, que es una distribución de Linux ligera y minimalista. Esto reduce la superficie de ataque al eliminar paquetes y servicios innecesarios, disminuyendo así las posibles vulnerabilidades.
- ¿Por qué se recomienda instalar dependencias exclusivas de producción?
  - Se definió la variable ENV NODE_ENV=production y se instalaron los paquetes utilizando npm ci --only=production. Esto asegura que no se instalen herramientas de desarrollo (que comúnmente introducen vulnerabilidades o facilitan un ataque) dentro de la imagen final.
- ¿Por qué se recomienda proteger el Build Context?
  - A través del archivo .dockerignore se evita que archivos o directorios sensibles locales (como repositorios .git, credenciales de usuario o archivos .env) sean copiados accidentalmente a la imagen. 