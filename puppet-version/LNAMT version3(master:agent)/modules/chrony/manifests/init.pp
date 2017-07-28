# Class: chrony
# 
# This module manages CHRONY
#
# 

class chrony {
	package{'chrony':
		ensure	=> latest,
	} ->
	
	file{'chrony.conf':
		ensure	=> file,
		path	=> '/etc/chrony.conf',
		source	=> 'puppet:///modules/chrony/chrony.conf',
	} ~>
	
	service{'chronyd':
		ensure	=> running,
		enable	=> true,
	}
}	
