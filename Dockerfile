FROM tomcat:9-alpine
MAINTAINER Gustavo Oliveira <cetres@gmail.com>

ENV JS_HOME=/opt/jrs \
    JS_VERSION=6.4.2 \
    JS_DB_TYPE=mysql \
    JS_DB_HOST=jasper.db \
    JS_DB_PORT=3306 \
    JS_DB_USER=jasper \
    JS_DB_PASSWORD=my_password

RUN  wget -qO /tmp/jrs.zip http://downloads.sourceforge.net/project/jasperserver/JasperServer/JasperReports%20Server%20Community%20Edition%20${JS_VERSION}/TIB_js-jrs-cp_${JS_VERSION}_bin.zip

COPY entrypoint.sh /

RUN rm -fr /usr/local/tomcat/webapps/{examples,docs} && \
    apk update && \
    apk add openjdk8 && \
    mkdir -p ${JS_HOME} && \
    unzip -q /tmp/jrs.zip -d ${JS_HOME}/ && \
    mv -v ${JS_HOME}/jasperreports-server-cp-${JS_VERSION}-bin/* ${JS_HOME}/ && \
    rmdir ${JS_HOME}/jasperreports-server-cp-${JS_VERSION}-bin && \
    rm -f /tmp/jrs.zip && \
    chmod a+x /entrypoint.sh && \
    chmod -R g+w ${JS_HOME}

EXPOSE 8080

CMD ["/entrypoint.sh"]