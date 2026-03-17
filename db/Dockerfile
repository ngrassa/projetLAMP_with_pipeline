FROM mariadb:11

LABEL version="1.0"
LABEL owner="RSI21"

ENV MARIADB_ROOT_PASSWORD=rootpassword
ENV MARIADB_DATABASE=articlesdb
ENV MARIADB_USER=rsiuser
ENV MARIADB_PASSWORD=rsipass

# Tout fichier .sql placé ici est exécuté automatiquement à l'init
COPY articles.sql /docker-entrypoint-initdb.d/articles.sql

EXPOSE 3306
