class tomcat::memconf inherits tomcat{
	file{'tomcat-user.xml':
		ensure	=> file,
		path	=> '/etc/tomcat/tomcat-users.xml',
		owner	=> tomcat,
		group	=> tomcat,
		content	=> template('/etc/puppet/modules/tomcat/templates/tomcat-users.xml.erb'),
		replace	=> true,
	}
	
	file{'server.xml':
		ensure	=> file,
		path	=> '/etc/tomcat/server.xml',
		owner	=> tomcat,
		group	=> tomcat,
		content => template('tomcat/server-mem.xml.erb'),
		require => File['tomcat-user.xml'],
		replace	=> true,
	}
	
	
	Package['java-1.8.0-openjdk-devel','tomcat','tomcat-admin-webapps','tomcat-webapps'] -> File['tomcat-user.xml'] 
}
