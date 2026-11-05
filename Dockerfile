FROM php:8.4-apache

# Устанавливаем надежный установщик расширений PHP
COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/

# Устанавливаем системные зависимости и расширения для Symfony и PostgreSQL
RUN apt-get update && apt-get install -y \
    zip \
    unzip \
    git \
    && install-php-extensions intl opcache pdo pdo_pgsql zip

# Включаем mod_rewrite для работы роутинга Symfony
RUN a2enmod rewrite

# Настраиваем Apache на папку public
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Устанавливаем Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Копируем проект в контейнер
WORKDIR /var/www/html
COPY . .

# Разрешаем запуск Composer от суперпользователя и ставим зависимости
ENV APP_ENV=prod
ENV COMPOSER_ALLOW_SUPERUSER=1
RUN composer install --no-dev --optimize-autoloader

# Выставляем права для кэша и логов Symfony
RUN chown -R www-data:www-data /var/www/html/var

EXPOSE 80
