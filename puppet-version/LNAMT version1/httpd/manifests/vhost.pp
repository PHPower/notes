class httpd::vhost inherits httpd {
	file{'vhost.conf':
		ensure	=> file,
		path	=> '/etc/httpd/conf.d/vhost.conf',
		content	=> template('httpd/vhost.conf.erb'),
	}

	Package['httpd'] -> File['vhost.conf'] ~> Service['httpd']
}
