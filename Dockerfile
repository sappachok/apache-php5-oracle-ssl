FROM debian:jessie

MAINTAINER Thomas Bisignani <contact@thomasbisignani.com>

RUN apt-get update
RUN apt-get -y upgrade

# Install Apache2 / PHP 5.6 & Co.
RUN apt-get -y install apache2 php5 libapache2-mod-php5 php5-dev php-pear php5-curl curl libaio1 openssl \

&& echo "extension=mcrypt.so" > /etc/php5/apache2/php.ini \

# Delete downloaded data afterwards to reduce image footprint
			&& rm -rf /var/lib/apt/lists/* \
# Fix warnings
			&& echo "ServerName raceapp.nstru.ac.th" >> /etc/apache2/conf-available/raceapp.nstru.ac.th.conf && a2enconf raceapp.nstru.ac.th \
# Create self-signed SSL certificate
			&& mkdir /etc/apache2/ssl \
			&& openssl req \
				-x509 \
				-nodes \
				-days 365 \
				-newkey rsa:2048 \
				-keyout /etc/apache2/ssl/apache2.key \
				-out /etc/apache2/ssl/apache2.crt \
				-subj "/CN=raceapp.nstru.ac.th" \
# Remove packages to reduce image size
#			&& apt-get purge openssl \
#			&& apt-get autoremove --purge \
# Install SSL certificate
			&& sed -i -e "s|/etc/ssl/certs/ssl-cert-snakeoil.pem|/etc/apache2/ssl/apache2.crt|g" /etc/apache2/sites-available/default-ssl.conf \
			&& sed -i -e "s|/etc/ssl/private/ssl-cert-snakeoil.key|/etc/apache2/ssl/apache2.key|g" /etc/apache2/sites-available/default-ssl.conf \
# Enable SSL
			&& a2enmod ssl \
# Enable mod_rewrite
			&& a2enmod rewrite \
			&& sed -i -e '/^<Directory \/var\/www\/html\/>/,/^<\/Directory>/s/\(AllowOverride \)None/\1All/' /etc/apache2/apache2.conf \
# Disable default site(s)
			&& a2dissite 000-default \
			&& a2dissite default-ssl \
# Enable default site(s)
      && a2ensite 000-default \
      && a2ensite default-ssl

# Install the Oracle Instant Client
ADD oracle/oracle-instantclient12.1-basic_12.1.0.2.0-2_amd64.deb /tmp
ADD oracle/oracle-instantclient12.1-devel_12.1.0.2.0-2_amd64.deb /tmp
ADD oracle/oracle-instantclient12.1-sqlplus_12.1.0.2.0-2_amd64.deb /tmp
RUN dpkg -i /tmp/oracle-instantclient12.1-basic_12.1.0.2.0-2_amd64.deb
RUN dpkg -i /tmp/oracle-instantclient12.1-devel_12.1.0.2.0-2_amd64.deb
RUN dpkg -i /tmp/oracle-instantclient12.1-sqlplus_12.1.0.2.0-2_amd64.deb
RUN rm -rf /tmp/oracle-instantclient12.1-*.deb

# Set up the Oracle environment variables
ENV LD_LIBRARY_PATH /usr/lib/oracle/12.1/client64/lib/
ENV ORACLE_HOME /usr/lib/oracle/12.1/client64/lib/

# Install the OCI8 PHP extension
RUN echo 'instantclient,/usr/lib/oracle/12.1/client64/lib' | pecl install -f oci8-2.0.8
RUN echo "extension=oci8.so" > /etc/php5/apache2/conf.d/30-oci8.ini

# Enable Apache2 modules
RUN a2enmod rewrite

# Set up the Apache2 environment variables
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2
ENV APACHE_LOCK_DIR /var/lock/apache2
ENV APACHE_PID_FILE /var/run/apache2.pid

EXPOSE 80

# Run Apache2 in Foreground
CMD /usr/sbin/apache2 -D FOREGROUND
