class httpd{
	package{'httpd':
		ensure	=> latest,
	} ->
	
	service{'httpd':
		ensure	=> running,
		enable	=> true,
	}
}

