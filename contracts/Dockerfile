FROM ghcr.io/foundry-rs/foundry:latest

USER root
RUN apk add --no-cache bash curl jq git || \
    (apt-get update && apt-get install -y --no-install-recommends bash curl jq git && rm -rf /var/lib/apt/lists/*)

WORKDIR /app
COPY . .
RUN chmod +x deploy.sh test.sh || true

