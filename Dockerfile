# syntax=docker/dockerfile:1
FROM php:8.2-apache

# Extensiones comunes que tu app podría necesitar (ajusta según uso real)
RUN apt-get update && apt-get install -y --no-install-recommends \
        libcurl4-openssl-dev \
    && docker-php-ext-install curl \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Apache: habilitar mod_rewrite por si usas rutas amigables
RUN a2enmod rewrite

# Copiamos el código al docroot de Apache
COPY . /var/www/html/

# Carpeta de datos: la creamos aquí por si no viene montado el volumen aún,
# y le damos dueño www-data (el usuario con el que corre Apache+PHP)
RUN mkdir -p /var/www/html/data \
    && chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html \
    && chmod -R 775 /var/www/html/data

# IMPORTANTE: en Coolify, monta el volumen persistente en /var/www/html/data
# Si el volumen llega vacío con dueño root, este RUN de arriba no alcanza
# porque el volumen se monta DESPUÉS del build. En ese caso, usa un
# entrypoint que haga chown al iniciar (ver nota abajo).

EXPOSE 80

# Entrypoint que corrige permisos del volumen en cada arranque,
# por si Coolify lo monta con otro dueño.
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]
