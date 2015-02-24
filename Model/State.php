<?php
// app/Model/User.php
App::uses('AppModel', 'Model');
    
class State extends AppModel {

	public $primaryKey = 'state_id';

	public $displayField = 'state_name';
    
    public $hasMany = array(
		'LocalGovt' => array(
			'className' => 'LocalGovt',
			'foreignKey' => 'state_id',
			'dependent' => false
		),
        'Sponsor' => array(
			'className' => 'Sponsor',
			'foreignKey' => 'state_id'
		)
	);

}