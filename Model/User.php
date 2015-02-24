<?php
// app/Model/User.php
App::uses('AppModel', 'Model');
App::uses('BlowfishPasswordHasher', 'Controller/Component/Auth');

class User extends AppModel {

	public $primaryKey = 'user_id';

	public $displayField = 'display_name';
    
    public function beforeSave($options = array()) {
        if (!isset($this->data[$this->alias]['user_id'])) {
            $this->data[$this->alias]['created_at'] = $this->dateFormatBeforeSave();
            $this->data[$this->alias]['created_by'] = AuthComponent::user('type_id');
        }
        if(isset($this->data[$this->alias]['password'])){
            $passwordHasher = new BlowfishPasswordHasher();
            $this->data[$this->alias]['password'] = $passwordHasher->hash($this->data[$this->alias]['password']);
        }
        //$this->data[$this->alias]['updated_at'] = $this->dateFormatBeforeSave();
        return parent::beforeSave($options);
    }
    
    public function afterSave($created, $options = array()) {
        if($created){
            $id = $this->data[$this->alias]['user_id'];
            $user = $this->data[$this->alias]['username'];
            $role = $this->data[$this->alias]['user_role_id'];
            if($role === 1 || $role === 2) {
                $parent_id = 1;
            }else if($role === 3 || $role === 4){
                $parent_id = 2;
            }else if($role > 4){
                $parent_id = 3;
            }
            //$this->createAROUser($user, $parent_id, $id);
        }
    }    
//    function procedure(){ 
//        $result = $this->execute('call test()');
//        return $result;
//    }
    
    public $validate = array(
        'username' => array(
            'notEmpty' => array(
                'rule' => array('notEmpty'),
                'message' => 'A username is required',                
            ),
            //'isUnique' => array( 'rule' => 'isUnique', 'message' => 'This username is already in use')
        ),
        'password' => array(
            'notEmpty' => array(
                'rule' => array('notEmpty'),
                'message' => 'A password is required',                
            ),
            'min_length' => array('rule' => array('minLength', '4'), 'message' => 'Password must have a mimimum of 6 characters')
        )
    );
    
    public $belongsTo = array(
        'UserRole' => array(
            'className' => 'UserRole',
            'foreignKey' => 'user_role_id'
        ),
        'Status' => array(
            'className' => 'Status',
            'foreignKey' => 'status_id',
        )
    );
    
}