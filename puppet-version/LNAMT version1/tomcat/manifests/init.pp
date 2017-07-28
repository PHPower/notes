class tomcat {
	package{['java-1.8.0-openjdk-devel','tomcat','tomcat-lib','tomcat-admin-webapps','tomcat-webapps']:
		ensure	=> latest,
	}
	
	package{'authbind':
		ensure	=> latest,
		source	=> 'puppet:///modules/tomcat/authbind-2.1.1-0.1.x86_64.rpm',
		provider => rpm,
	}

	exec{'authbind':
		command => 'nohup authbind --deep /usr/libexec/tomcat/server start &',
		sourece => '/usr/bin:/usr/sbin:/bin:/sbin',	
		require	=> Package['authbind'],
	}
}
