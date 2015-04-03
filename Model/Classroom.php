<?php
App::uses('AppModel', 'Model');
/**
 * Class Model
 *
 * @property Classlevel $Classlevel
 */
class Classroom extends AppModel {

    public $primaryKey = 'class_id';

    public $displayField = 'class_name';


    public $belongsTo = array(
        'Classlevel' => array(
            'className' => 'Classlevel',
            'foreignKey' => 'classlevel_id',
            'conditions' => '',
            'fields' => '',
            'order' => ''
        )
    );
    
    //Find all the classrooms in a classlevel and the head tutor assigned
    public function findClassByClasslevel($classlevel_id, $year_id) {
        $res = $this->query('SELECT fun_getClassHeadTutor("'.$classlevel_id.'", "'.$year_id.'")');
        if($res !== '0') {
            $result = $this->query('SELECT a.* FROM ClassHeadTutorResultTable a');
        }
        return $result;
    }
    
    //Find the head Tutors assigned to a class
    public function findHeadTutorClassrooms() {
        return $this->query('SELECT a.* FROM teachers_classviews a WHERE a.employee_id="'.AuthComponent::user('type_id').'" ORDER BY a.employee_name');
    }
    
    //Find the head Tutors assigned to a class for the current academic year
    public function findHeadTutorCurrentClassrooms() {
        $AcademicTerm = ClassRegistry::init('AcademicTerm');
        return $this->query('SELECT a.* FROM teachers_classviews a WHERE a.employee_id="'.AuthComponent::user('type_id').'"'
                . ' AND academic_year_id="'.$AcademicTerm->getCurrentYearID().'" ORDER BY a.employee_name');
    }
}
