#!/bin/bash
set -e
MYID=$(id -u)
CONTROL=/usr/sbin/rabbitmqctl
#SERVER=/usr/sbin/rabbitmq-server
SERVER=/usr/lib/rabbitmq/bin/rabbitmq-server
export RABBITMQ_PID_FILE=/data/rabbitmq.pid

function die {
  echo ERROR: "$@"
  exit 1
}

if [ ! -x "$CONTROL" ]; then
  die "can't find $CONTROL!"
fi

if [ ! -x "$SERVER" ]; then
  die "can't find $SERVER!"
fi

if [ "$MYID" != "0" ]; then
  die "rabbitmq startup script must be executed as root!"
fi

function remove_pid {
  echo "INFO: REMOVING PIDFILE"
  rm -f "$RABBITMQ_PID_FILE"
}

function stop_rabbitmq {
  echo "INFO: STOPPING RABBITMQ"
  if [ -f "$RABBITMQ_PID_FILE" ]; then
    set +e
    $CONTROL stop "$RABBITMQ_PID_FILE"
    set -e
    if [ $? = 0 ] ; then
      remove_pid
    else
      echo "WARN: RABBITMQ FAILED TO STOP!"
    fi
  fi
}

function start_rabbitmq {
  ulimit -n 1024
  chown -R rabbitmq:rabbitmq /data
  rm -f "$RABBITMQ_PID_FILE"

  gosu rabbitmq $SERVER "$@" &
  $CONTROL wait "$RABBITMQ_PID_FILE" >/dev/null 2>&1
  set -e
  if [ $? != 0 ] ; then
    echo "ERROR: RABBITMQ FAILED TO START!"
    remove_pid
  fi
}

trap "stop_rabbitmq" SIGINT SIGTERM

start_rabbitmq

while [ -f "$RABBITMQ_PID_FILE" ]; do
  sleep 0.25
done
echo "all done!"
