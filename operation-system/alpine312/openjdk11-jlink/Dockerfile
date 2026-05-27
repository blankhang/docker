FROM blankhang/alpine-3.12:openjdk11 as packager

##jlink
RUN /usr/lib/jvm/java-11-openjdk/bin/jlink \
	--module-path /usr/lib/jvm/java-11-openjdk/jmods \
	--verbose \
	--add-modules java.base,java.logging,java.xml,jdk.unsupported,java.sql,java.desktop,java.management,java.naming,java.instrument,jdk.jstatd,jdk.jcmd,jdk.management \
	--compress 2 \
	--no-header-files \
	--output /usr/lib/jvm/java-11-openjdk-jlinked

# copy jdk after jlink
FROM blankhang/alpine-3.12:glibc-2.32-r0
MAINTAINER blankhang <blankhang@gmail.com>
COPY --from=packager /usr/lib/jvm/java-11-openjdk-jlinked /usr/lib/jvm/java-11-openjdk
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk
ENV PATH=$JAVA_HOME/bin:$PATH