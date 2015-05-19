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

    public $belongsTo = array(
        'Classroom' => array(
            'className' => 'Classroom',
            'foreignKey' => 'class_id'
        ),
        'Employee' => array(
            'className' => 'Employee',
            'foreignKey' => 'employee_id',
        ),
        'AcademicYear' => array(
            'className' => 'AcademicYear',
            'foreignKey' => 'academic_year_id',
        )
    );

}
