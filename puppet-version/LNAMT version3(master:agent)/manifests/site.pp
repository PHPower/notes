node 'base' {
	include	chrony
} 
node 'node1.maxie.io' {
	include	nginx
	include	nginx::webproxy	
}

node 'node2.maxie.io' {
	include	mariadb
	include	tomcat
	include	tomcat::conf
	include	tomcat::blog
	include	tomcat::authbind
}
