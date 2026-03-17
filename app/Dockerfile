FROM debian:stable-slim
LABEL version="1.0"
LABEL owner="RSI21"

RUN apt-get update && \
    apt-get install -y apache2 php php-mysql && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY .  /var/www/html/
RUN rm -f /var/www/html/index.html

EXPOSE 80
CMD ["apache2ctl", "-D", "FOREGROUND"]
