<?php
App::uses('AppModel', 'Model');
/**
 * Class Model
 *
 * @property
 */
class Setup extends AppModel {

	public $primaryKey = 'setup_id';
    
    public function beforeSave($options = array()) {
        return parent::beforeSave($options);
    }


//    public function afterSave($created, $options = array()) {
//        $User = ClassRegistry::init('User');
//        $userRole = ClassRegistry::init('UserRole');
//        $Role = $userRole->find('first', array('conditions' => array('UserRole.' . $userRole->primaryKey => 1)));
//        $id = $this->id;
//        if($created){
//            if(isset($id)){
//                $User->create();
//                $User->data['User']['username'] = $this->data[$this->alias]['email'];
//                $User->data['User']['password'] = $this->data[$this->alias]['password'];
//                $User->data['User']['display_name'] = trim(ucwords($this->data[$this->alias]['full_name']));
//                $User->data['User']['type_id'] = $id;
//                $User->data['User']['group_alias'] = $Role['UserRole']['group_alias'];
//                $User->data['User']['user_role_id'] = 1;
//                if($User->save()) {
//
//                }
//            }
//        }
//    }
}
