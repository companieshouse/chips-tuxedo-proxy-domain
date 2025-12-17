FROM 300288021642.dkr.ecr.eu-west-2.amazonaws.com/ch-weblogic:2.0.0 AS builder

# IMPORTANT - the default admin password should be supplied as a build arg
# e.g. --build-arg ADMIN_PASSWORD=notsecure123.  This password MUST later be reset
# to a secure value when starting the admin container.
# The ARGS are not retained in the final image, due to using a multi-stage build.
ARG ADMIN_PASSWORD
ARG ARTIFACTORY_URL
ARG ARTIFACTORY_USERNAME
ARG ARTIFACTORY_PASSWORD

ENV DOMAIN_NAME=chipsdomain
ENV DOMAIN_HOME=${ORACLE_HOME}/${DOMAIN_NAME} \
    ADMIN_NAME=wladmin \
    ARTIFACTORY_BASE_URL=${ARTIFACTORY_URL}/virtual-release

WORKDIR ${ORACLE_HOME}

# Copy over container scripts for creating the domain, setting security and starting servers
COPY --chown=weblogic container-scripts container-scripts/

# Initialise the domain using a standard template provided with WebLogic
RUN ${ORACLE_HOME}/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning container-scripts/create-domain.py 

# Copy across a custom config.xml
COPY --chown=weblogic config ${DOMAIN_HOME}/config/

# Set the credentials in the custom config.xml
RUN ${ORACLE_HOME}/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning container-scripts/set-credentials.py

# Copy across chipsconfig directory
COPY --chown=weblogic chipsconfig ${DOMAIN_HOME}/chipsconfig/

# Download libs from artifactory
RUN cd ${DOMAIN_NAME}/chipsconfig && \
    curl -L -u "${ARTIFACTORY_USERNAME}:${ARTIFACTORY_PASSWORD}" ${ARTIFACTORY_BASE_URL}/log4j/log4j/1.2.14/log4j-1.2.14.jar -o log4j.jar && \
    curl -L -u "${ARTIFACTORY_USERNAME}:${ARTIFACTORY_PASSWORD}" ${ARTIFACTORY_BASE_URL}/uk/gov/companieshouse/weblogic-tux-hostname-patch/1.0.0/weblogic-tux-hostname-patch-1.0.0.jar -o weblogic-tux-hostname-patch-1.0.0.jar && \
    curl -L -u "${ARTIFACTORY_USERNAME}:${ARTIFACTORY_PASSWORD}" ${ARTIFACTORY_BASE_URL}/uk/gov/companieshouse/weblogic-tux-hostname-patch/2.0.0/weblogic-tux-hostname-patch-2.0.0.jar -o weblogic-tux-hostname-patch-2.0.0.jar

FROM 300288021642.dkr.ecr.eu-west-2.amazonaws.com/ch-weblogic:2.0.0

ENV DOMAIN_NAME=chipsdomain
ENV DOMAIN_HOME=${ORACLE_HOME}/${DOMAIN_NAME} \
    ADMIN_NAME=wladmin

# Copy over domain directory from builder stage
COPY --from=builder --chown=weblogic ${DOMAIN_HOME} ${DOMAIN_HOME}/

# Copy over container scripts from builder stage
COPY --from=builder --chown=weblogic ${ORACLE_HOME}/container-scripts ${ORACLE_HOME}/container-scripts/

# Modify the umask setting in the WebLogic start scripts
RUN sed -i 's/umask 027/umask 022/' ${DOMAIN_NAME}/bin/startWebLogic.sh && \
    sed -i 's/umask 027/umask 022/' ${ORACLE_HOME}/wlserver/server/bin/startNodeManager.sh

CMD ["bash"]


