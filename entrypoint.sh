#!/bin/bash
set -e
DB_TIMEOUT=30

setup_jrs() {
    JS_DB_TYPE=${JS_DB_TYPE:-mysql}
    # Allow either postgres or postgresql
    [ "$JS_DB_TYPE" = "postgres" ] && JS_DB_TYPE=postgresql
    if [ -v MYSQL_PORT_3306_TCP_ADDR ]; then
        # using link option at docker --link <mysql-container-name>:mysql
        JS_DB_HOST=${MYSQL_PORT_3306_TCP_ADDR}
    else
    	  JS_DB_HOST=${JS_DB_HOST:-jasper.db}
    fi
    JS_DB_USER=${JS_DB_USER:-jasper}
    JS_DB_PASSWORD=${JS_DB_PASSWORD:-my_password}
    # Choose the correct default port
    default_port=3306
    [ "$JS_DB_TYPE" = "postgresql" ] && default_port=5432
    JS_DB_PORT=${JS_DB_PORT:-$default_port}
    JS_ENABLE_SAVE_TO_HOST_FS=${JS_ENABLE_SAVE_TO_HOST_FS:-false}
    JS_MAIL_HOST=${JS_MAIL_HOST:-mail.example.com}
    JS_MAIL_PORT=${JS_MAIL_PORT:-25}
    JS_MAIL_PROTOCOL=${JS_MAIL_PROTOCOL:-smtp}
    JS_MAIL_USERNAME=${JS_MAIL_USERNAME:-admin}
    JS_MAIL_PASSWORD=${JS_MAIL_PASSWORD:-password}
    JS_MAIL_SENDER=${JS_MAIL_SENDER:-admin@example.com}
    JS_WEB_DEPLOYMENT_URI=${JS_WEB_DEPLOYMENT_URI:-http://localhost:8080/jasperserver}
    pushd ${JS_HOME}/buildomatic
    cat <<EOF > default_master.properties
appServerType=tomcat
appServerDir=${CATALINA_HOME}
dbType=${JS_DB_TYPE}
dbHost=${JS_DB_HOST}
dbPort=${JS_DB_PORT}
dbUsername=${JS_DB_USER}
dbPassword=${JS_DB_PASSWORD}
quartz.mail.sender.host=${JS_MAIL_HOST}
quartz.mail.sender.port=${JS_MAIL_PORT}
quartz.mail.sender.protocol=${JS_MAIL_PROTOCOL}
quartz.mail.sender.username=${JS_MAIL_USERNAME}
quartz.mail.sender.password=${JS_MAIL_PASSWORD}
quartz.mail.sender.from=${JS_MAIL_SENDER}
quartz.web.deployment.uri=${JS_WEB_DEPLOYMENT_URI}
EOF

    # DB init
    ./js-ant create-js-db init-js-db-ce import-minimal-ce || true
    for i in $@; do
        ./js-ant $i
    done

    if [ "${JS_ENABLE_SAVE_TO_HOST_FS}" = "true" ]; then
    	# Change the value of enableSaveToHostFS to true
    	sed -i "s/\(<property name=\"enableSaveToHostFS\" value=\"\).*\(\"\/>\)/\1${JS_ENABLE_SAVE_TO_HOST_FS}\2/" /usr/local/tomcat/webapps/jasperserver/WEB-INF/applicationContext.xml
    fi

    popd
}

wait_for() {
   ((t = ${DB_TIMEOUT}))
   echo -n "Waiting for database at ${JS_DB_HOST}:${JS_DB_PORT}"
   until echo > /dev/tcp/${JS_DB_HOST}/${JS_DB_PORT} 2> /dev/null; do
     echo -n "."
     ((t -= 1))
     sleep 0.5
     if ((t == 0)); then
       echo "Database not found";
       exit 1
     fi
   done
   echo " OK"
}

run_jrs() {
    wait_for
    if [ ! -d "$CATALINA_HOME/webapps/jasperserver" ]; then
        setup_jrs deploy-webapp-ce
    fi
    catalina.sh run
}

export JS_CATALINA_OPTS=${JS_CATALINA_OPTS:-"-Xmx512m -XX:MaxPermSize=256m -XX:+UseBiasedLocking -XX:BiasedLockingStartupDelay=0 -XX:+UseParNewGC -XX:+UseConcMarkSweepGC -XX:+DisableExplicitGC -XX:+CMSIncrementalMode -XX:+CMSIncrementalPacing -XX:+CMSParallelRemarkEnabled -XX:+UseCompressedOops -XX:+UseCMSInitiatingOccupancyOnly"}
run_jrs