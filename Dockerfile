from cirquare/base

MAINTAINER Zafar Ali

# Set locales
RUN locale-gen en_GB.UTF-8 en_US.UTF-8
ENV LANG en_GB.UTF-8
#ENV TOMCAT_VERSION=8.5.31
# see https://www.apache.org/dist/tomcat/tomcat-$TOMCAT_MAJOR/KEYS
# see also "update.sh" (https://github.com/docker-library/tomcat/blob/master/update.sh)
ENV TOMCAT_MAJOR 8
ENV TOMCAT_VERSION 8.5.31
ENV TOMCAT_SHA512 a961eedc4b0c0729f1fb96dafb75eb48e000502233b849f47c84a6355873bc96d131b112400587e96391262e0659df9b991b4e66a78fda74168f939c4ab5af88
ENV CATALINA_OPTS="-Xmx2048m -server"
ENV CATALINA_HOME /opt/tomcat
ENV PATH $PATH:$CATALINA_HOME/bin
# let "Tomcat Native" live somewhere isolated
ENV TOMCAT_NATIVE_LIBDIR $CATALINA_HOME/native-jni-lib
ENV LD_LIBRARY_PATH ${LD_LIBRARY_PATH:+$LD_LIBRARY_PATH:}$TOMCAT_NATIVE_LIBDIR
ENV TOMCAT_TGZ_URL https://www.apache.org/dist/tomcat/tomcat-$TOMCAT_MAJOR/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz
ENV TOMCAT_SHA512 a961eedc4b0c0729f1fb96dafb75eb48e000502233b849f47c84a6355873bc96d131b112400587e96391262e0659df9b991b4e66a78fda74168f939c4ab5af88
ENV OPENSSL_VERSION 1.1.0f-3+deb9u2
ENV KEYSTORE_PASSWORD password
RUN apt-get update && \
	apt-get install -y --allow-unauthenticated --no-install-recommends dpkg-dev gcc libapr1-dev libssl-dev make


RUN set -ex; \
		if dpkg --compare-versions "$currentVersion" '<<' "$OPENSSL_VERSION"; then \
			if ! grep -q stretch /etc/apt/sources.list; then \
	# only add stretch if we're not already building from within stretch
				{ \
					echo 'deb http://deb.debian.org/debian stretch main'; \
					echo 'deb http://security.debian.org stretch/updates main'; \
					echo 'deb http://deb.debian.org/debian stretch-updates main'; \
				} > /etc/apt/sources.list.d/stretch.list; \
				{ \
	# add a negative "Pin-Priority" so that we never ever get packages from stretch unless we explicitly request them
					echo 'Package: *'; \
					echo 'Pin: release n=stretch*'; \
					echo 'Pin-Priority: -10'; \
					echo; \
	# ... except OpenSSL, which is the reason we're here
					echo 'Package: openssl libssl*'; \
					echo "Pin: version $OPENSSL_VERSION"; \
					echo 'Pin-Priority: 990'; \
				} > /etc/apt/preferences.d/stretch-openssl; \
			fi; \
			apt-get update; \
			apt-get install -y --allow-unauthenticated --no-install-recommends openssl="$OPENSSL_VERSION"; \
			rm -rf /var/lib/apt/lists/*; \
		fi
			
RUN apt-get update && apt-get install -y --allow-unauthenticated --no-install-recommends \
		libapr1 \
	&& rm -rf /var/lib/apt/lists/*

# see https://www.apache.org/dist/tomcat/tomcat-8/KEYS
ENV GPG_KEYS 05AB33110949707C93A279E3D3EFE6B686867BA6 07E48665A34DCAFAE522E5E6266191C37C037D42 47309207D818FFD8DCD3F83F1931D684307A10A5 541FBE7D8F78B25E055DDEE13C370389288584E7 61B832AC2F1C5A90F0F9B00A1C506407564C17A3 713DA88BE50911535FE716F5208B0AB1D63011C7 79F7026C690BAA50B92CD8B66A3AD3F4F22C4FED 9BA44C2621385CB966EBA586F72C284D731FABEE A27677289986DB50844682F8ACB77FC2E86E29AC A9C5DF4D22E99998D9875A5110C01C5A2F6059E7 DCFD35E0BF8CA7344752DE8B6FB21E8933C60243 F3A04C595DB5B6A5F1ECA43E3B7BBB100D811BBE F7DA48BB64BCB84ECBA7EE6935CD23C10D498E23

ENV TOMCAT_TGZ_URLS \
# https://issues.apache.org/jira/browse/INFRA-8753?focusedCommentId=14735394#comment-14735394
	https://www.apache.org/dyn/closer.cgi?action=download&filename=tomcat/tomcat-$TOMCAT_MAJOR/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz \
# if the version is outdated, we might have to pull from the dist/archive :/
	https://www-us.apache.org/dist/tomcat/tomcat-$TOMCAT_MAJOR/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz \
	https://www.apache.org/dist/tomcat/tomcat-$TOMCAT_MAJOR/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz \
	https://archive.apache.org/dist/tomcat/tomcat-$TOMCAT_MAJOR/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz

ENV TOMCAT_ASC_URLS \
	https://www.apache.org/dyn/closer.cgi?action=download&filename=tomcat/tomcat-$TOMCAT_MAJOR/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz.asc \
# not all the mirrors actually carry the .asc files :'(
	https://www-us.apache.org/dist/tomcat/tomcat-$TOMCAT_MAJOR/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz.asc \
	https://www.apache.org/dist/tomcat/tomcat-$TOMCAT_MAJOR/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz.asc \
	https://archive.apache.org/dist/tomcat/tomcat-$TOMCAT_MAJOR/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz.asc

# Download and Verify Apache Tomcat
RUN set -eux; \
	apt-get update; \
	\
	apt-get install -y --allow-unauthenticated --no-install-recommends gnupg dirmngr; \
	\
	export GNUPGHOME="$(mktemp -d)"; \
	for key in $GPG_KEYS; do \
		gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
	done; \
	\
	apt-get install -y --allow-unauthenticated --no-install-recommends wget ca-certificates; \
	for url in $TOMCAT_TGZ_URLS; do \
		if wget -O tomcat.tar.gz "$url"; then \
			success=1; \
			break; \
		fi; \
	done; \
	[ -n "$success" ]; \
	\
	echo "$TOMCAT_SHA512 *tomcat.tar.gz" | sha512sum -c -; \
	\
	success=; \
	for url in $TOMCAT_ASC_URLS; do \
		if wget -O tomcat.tar.gz.asc "$url"; then \
			success=1; \
			break; \
		fi; \
	done; \
	[ -n "$success" ]; \
	\
	gpg --batch --verify tomcat.tar.gz.asc tomcat.tar.gz; \
	rm -rf "$GNUPGHOME";

RUN mkdir -p $CATALINA_HOME
RUN tar -xvf tomcat.tar.gz -C $CATALINA_HOME --strip-components=1 && \
	rm $CATALINA_HOME/bin/*.bat && \
	rm tomcat.tar.gz*

RUN ls $CATALINA_HOME

RUN set -eux; \
	\	
	nativeBuildDir="$(mktemp -d)"; \
	tar -xvf $CATALINA_HOME/bin/tomcat-native.tar.gz -C "$nativeBuildDir" --strip-components=1; \
	( \
		cd "$nativeBuildDir/native"; \
		gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)"; \
		./configure \
			--build="$gnuArch" \
			--libdir="$TOMCAT_NATIVE_LIBDIR" \
			--prefix="$CATALINA_HOME" \
			--with-apr="$(which apr-1-config)" \
			--with-java-home=$JAVA_HOME \
			--with-ssl=yes; \
		make -j "$(nproc)"; \
		make install; \
	); \
	rm -rf "$nativeBuildDir"; \
	rm $CATALINA_HOME/bin/tomcat-native.tar.gz

ADD *.cer $CATALINA_HOME
WORKDIR $CATALINA_HOME

COPY conf/server.xml ${CATALINA_HOME}/conf/
COPY conf/tomcat-users.xml ${CATALINA_HOME}/conf/
COPY conf/Catalina/localhost/manager.xml ${CATALINA_HOME}/conf/Catalina/localhost
COPY conf/Catalina/localhost/host-manager.xml ${CATALINA_HOME}/conf/Catalina/localhost

RUN sed -i "s/KEYSTORE_PASSWORD_PLACEHOLDER/${KEYSTORE_PASSWORD}/g" ${CATALINA_HOME}/conf/server.xml

        ${CATALINA_HOME}/conf/server.xml && \
RUN keytool -noprompt -genkey -alias cirquare -dname "CN=cirquare.co.uk, OU=Cirquare Ltd, O=Cirquare Ltd, L=Birmingham, S=West Midlands, C=UK" \
	 -keystore $CATALINA_HOME/cirquare.p12  -deststoretype pkcs12 -storepass $KEYSTORE_PASSWORD -KeySize 2048 -keypass $KEYSTORE_PASSWORD -keyalg RSA && \
	keytool -exportcert -keystore $CATALINA_HOME/cirquare.p12 -storepass $KEYSTORE_PASSWORD -alias cirquare -rfc -file cirquare-public-certificate.pem
	
EXPOSE 8080 8443
CMD ["/opt/tomcat/bin/catalina.sh", "run"]

#-Djava.security.egd=file:/dev/./urandom