class tomcat::memtwo inherits tomcat {
	exec{'mkdir':
		command	=> 'mkdir -p /usr/share/tomcat/webapps/test/{WEB-INF,classes,META-INF}',
		path    => '/bin:/sbin:/usr/bin:/usr/sbin',
		creates => '/usr/share/tomcat/webapps/test/',
	}

	file{'index.jsp':
		ensure	=> file,
		path	=> '/usr/share/tomcat/webapps/test/index.jsp',
		source	=> 'puppet:///modules/tomcat/tom2-index.jsp',
		require	=> Exec['mkdir'],
	} 

	file{'javolution-5.4.3.1.jar':
		ensure	=> file,
		path	=> '/usr/share/java/tomcat/javolution-5.4.3.1.jar',
		source	=> 'puppet:///modules/tomcat/javolution-5.4.3.1.jar',
		require	=> Exec['mkdir'],
	}
	
	file{'memcached-session-manager-1.8.3.jar':
		ensure	=> file,
		path	=> '/usr/share/java/tomcat/memcached-session-manager-1.8.3.jar',
		source	=> 'puppet:///modules/tomcat/memcached-session-manager-1.8.3.jar',
		require	=> Exec['mkdir'],
	}

	file{'memcached-session-manager-tc7-1.8.3.jar':
		ensure	=> file,
		path	=> '/usr/share/java/tomcat/memcached-session-manager-tc7-1.8.3.jar',
		source	=> 'puppet:///modules/tomcat/memcached-session-manager-tc7-1.8.3.jar',
		require	=> Exec['mkdir'],
	}

	file{'msm-javolution-serializer-1.8.3.jar':
		ensure	=> file,
		path	=> '/usr/share/java/tomcat/msm-javolution-serializer-1.8.3.jar',
		source	=> 'puppet:///modules/tomcat/msm-javolution-serializer-1.8.3.jar',
		require	=> Exec['mkdir'],
	}

	file{'spymemcached-2.11.1.jar':
		ensure	=> file,
		path	=> '/usr/share/java/tomcat/spymemcached-2.11.1.jar',
		source	=> 'puppet:///modules/tomcat/spymemcached-2.11.1.jar',
		require	=> Exec['mkdir'],
	}

	Package['java-1.8.0-openjdk-devel','tomcat','tomcat-admin-webapps','tomcat-webapps'] -> Exec['mkdir']
}
