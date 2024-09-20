FROM docker.io/library/node:21-alpine AS deemix

RUN apk add --no-cache git jq python3 make gcc musl-dev g++ && \
    rm -rf /var/lib/apt/lists/* && \
    git clone --recurse-submodules https://gitlab.com/RemixDev/deemix-gui.git
WORKDIR deemix-gui
RUN jq '.pkg.targets = ["node16-alpine-x64"]' ./server/package.json > tmp-json && \
    mv tmp-json /deemix-gui/server/package.json && \
    yarn install-all && \
    sed -i 's/const channelData = await dz.gw.get_page(channelName)/let channelData; try { channelData = await dz.gw.get_page(channelName); } catch (error) { console.error(`Caught error ${error}`); return [];}/' ./server/src/routes/api/get/newReleases.ts && \
    yarn dist-server && \
    mv /deemix-gui/dist/deemix-server /deemix-server

FROM docker.io/library/node:21-alpine

ENV DEEMIX_SINGLE_USER=true
ENV AUTOCONFIG=true
ENV CLEAN_DOWNLOADS=true
ENV PUID=1000
ENV PGID=1000

# deemix
COPY --from=deemix /deemix-server /deemix-server
RUN chmod +x /deemix-server
VOLUME ["/config", "/data/deemix"]

# arl-watch
RUN apk add --no-cache inotify-tools && \
    rm -rf /var/lib/apt/lists/*

COPY root /
RUN chmod +x /etc/services.d/*/run && \
    chmod +x /usr/local/bin/*.sh

EXPOSE 6595
