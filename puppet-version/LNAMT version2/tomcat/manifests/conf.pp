class tomcat::conf inherits tomcat{
	file{'tomcat-user.xml':
		ensure	=> file,
		path	=> '/etc/tomcat/tomcat-users.xml',
		owner	=> tomcat,
		group	=> tomcat,
		content	=> template('tomcat/tomcat-users.xml.erb'),
	}
	
	file{'server.xml':
		ensure	=> file,
		path	=> '/etc/tomcat/server.xml',
		owner	=> tomcat,
		group	=> tomcat,
		content => template('tomcat/server.xml.erb'),
		require => File['tomcat-user.xml'],
	}
	
	
#	exec{'startdb':
#		command => 'authbind --deep /usr/libexec/tomcat/server start &',
#		source => '/usr/bin:/usr/sbin:/bin:/sbin',	
#		require	=> Package['authbind'],
#	}
	
	Package['java-1.8.0-openjdk-devel','tomcat','tomcat-lib','tomcat-admin-webapps','tomcat-webapps'] -> File['tomcat-user.xml'] 

#~> Exec['authbind']
}
