FROM debian:buster

# The bedrock_server executable needs this set
ENV LD_LIBRARY_PATH=.
ARG bedrock_version

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
      less \
      nano \
      curl \
      zip \
      unzip \
      awscli

WORKDIR /root

RUN curl -o bedrock_server.zip "https://minecraft.azureedge.net/bin-linux/bedrock-server-${bedrock_version}.zip"
RUN unzip bedrock_server.zip >/dev/null

COPY server.properties .
COPY permissions.json .
COPY whitelist.json .

EXPOSE 19132/udp 19133/udp

CMD ["./bedrock_server"]
