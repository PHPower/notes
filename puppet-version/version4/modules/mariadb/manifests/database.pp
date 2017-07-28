class mariadb::database inherits mariadb {
	file{'solodb.sql':
		ensure	=> file,
		path	=> '/var/lib/mysql/solodb.sql',
		source	=> 'puppet:///modules/mariadb/solodb.sql'
	}	

	# only run once
	exec{'createdb':
		command	=> 'mysql < /var/lib/mysql/solodb.sql',
		path    => '/bin:/sbin:/usr/bin:/usr/sbin',
		require	=> Package['mariadb-server'],
		unless  => "mysql -usolo -proot@123 -h$ipaddress",
	}

	Service['mariadb'] -> File['solodb.sql'] -> Exec['createdb']
}
