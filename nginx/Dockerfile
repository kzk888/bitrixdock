FROM nginx:1.18

ADD conf/nginx.conf /etc/nginx/
COPY conf/conf.d/ /etc/nginx/conf.d/

RUN apt-get update -y > /dev/null 2>&1 && apt install python-certbot-nginx -y > /dev/null 2>&1
RUN usermod -u 1000 www-data

CMD ["nginx"]

EXPOSE 80 443
