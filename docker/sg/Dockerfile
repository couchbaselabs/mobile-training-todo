FROM ubuntu:22.04

ARG SG_DEB
RUN [ -z "$SG_DEB" ] && echo "SG_DEB is required" && exit 1 || true

COPY config /opt/todo
COPY $SG_DEB /opt/todo/couchbase-sync-gateway.deb

WORKDIR /opt/todo
RUN mkdir -p logs

RUN apt -yqq update 
RUN apt -yqq install systemctl curl
RUN apt -yqq install ./couchbase-sync-gateway.deb

EXPOSE 4984
EXPOSE 4985

CMD ["./run.sh", "booststrap.json", "/opt/todo/logs"]
