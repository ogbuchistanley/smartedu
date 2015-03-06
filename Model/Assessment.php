<?php
App::uses('AppModel', 'Model');
/**
 * Classgroup Model
 *
 */
class Assessment extends AppModel {

    public $primaryKey = 'assessment_id';


    public function beforeSave($options = array()) {
        $term_id = ClassRegistry::init('AcademicTerm');
        if (!isset($this->data[$this->alias]['assessment_id'])) {

            $this->data[$this->alias]['academic_term_id'] = $term_id->getCurrentTermID();
        }
        return parent::beforeSave($options);
    }


    public $belongsTo = array(
        'Student' => array(
            'className' => 'Student',
            'foreignKey' => 'student_id',
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

}
