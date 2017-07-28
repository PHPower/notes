class httpd::httpdconf inherits httpd {
	file{'httpd.conf':
		ensure	=> file,
		path	=> '/etc/httpd/conf/httpd.conf',
		content	=> template('httpd/httpd.conf.erb'),
	}

	Package['httpd'] -> File['httpd.conf'] ~> Service['httpd']
}
