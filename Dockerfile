FROM traccar/traccar:latest

USER root

RUN if command -v apk >/dev/null 2>&1; then \
        apk add --no-cache postgresql-client; \
    elif command -v apt-get >/dev/null 2>&1; then \
        apt-get update && \
        apt-get install -y --no-install-recommends postgresql-client && \
        rm -rf /var/lib/apt/lists/*; \
    else \
        echo "Unsupported base image: PostgreSQL client cannot be installed." >&2; \
        exit 1; \
    fi

WORKDIR /opt/traccar

COPY traccar.xml /opt/traccar/conf/traccar.xml
COPY init-db.sh /opt/traccar/init-db.sh
COPY start.sh /opt/traccar/start.sh

RUN chmod 755 /opt/traccar/init-db.sh /opt/traccar/start.sh

# Tracker port (Coban / gps103 protocol) and web/API port
EXPOSE 5001 8082

# Clear the base image Java entrypoint so Railway pre-deploy commands can run
# as normal executables instead of being appended as Java arguments.
ENTRYPOINT []
CMD ["/opt/traccar/start.sh"]
