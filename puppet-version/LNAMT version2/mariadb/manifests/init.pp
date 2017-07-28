class mariadb($datadir='/var/lib/mysql') {
	package{'mariadb-server':
		ensure	=> installed,
	}

	file{"$datadir":
		ensure	=> directory,
		owner	=> mysql,
		group	=> mysql,
		require	=> [ Package['mariadb-server'], Exec['createdir'], ],	
	}
	
	exec{'createdir':
		command	=> "mkdir -pv $datadir",
		require	=> Package['mariadb-server'],
		path	=> '/bin:/sbin:/usr/bin:/usr/sbin',
		creates	=> "$datadir",
	}

	file{'server.cnf':
		ensure	=> file,
		path	=> '/etc/my.cnf.d/server.cnf',
		content	=> template('mariadb/server.cnf.erb'),
		require	=> Package['mariadb-server'],
		notify	=> Service['mariadb'],
	}

	service{'mariadb':
		ensure	=> running,
		enable	=> true,
		require	=> [ Exec['createdir'], File["$datadir"], ],
	}
}
