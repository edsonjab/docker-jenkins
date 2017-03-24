#!/bin/bash
#script que genera un respaldo de las bases de datos
#pg_dump -i -h localhost --username=username -F c -b -v -f latest_db.dmp nombre_db
#mongodump --host localhost --port 27017 --db dgm --username admin --password admin --out /opt/dump
for line in $(cat databases);
  do
    PROPERTY="$(cut -d'=' -f1 <<<"$line")"
    VALUE="$(cut -d'=' -f2 <<<"$line")"

    case $PROPERTY in
      "bd")
        BD=$VALUE
      ;;
      "host")
        HOST=$VALUE
      ;;
      "port")
        PORT=$VALUE
      ;;
      "schema")
        SCHEMA=$VALUE
      ;;
      "user")
        USER=$VALUE
      ;;
      "pass")
        PASS=$VALUE
      ;;
      *)
        if [ $BD != "" -a $USER != "" ]; then
          #Se construye la Fecha para el nombre
          DIA=$(date +"%d")
          MES=$(date +"%m")
          ANIO=$(date +"%y")
          HORA=$(date +"%H")
          MINUTO=$(date +"%M")
          NOMBRE="$HOST"_"$SCHEMA"_"$DIA$MES$ANIO$HORA$MINUTO"
          if [ $BD == "postgres" ]; then
              echo "pg_dump -h $HOST --username=$USER -F c -b -v -f $NOMBRE.dmp $SCHEMA"
          else
            if [ $USER == "" ]; then
              echo "mongodump --host $HOST --port $PORT --db $SCHEMA --out /opt/dump/$NOMBRE"
            else
              echo "mongodump --host $HOST --port $PORT --db $SCHEMA --username $USER --password $PASS --out /opt/dump/$NOMBRE"
            fi
          fi
        fi
      ;;
    esac
done
