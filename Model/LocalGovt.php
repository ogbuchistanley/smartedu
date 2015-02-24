<?php
App::uses('AppModel', 'Model');
/**
 * LocalGovt Model
 *
 * @property State $State
 */
class LocalGovt extends AppModel {

	public $primaryKey = 'local_govt_id';

	public $displayField = 'local_govt_name';

	public $belongsTo = array(
		'State' => array(
			'className' => 'State',
			'foreignKey' => 'state_id',
			'conditions' => '',
			'fields' => '',
			'order' => ''
		)
	);
}
