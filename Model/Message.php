<?php
App::uses('AppModel', 'Model');

class Message extends AppModel {

    public $primaryKey = 'message_id';

    public function beforeSave($options = array()) {
        $this->data[$this->alias]['message_sender'] = AuthComponent::user('type_id');
        
        return parent::beforeSave($options);
    }
}
