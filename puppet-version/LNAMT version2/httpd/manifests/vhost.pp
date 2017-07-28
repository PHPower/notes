class httpd::vhost inherits httpd {
	exec{'mkdir':
		command	=> 'mkdir -p /web/blog/logs/',
		path	=> '/usr/bin:/usr/sbin/:/bin:/sbin',
		creates	=> '/web/blog/logs',
		before	=> [ File['vhost.conf'], Service['httpd'] ],
	}

	file{'vhost.conf':
		ensure	=> file,
		path	=> '/etc/httpd/conf.d/vhost.conf',
		content	=> template('httpd/vhost.conf.erb'),
	}
	

	Package['httpd'] -> File['vhost.conf'] ~> Service['httpd']
}
