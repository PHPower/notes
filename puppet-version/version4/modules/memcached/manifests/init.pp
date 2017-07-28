class memcached {
	package{'memcached':
		ensure	=> latest,
	} ->

	service{'memcached':
		ensure	=> running,
		enable	=> true,
	}
}
