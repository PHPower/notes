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
		source	=> 'puppet:///modules/tomcat/local.properties',
		require	=> File['ROOT'],
	}

	file{'latke.properties':
		ensure	=> file,
		path	=> '/usr/share/tomcat/webapps/ROOT/WEB-INF/classes/latke.properties',
		replace	=> true,
		owner	=> 'tomcat',
		group	=> 'tomcat',
		source	=> 'puppet:///modules/tomcat/latke.properties',
		require	=> File['ROOT'],
	}
	
	Package['tomcat'] -> File['ROOT']
	
}
