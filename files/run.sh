#!/bin/bash
#set -e
MYSQL_SOCK=${MYSQL_SOCK:-"/tmp/mysql.sock"}

MYSQL_DATABASE=${MYSQL_DATABASE:-""}
MYSQL_USER=${MYSQL_USER:-""}
MYSQL_PASSWORD=${MYSQL_PASSWORD:-""}

MYSQL_IMPORT=${MYSQL_IMPORT:-""}
MYSQL_IMPORT_SQL=${MYSQL_IMPORT_SQL:-""}

MYSQL_USE_SLOW_QUERY=${MYSQL_USE_SLOW_QUERY:-"false"}
MYSQL_SLOW_QUERY_TIME=${MYSQL_SLOW_QUERY_TIME:-"1"}
MYSQL_SLOW_QUERY_FILE=${MYSQL_SLOW_QUERY_FILE:-"/var/log/mysql/slow.log"}

VOLUME_HOME="/var/lib/mysql"

if [ ! -z "$MYSQL_SOCK" ] ; then
    sed -i -e "s|.*socket=.*|socket=${MYSQL_SOCK}|g" /etc/mysql/my.cnf
fi

if [[ ! -f /var/run/mysqld/mysqld.pid ]]; then
    mkdir -p /var/run/mysqld
    chown -R mysql:mysql /var/run/mysqld

fi

ln -sf /tmp/mysql.sock /var/lib/mysql/mysql.sock



chown -R mysql:mysql $VOLUME_HOME

extend_conf_dir="/etc/my.cnf.d"
mkdir -p $extend_conf_dir

if [[ $MYSQL_USE_SLOW_QUERY == "true" ]]; then
  echo "[mysqld]" > $extend_conf_dir/slow.cnf
  echo "slow_query_log=1" >> $extend_conf_dir/slow.cnf
  echo "slow_query_log_file=${MYSQL_SLOW_QUERY_FILE}" >> $extend_conf_dir/slow.cnf
  echo "long_query_time=${MYSQL_SLOW_QUERY_TIME}" >> $extend_conf_dir/slow.cnf
  chown -R mysql:mysql $extend_conf_dir
fi

if [[ ! -d $VOLUME_HOME/mysql ]]; then

echo "=> An empty or uninitialized MariaDB volume is detected in $VOLUME_HOME"
echo "=> Installing MariaDB ..."
mysql_install_db > /dev/null 2>&1
echo "=> Done!"

chown -R mysql:mysql $VOLUME_HOME

PASS=${MYSQL_ROOT_PASSWORD:-$(cat /dev/urandom | tr -cd 'a-f0-9' | head -c 8)}
_word=$( [ ${MYSQL_ROOT_PASSWORD} ] && echo "user defined" || echo "a random" )

echo "=> Creating MariaDB root user with ${_word} password"
/usr/sbin/mysqld > /dev/null 2>&1 &
sleep 5

tfile=`mktemp`
if [[ ! -f "$tfile" ]]; then
    return 1
fi
cat << EOF > $tfile
USE mysql;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '$PASS';
FLUSH PRIVILEGES;
EOF
if [[ $MYSQL_DATABASE != "" ]]; then
    echo "CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\` CHARACTER SET utf8 COLLATE utf8_general_ci;" >> $tfile
    if [[ $MYSQL_USER != "" ]]; then
        echo "GRANT ALL ON \`$MYSQL_DATABASE\`.* to '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';" >> $tfile
    fi
fi
mysql < $tfile
cat $tfile
echo $tfile

rm -f $tfile

if [[ $MYSQL_DATABASE != "" ]]; then
	echo "=> Creating a database called '$MYSQL_DATABASE'"
    if [[ $MYSQL_USER != "" ]]; then
		echo "=> Adding user '$MYSQL_USER' with a password of '$MYSQL_PASSWORD'"
    fi
fi

if [[ $MYSQL_IMPORT != "" ]]; then
	echo "=> [CURL] Importing database a database called to '$MYSQL_DATABASE'"
	curl -s $MYSQL_IMPORT -o yt-schema.gz ; gzip -f -d yt-schema.gz
	mysql -u root $MYSQL_DATABASE < /root/schema.sql
fi

if [[ $MYSQL_IMPORT_SQL != "" ]]; then
    echo "=> [SQL] Importing database a database called to '$MYSQL_DATABASE'"
    echo $MYSQL_IMPORT_SQL > temp.sql
    mysql -uroot $MYSQL_DATABASE < temp.sql;
fi

kill %1 > /dev/null 2>&1
sudo -u mysql pkill mysqld > /dev/null 2>&1
wait

else
    echo "=> Using an existing volume of MariaDB"
fi

echo "=> Done!"
echo "========================================================================"
echo "You can now connect to this MariaDB Server using:"
echo ""
echo "    mysql -uroot -p$PASS -h<host> -P<port> --protocol=TCP"
if [[ $MYSQL_USER != "" ]]; then
echo ""
echo " or:"
echo ""
echo "    mysql -u$MYSQL_USER -p$MYSQL_PASSWORD -h<host> -P<port> --protocol=TCP"
fi
if [[ $MYSQL_IMPORT != "" ]]; then
echo ""
echo "    Imported SQL to called to '$MYSQL_DATABASE'"
fi
echo "========================================================================"

exec mysqld_safe > /dev/null 2>&1
