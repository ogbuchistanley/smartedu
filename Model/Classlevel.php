<?php
App::uses('AppModel', 'Model');

class Classlevel extends AppModel {

    public $primaryKey = 'classlevel_id';

    public $displayField = 'classlevel';

    public $belongsTo = array(
		'Classgroup' => array(
			'className' => 'Classgroup',
			'foreignKey' => 'classgroup_id',
			'conditions' => '',
			'fields' => '',
			'order' => ''
		)
	);
    
	public $hasMany = array(
		'Classroom' => array(
			'className' => 'Classroom',
			'foreignKey' => 'classlevel_id',
			'dependent' => false,
			'conditions' => '',
			'fields' => '',
			'order' => '',
			'limit' => '',
			'offset' => '',
			'exclusive' => '',
			'finderQuery' => '',
			'counterQuery' => ''
		)
	);

}
