class mariadb::database inherits mariadb {
	file{'solodb.sql':
		ensure	=> file,
		path	=> '/var/lib/mysql/solodb.sql',
		source	=> 'puppet:///modules/mariadb/solodb.sql'
	}	

	exec{'createdb':
		command	=> 'mysql < /var/lib/mysql/solodb.sql',
		path    => '/bin:/sbin:/usr/bin:/usr/sbin',
		require	=> Package['mariadb-server'],
	}

	Service['mariadb'] -> File['solodb.sql'] -> Exec['createdb']
}
