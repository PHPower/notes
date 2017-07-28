class mariadb::database inherits mariadb {
	exec{'createdb':
		command	=> 'mysql < /etc/puppet/modules/mariadb/files/solodb.sql',
		path    => '/bin:/sbin:/usr/bin:/usr/sbin',
		require	=> Package['mariadb-server'],
	}

	Service['mariadb'] -> Exec['createdb']
}
