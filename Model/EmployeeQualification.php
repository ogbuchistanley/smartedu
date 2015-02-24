<?php
App::uses('AppModel', 'Model');
/**
 * ExamDetail Model
 *
 * @property Exam $Exam
 * @property Student $Student
 */
class EmployeeQualification extends AppModel {

/**
 * Primary key field
 *
 * @var string
 */
    public $primaryKey = 'employee_qualification_id';


	//The Associations below have been created with all possible keys, those that are not needed can be removed

/**
 * belongsTo associations
 *
 * @var array
 */
    public $belongsTo = array(
        'Employee' => array(
            'className' => 'Employee',
            'foreignKey' => 'employee_id',
            'conditions' => '',
            'fields' => '',
            'order' => ''
        )
    );
    
    
    public function beforeSave($options = array()) {
        if(isset($this->data[$this->alias]['date_from'])){
            $this->data[$this->alias]['date_from'] = $this->dateFormat($this->data[$this->alias]['date_from']);
        }
        if(isset($this->data[$this->alias]['date_to'])){
            $this->data[$this->alias]['date_to'] = $this->dateFormat($this->data[$this->alias]['date_to']);
        }
        if(isset($this->data[$this->alias]['qualification_date'])){
            $this->data[$this->alias]['qualification_date'] = $this->dateFormat($this->data[$this->alias]['qualification_date']);
        }
        return parent::beforeSave($options);
    }
}
