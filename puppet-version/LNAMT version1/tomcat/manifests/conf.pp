class tomcat::conf inherits tomcat{
	file{'tomcat-user.xml':
		ensure	=> file,
		path	=> '/etc/tomcat/tomcat-users.xml',
		content	=> template('tomcat/tomcat-users.xml.erb'),
	}
	
	file{'server.xml':
		ensure	=> file,
		path	=> '/etc/tomcat/server.xml',
		content => template('tomcat/server.xml.erb')
		require => File['tomcat-user.xml'],
	}
	
	Package['java-1.8.0-openjdk-devel','tomcat','tomcat-lib','tomcat-admin-webapps','tomcat-webapps','authbind'] -> File['tomcat-user.xml'] ~> Exec['authbind']
}
