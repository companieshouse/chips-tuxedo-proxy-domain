FROM 300288021642.dkr.ecr.eu-west-2.amazonaws.com/ch-weblogic:1.5.1

# IMPORTANT - the default admin password should be supplied as a build arg
# e.g. --build-arg ADMIN_PASSWORD=notsecure123.  This password will be visible in the image
# so MUST later be reset to a secure value when starting the admin container.
ARG ADMIN_PASSWORD

ENV ORACLE_HOME=/apps/oracle \
    DOMAIN_NAME=chipsdomain \
    ADMIN_NAME=wladmin \
    ARTIFACTORY_BASE_URL=http://repository.aws.chdev.org:8081/artifactory

WORKDIR $ORACLE_HOME

# Copy over utility scripts for creating the domain, setting security and starting servers
COPY --chown=weblogic:weblogic container-scripts container-scripts/

# Initialise the domain using a standard template provided with WebLogic
RUN $ORACLE_HOME/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning container-scripts/create-domain.py 

# Copy across a custom config.xml
COPY --chown=weblogic:weblogic config ${DOMAIN_NAME}/config/

# Copy across chipsconfig directory
COPY --chown=weblogic:weblogic chipsconfig ${DOMAIN_NAME}/chipsconfig/

# Download libs from artifactory
RUN cd ${DOMAIN_NAME}/chipsconfig && \
    curl ${ARTIFACTORY_BASE_URL}/libs-release/log4j/log4j/1.2.14/log4j-1.2.14.jar -o log4j.jar

# Set the credentials in the custom config.xml
RUN $ORACLE_HOME/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning container-scripts/set-credentials.py && \
    chmod 754 container-scripts/*.sh

# Modify the umask setting in the WebLogic start scripts
RUN sed -i 's/umask 027/umask 022/' ${DOMAIN_NAME}/bin/startWebLogic.sh && \
    sed -i 's/umask 027/umask 022/' ${ORACLE_HOME}/wlserver/server/bin/startNodeManager.sh

USER weblogic
CMD ["bash"]


