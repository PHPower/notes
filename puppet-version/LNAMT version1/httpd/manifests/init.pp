class httpd($version) {
	package{"$version":
		ensure	=> latest,
	}
	
	service{"$version"
		ensure	=> running,
		enable	=> true,
	}
}

$version = $osfamily ? {
	"RedHat" => 'httpd',
	/(?i-mx:debian)/ => 'apache2',
	default => 'httpd',
}
