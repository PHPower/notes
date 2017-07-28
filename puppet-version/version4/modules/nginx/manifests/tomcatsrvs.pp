class nginx::tomcatsrvs inherits nginx {
	file{'nginx-tomcat.conf':
		ensure	=> file,
		path	=> '/etc/nginx/nginx.conf',
		content	=> template('nginx/nginx-tomcat.conf.erb'),
	}
	
	Package['nginx'] -> File['nginx-tomcat.conf']  ~> Service['nginx']
}
