FROM ubuntu:22.04

RUN apt update -y && apt install -y curl

COPY config /opt/todo
WORKDIR /opt/todo

CMD ["./setup.sh"]