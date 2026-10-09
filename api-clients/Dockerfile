# Etapa 1: Builder
# Usamos una imagen de Python 3.11 reducida para compilar e instalar dependencias
FROM python:3.11-slim AS builder

# Establecemos el directorio de trabajo
WORKDIR /app

# Creamos un entorno virtual dentro de la imagen
RUN python -m venv /opt/venv

# Activamos el entorno virtual (agregándolo al PATH)
ENV PATH="/opt/venv/bin:$PATH"

# Copiamos el archivo de requerimientos
COPY requirements.txt .

# Instalamos las dependencias en el entorno virtual
# Usamos --no-cache-dir para no guardar el caché de pip, reduciendo el tamaño temporal
RUN pip install --no-cache-dir -r requirements.txt


# Etapa 2: Runner (Imagen final)
# Usamos nuevamente una imagen base slim para que sea liviana
FROM python:3.11-slim

# Configuramos variables de entorno de Python
# PYTHONDONTWRITEBYTECODE: evita que Python escriba archivos .pyc en el disco
# PYTHONUNBUFFERED: asegura que la salida de stdout/stderr se imprima directamente, útil para logs en Docker
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Creamos un usuario "no-root" por motivos de seguridad
RUN adduser --disabled-password --gecos '' appuser

# Directorio de trabajo
WORKDIR /app

# Copiamos ÚNICAMENTE el entorno virtual ya instalado de la etapa 'builder'
COPY --from=builder /opt/venv /opt/venv

# Nos aseguramos de utilizar el entorno virtual en esta etapa
ENV PATH="/opt/venv/bin:$PATH"

# Copiamos el código fuente de nuestra aplicación
COPY . .

# Cambiamos el propietario de los archivos al usuario no-root
RUN chown -R appuser:appuser /app

# Cambiamos la ejecución a nuestro usuario no-root (evita correr como root)
USER appuser

# Exponemos el puerto 8080 en el que correrá Flask
EXPOSE 8080

# Health check
HEALTHCHECK --interval=10s --timeout=3s --retries=3 --start-period=10s \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8080/health/live')" || exit 1

# Comando para levantar la aplicación
CMD ["python", "main.py"]

