# Imagen base de Matomo (versión estable con Apache)
FROM matomo:5.5-apache

# Crear el fichero personalizado de configuración PHP
RUN echo "php_admin_value[memory_limit] = 512M" > /usr/local/etc/php/conf.d/zzz-matomo.ini \
    && echo "upload_max_filesize = 512M" >> /usr/local/etc/php/conf.d/zzz-matomo.ini \
    && echo "post_max_size = 512M" >> /usr/local/etc/php/conf.d/zzz-matomo.ini

# Exponer el puerto por defecto
EXPOSE 80

# Mantener el entrypoint original del contenedor Matomo
