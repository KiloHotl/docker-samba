FROM alpine:latest

ENV TZ="UTC"

RUN apk --update --no-cache add \
    bash \
    coreutils \
    jq \
    samba \
    shadow \
    tzdata \
    yq \
  && rm -rf /tmp/*

COPY entrypoint.sh /entrypoint.sh

EXPOSE 445/tcp 139/tcp 137/udp 138/udp

VOLUME [ "/data" ]

ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "smbd", "-F", "--debug-stdout", "--no-process-group" ]

HEALTHCHECK --interval=30s --timeout=10s \
  CMD smbclient -L \\localhost -U % -m SMB3
