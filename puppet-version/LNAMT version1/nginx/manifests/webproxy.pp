class nginx::webproxy inherits nginx {
	file{'nginx.conf':
		ensure	=> file,
		path	=> '/etc/nginx/nginx.conf',
		content	=> template('nginx/nginx.conf.erb'),
	}
	
	Package['nginx'] -> File['nginx.conf']  ~> Service['nginx']
}
