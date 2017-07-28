class tomcat::authbind inherits tomcat {
	file{'authbind':
		ensure	=> file,
		path	=> '/tmp/authbind-2.1.1-0.1.x86_64.rpm',
		source	=> 'puppet:///modules/tomcat/authbind-2.1.1-0.1.x86_64.rpm'
	} 

	package{'authbind':
		ensure	=> installed,
		source	=> '/tmp/authbind-2.1.1-0.1.x86_64.rpm',
		provider => rpm,
	}

	exec{'authbind':
		command	=> 'setsid authbind --deep /usr/libexec/tomcat/server start',
		path	=> '/bin:/sbin:/usr/bin:/usr/sbin',
		require	=> Package['authbind']
	}

	File['authbind'] -> Package['authbind']

}
