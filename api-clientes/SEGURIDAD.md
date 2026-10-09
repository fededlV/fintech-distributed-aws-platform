# Seguridad. 

## Medidas de seguridad. 
- Se va a aplicar la ejecución de contenedores con **usuarios sin privilegios**.
- Aseguramos que ningún archivo de configuración sensibles se incluyan en el build context ni en los repositorios Git.
- Usuario "no-root" para la ejecución de contenedores: **Medida de seguridad crucial.** Por defecto, los contenedores corren como root. Si un atacante lograra vulnerar nuestro servicio api-clientes, tendría acceso de root en ese contenedor. Al crear y ejecutar todo con el usuario appuser, mitigamos drásticamente el impacto de un posible ataque o vulnerabilidad de ejecución remota de código en Flask.  
- Entorno virtual en la imagen. 

## Explicación de medidas. 
- ¿Por qué se recomienda crear un usuario "no-root"?
  - Si no se define un usuario en el Dockerfile, Docker va a ejecutar todos los procesos internos como `root`. Esto es porque ayuda a la **mitigación de escape de contenedor**, que aunque los contenedores usen *namespaces* y *cgroups* para aislarse ya que comparten el mismo SO que el host. Si un atacante explota una vulnerabilidad en la aplicación y escapa del contenedor siendo `root`, va a tener privilegios de superusuario directos sobre la máquina anfitriona. 
- Los directorios globales del sistema pertenecen al root y requieren permisos elevados para escribir en los mismos. Al crear un entorno virtual dentro de la imagen en la carpeta del proyecto el usuario `appuser` es el dueño legítimo de estos archivos, manteniendo el principio de menor privilegio. 