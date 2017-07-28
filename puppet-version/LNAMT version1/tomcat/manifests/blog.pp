class tomcat::blog inherits tomcat {
	file{'/usr/share/tomcat/webapps/ROOT':
		ensure	=> directory,
		source	=> 'puppet:///modules/tomcat/ROOT',
		recures => true,
	}

	file{'local.properties':
		ensure	=> file,
		path	=> '/usr/share/tomcat/webapps/ROOT/WEB-INF/classes/local.properties',
		content	=> template('tomcat/local.properties.erb'),
		require	=> File['/usr/share/tomcat/webapps/ROOT'],
	}
	
	Exec['authbind']{
		onlyif	=> '/usr/bin/mysql',
	}
	
	Package['authbind'] -> File['/usr/share/tomcat/webapps/ROOT'] ~> Exec['authbind']
	
}
