<?php
App::uses('AppModel', 'Model');
/**
 * AcademicYear Model
 *
 */
class ProcessItem extends AppModel {

    public $primaryKey = 'process_item_id';

    public function beforeSave($options = array()) {
        if (!isset($this->data[$this->alias]['process_item_id'])) {
            $this->data[$this->alias]['process_date'] = $this->dateFormatBeforeSave($this->data[$this->alias]['process_date']);
            $this->data[$this->alias]['process_by'] = AuthComponent::user('type_id');
        }
        return parent::beforeSave($options);
    }
    
    public function proc_processTerminalFees($process_id){
        $result = $this->query('CALL `proc_processTerminalFees`("'.$process_id.'")');
        return $result;
    }
}
