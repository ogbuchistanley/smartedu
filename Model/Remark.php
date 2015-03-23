<?php
App::uses('AppModel', 'Model');
/**
 * Class Model
 *
 * @property Classlevel $Classlevel
 */
class Remark extends AppModel {

	public $primaryKey = 'remark_id';
    
    public $belongsTo = array(
        'Student' => array(
            'className' => 'Student',
            'foreignKey' => 'student_id',
            'conditions' => '',
            'fields' => '',
            'order' => ''
        ),
        'Employee' => array(
            'className' => 'Employee',
            'foreignKey' => 'employee_id',
            'conditions' => '',
            'fields' => '',
            'order' => ''
        ),
        'AcademicTerm' => array(
            'className' => 'AcademicTerm',
            'foreignKey' => 'academic_term_id',
            'conditions' => '',
            'fields' => '',
            'order' => ''
        )
    );

    public function beforeSave($options = array()) {
        $AcademicTerm = ClassRegistry::init('AcademicTerm');
        $this->data[$this->alias]['employee_id'] = AuthComponent::user('type_id');
        $this->data[$this->alias]['academic_term_id'] = $AcademicTerm->getCurrentTermID();
        return parent::beforeSave($options);
    }


}
