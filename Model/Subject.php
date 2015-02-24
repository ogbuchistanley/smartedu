<?php
// app/Model/User.php
App::uses('AppModel', 'Model');

class Subject extends AppModel {

	public $primaryKey = 'subject_id';

	public $displayField = 'subject_name';
    
    public $belongsTo = array(
        'SubjectGroup' => array(
            'className' => 'SubjectGroup',
            'foreignKey' => 'subject_group_id'
        ),
    );
    
    public function proc_assignSubject2Students($subject_classlevel_id){
        $result = $this->query('CALL `proc_assignSubject2Students`("'.$subject_classlevel_id.'")');
        return $result;
    }
    
    //Find the Subjects assigned to a tutor for the current academic term
    public function findCurrentTermSubjectTutor() {
        $AcademicTerm = ClassRegistry::init('AcademicTerm');
        return $this->query('SELECT a.* FROM teachers_subjectsviews a WHERE a.employee_id="'.AuthComponent::user('type_id').'"'
                . ' AND academic_term_id="'.$AcademicTerm->getCurrentTermID().'"');
    }
}