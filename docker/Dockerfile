FROM debian:buster

# The bedrock_server executable needs this set
ENV LD_LIBRARY_PATH=.
ENV bedrock_version=1.14.32.1

RUN apt-get update && apt-get install -y \
      curl

RUN curl -o bedrock_server.zip 'https://minecraft.azureedge.net/bin-linux/bedrock-server-1.14.32.1.zip' \
    && unzip bedrock_server.zip

COPY server.properties server.properties
COPY whitelist.json whitelist.json

CMD ["./bedrock_server"]
