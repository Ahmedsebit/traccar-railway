#!/bin/sh
set -eu

exec /opt/traccar/jre/bin/java \
  -XX:+ExitOnOutOfMemoryError \
  -Xms256m \
  -Xmx512m \
  -jar /opt/traccar/tracker-server.jar \
  /opt/traccar/conf/traccar.xml
