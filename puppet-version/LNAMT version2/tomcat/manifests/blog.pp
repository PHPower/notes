class tomcat::blog inherits tomcat {
	#file{'ROOT':
	#	ensure	=> directory,
	#	path	=> '/usr/share/tomcat/webapps/ROOT',
	#	source	=> 'puppet:///modules/tomcat/ROOT',
	#	recures => true,
	#}

	file{'local.properties':
		ensure	=> file,
		path	=> '/usr/share/tomcat/webapps/ROOT/WEB-INF/classes/local.properties',
		content	=> template('tomcat/local.properties.erb'),
	}
	
	
	
}
