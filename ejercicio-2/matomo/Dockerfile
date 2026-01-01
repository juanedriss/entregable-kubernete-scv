FROM matomo:latest

# Personalización básica: preparar un directorio para extensiones adicionales
RUN set -eux; \
    mkdir -p /var/www/html/plugins/ExtraExtensions

# Valores predeterminados para la configuración de PHP
ENV PHP_MEMORY_LIMIT=512M \
    PHP_UPLOAD_MAX_FILESIZE=512M \
    PHP_POST_MAX_SIZE=512M

# Generación dinámica del archivo de ajustes PHP usando variables de entorno
RUN printf '%s\n' \
"#!/bin/sh" \
"echo \"memory_limit=${PHP_MEMORY_LIMIT}\" > /usr/local/etc/php/conf.d/zzz-overrides.ini" \
"echo \"upload_max_filesize=${PHP_UPLOAD_MAX_FILESIZE}\" >> /usr/local/etc/php/conf.d/zzz-overrides.ini" \
"echo \"post_max_size=${PHP_POST_MAX_SIZE}\" >> /usr/local/etc/php/conf.d/zzz-overrides.ini" \
"exec /entrypoint.sh \"\$@\"" \
> /usr/local/bin/entrypoint-custom.sh && \
    chmod +x /usr/local/bin/entrypoint-custom.sh

ENTRYPOINT ["/usr/local/bin/entrypoint-custom.sh"]
CMD ["apache2-foreground"]

LABEL maintainer="dockerhub_user_placeholder"
