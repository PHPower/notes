class tomcat::blog inherits tomcat {

	file{'ROOT':
                ensure  => directory,
                path    => '/usr/share/tomcat/webapps/ROOT/',
                source  => 'puppet:///modules/tomcat/ROOT/',
                replace => true,
                recurse => true,
                owner   => 'tomcat',
                group   => 'tomcat',
        }

	file{'local.properties':
		ensure	=> file,
		path	=> '/usr/share/tomcat/webapps/ROOT/WEB-INF/classes/local.properties',
		replace	=> true,
		owner	=> 'tomcat',
		group	=> 'tomcat',
		content	=> template('tomcat/local.properties.erb'),
		require	=> File['ROOT'],
	}
	
	Package['tomcat'] -> File['ROOT']
	
}
