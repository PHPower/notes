node 'base' {
	include	chrony
} 
node 'node1.maxie.io' {
	include	nginx
	include	nginx::tomcatsrvs	
}

node 'node2.maxie.io' {
	include	mariadb
	include	httpd
	include	httpd::httpdconf
	include	httpd::vhost
	include	tomcat
	include	tomcat::memconf
	include	tomcat::blog
	include tomcat::memone
	include	memcached
	include	tomcat::authbind
}

node 'node3.maxie.io' {
	include	mariadb
	include	httpd
	include	httpd::httpdconf
	include	httpd::vhost
	include	tomcat
	include	tomcat::memconf
	include	tomcat::blog
	include tomcat::memtwo
	include	memcached
	include	tomcat::authbind
}
