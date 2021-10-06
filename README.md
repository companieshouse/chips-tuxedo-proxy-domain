# chips-tuxedo-proxy-domain
Docker build for chips-tuxedo-proxy WebLogic domain


## chips-tuxedo-proxy-domain
This build extends the ch-weblogic image and adds a WebLogic domain configuration for the Companies House Information Processing System (CHIPS) tuxedo proxy application.  The image produced by this build can be run, but it is not of practical value and is designed to be further extended by the chips-tuxedo-proxy-app build/image.

The domain is simple and comprises:
 - Administration server - (intended to run in wladmin container)
 - One managed server & nodemanager - (intended to run in wlserver1 container)

### Building the image
To build the image, from the root of the repo run:

    docker build -t chips-tuxedo-proxy-domain --build-arg ADMIN_PASSWORD=security123 .

**Important** The arg ADMIN_PASSWORD sets the administrator password that is used in the built image.  The password can easily be discovered simply by running `docker history chips-tuxedo-proxy-domain` Therefore, the password must be reset, along with other sensitive credentials when the image is actually used to start containers. That reset is handled automtically by the start scripts.

### Run time environment properties file
In order to use the image, a number of environment properties need to be defined in a file, held locally to where the docker command is being run - for example, `chips.properties` 
|Property|Description  |Example
|--|--|--
|ADMIN_PASSWORD |The password to set for the weblogic user.  Needs to be at least 8 chars and include a number.|secret123
|DOMAIN_CREDENTIAL|A random string to override and reset the default credential already present in the image.|kjsdgf5464fdva
|LDAP_CREDENTIAL|A random string to override and reset the default credential already present in the image.|ldap01234
|START_ARGS|Any startup JVM arguments that should be used when starting the managed server|-Dmyarg=true -Dmyotherarg=false
|USER_MEM_ARGS|JVM arguments for setting the GC and memory settings for the managed server.  These will be included at the start of the arguments to the JVM|-XX:+UseG1GC -verbose:gc -XX:+PrintGCDetails -XX:+PrintGCDateStamps -Xms712m -Xmx712m
|ADMIN_MEM_ARGS|JVM arguments for setting the GC and memory settings for the admin server.  These will be included at the start of the arguments to the JVM|-Djava.security.egd=file:/dev/./urandom -Xms32m -Xmx512m
|AUTO_START_NODES|A list of managed server names to auto start when the container is launched|wlserver1
|TZ|The timezone to use when running WebLogic|Europe/London

## docker-compose
docker-compose can be used to start all the required containers in one operation.

It uses the docker-compose.yml file included in the repository to start up the following:
- WebLogic Administration server container
- One managed server/nodemanager container

### Preparing for running

The following steps should be taken before first starting the containers with docker-compose

#### Environment variables
In order to configure which version of the images to use when starting, there is an environment variable that can be set:
|ENV VAR  | Description | Example| Default
|--|--|--|--
|CHIPS_TUXEDO_PROXY_DOMAIN_IMAGE  |The image repository and version to use for the chips-tuxedo-proxy-domain image  |12345678910.dkr.ecr.eu-west-2.amazonaws.com/chips-domain:1.0|chips-tuxedo-proxy-domain (latest local image)

#### Properties file for application
In addition, the chips.properties file described under "Run time environment properties file" also needs to be present.

#### running-servers directory
Finally, the WebLogic managed server work directories are made available to, and persisted, on the host via a bind mount to a local directory.  To create the directory run the following in the root of the checked out repository:

    mkdir -p running-servers

### Starting up
The following command, executed from the root of the repo,  can be used to start up all the containers required to run the CIC service:

    docker-compose up -d


### Accessing the Administration server
After starting the containers, the Administration server console will be available on http://127.0.0.1:21010/console on the host.  You can login with the user `weblogic` and the password you set for `ADMIN_PASSWORD`in the properties file.

### Starting the Managed server 
The managed server container will be running Node Manager, which can then be used to start up the managed server instance inside the container using the Administration console.  If the `AUTO_START_NODES` property is used, the server listed will be started automatically.