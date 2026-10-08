FROM traccar/traccar:latest

WORKDIR /opt/traccar

COPY traccar.xml /opt/traccar/conf/traccar.xml

# Tracker port (Coban / gps103 protocol) and web/API port
EXPOSE 5001 8082

# Overrides the image default, which forces IPv4 only (-Djava.net.preferIPv4Stack=true)
# and that can break Railway private networking. Memory sized for a small Railway service.
CMD ["java", "-Xms256m", "-Xmx512m", "-jar", "tracker-server.jar", "conf/traccar.xml"]
