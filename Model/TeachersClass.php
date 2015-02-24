<?php
App::uses('AppModel', 'Model');
/**
 * TeachersSubject Model
 *
 */
class TeachersClass extends AppModel {

    public $primaryKey = 'teacher_class_id';
    
    
     public function beforeSave($options = array()) {
        if (!isset($this->data[$this->alias]['teacher_class_id'])) {
            $this->data[$this->alias]['created_at'] = $this->dateFormatBeforeSave();
        }
        //$this->data[$this->alias]['updated_at'] = $this->dateFormatBeforeSave();
        return parent::beforeSave($options);
    }

}
