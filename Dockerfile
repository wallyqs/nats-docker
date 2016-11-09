FROM registry.access.redhat.com/rhel7

LABEL Name="nats" \
      Vendor="NATS Messaging " \
      Version="0.9.4" \
      Release="1" \
      build-date="2016-11-09T19:39:22.821216Z" \
      url="https://nats.io" \
      summary="NATS: A high-performance cloud native messaging system." \
      description="nats is a high performance server for the NATS Messaging System." \
      RUN='docker run -tdi --name ${NAME} \
      ${IMAGE}' \
      STOP='docker stop ${NAME}'

### Atomic Help File - Write in Markdown, it will be converted to man format at build time.
### https://github.com/projectatomic/container-best-practices/blob/master/creating/help.adoc
COPY help.md /

RUN yum clean all && \
    yum-config-manager --disable \* && \
    yum-config-manager --enable rhel-7-server-rpms && \
    yum-config-manager --enable rhel-7-server-optional-rpms && \
### Add additional Red Hat repos
    yum -y update-minimal --security --sec-severity=Important --sec-severity=Critical --setopt=tsflags=nodocs && \
### Help markdown to man conversion
    yum -y install golang-github-cpuguy83-go-md2man && go-md2man -in help.md -out help.1 && \
    yum -y remove golang-github-cpuguy83-go-md2man && rm -f help.md && \
    yum clean all

### Setup the user that is used for the build execution and for the application runtime execution by default.
ENV APP_ROOT=/opt/app-root \
    USER_NAME=nats \
    USER_UID=10001
ENV APP_HOME=${APP_ROOT}/src \
    PATH=$PATH:${APP_ROOT}/bin
RUN mkdir -p ${APP_HOME} ${APP_ROOT}/bin ${APP_ROOT}/conf && \
    useradd -l -u ${USER_UID} -r -g 0 -d ${APP_ROOT} -s /sbin/nologin \
            -c "${USER_NAME} application user" ${USER_NAME}

### Add gnatsd binary itself
COPY gnatsd ${APP_ROOT}/bin/gnatsd
COPY gnatsd.conf ${APP_ROOT}/conf/gnatsd.conf
RUN chown -R ${USER_UID}:0 ${APP_ROOT} && \
    chmod -R g+rw ${APP_ROOT} && \
    chmod ug+x ${APP_ROOT}/bin/gnatsd && \
    find ${APP_ROOT} -type d -exec chmod g+x {} +

### Containers should NOT run as root as a best practice
USER ${USER_UID}
WORKDIR ${APP_ROOT}

# Expose client, management, and cluster ports
EXPOSE 4222 8222 6222

# Run via the configuration file
ENTRYPOINT ["/gnatsd", "-c", "/gnatsd.conf"]
CMD []
