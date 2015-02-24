<?php
class DATABASE_CONFIG {

	public $default = array(
        'driver' => 'mysqli',
		'datasource' => 'Database/Mysql',
		'persistent' => false,
		'host' => 'localhost',
		//'host' => '50.62.209.50',
		//'host' => '198.12.158.236',
		//'login' => 'smartschool',
		'login' => 'root',
		//'login' => 'zumasoftware',
		//'password' => 'zumasoftware_smartschool',
		'password' => '',
		//'password' => 'zumasoftware',
		//'database' => 'zumasoftware_smartschool',
		'database' => 'smartschool',
	);
}
