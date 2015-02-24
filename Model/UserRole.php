<?php
// app/Model/User.php
App::uses('AppModel', 'Model');

class UserRole extends AppModel {

	public $primaryKey = 'user_role_id';

	public $displayField = 'user_role';
    
    public $validate = array(
        'user_role' => array(
            'notEmpty' => array(
                'rule' => array('notEmpty'),
                'message' => 'A user_role is required',                
            ),
            'isUnique' => array( 'rule' => 'isUnique', 'message' => 'This username is already in use')
        )
    );
}