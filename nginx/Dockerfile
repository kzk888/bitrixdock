FROM nginx:1.18

ADD conf/nginx.conf /etc/nginx/
COPY conf/conf.d/ /etc/nginx/conf.d/

RUN usermod -u 1000 www-data

CMD ["nginx"]

EXPOSE 80 443
