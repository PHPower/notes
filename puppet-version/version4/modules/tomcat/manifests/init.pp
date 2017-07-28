class tomcat {
	package{['java-1.8.0-openjdk-devel','tomcat','tomcat-admin-webapps','tomcat-webapps']:
		ensure	=> installed,
	} 
}
