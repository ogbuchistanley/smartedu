<?php
App::uses('AppModel', 'Model');
/**
 * StudentsClass Model
 *
 */
class StudentsClass extends AppModel {
    
    public $primaryKey = 'student_class_id';
    
    public $belongsTo = array(
		'Classroom' => array(
			'className' => 'Classroom',
			'foreignKey' => 'class_id',
			'conditions' => '',
			'fields' => '',
			'order' => ''
		)
	);
    
    public function findStudentsWithOutClass() {
        $term_id = ClassRegistry::init('AcademicTerm');
//        $options = array('conditions' => array('StudentsClass.class_id' => $param, 'StudentsClass.academic_year_id' => $term_id->getCurrentYearID()));
//        return $stud->find('all', $options);
        $result = $this->query('
            SELECT b.student_id, b.first_name, b.surname, b.other_name, b.student_no FROM students b
            WHERE b.student_status_id="1" 
            AND b.student_id NOT IN (SELECT student_id FROM students_classes WHERE academic_year_id="'.$term_id->getCurrentYearID().'")
        ');
        return $result;
    }
    
    public function findStudentsByClass($class_id) {
        $term_id = ClassRegistry::init('AcademicTerm');
        $result = $this->query('
            SELECT a.*, b.first_name, b.surname, b.other_name, b.student_no FROM students_classes a INNER JOIN students b ON a.student_id=b.student_id
            WHERE b.student_status_id="1" AND a.class_id="'.$class_id.'" AND academic_year_id="'.$term_id->getCurrentYearID().'"
        ');
        return $result;
    }
    
    public function findStudentsByClasslevelOrClass($year_id, $classlevel_id, $class_id=null) {
        if($class_id === null){
            $result = $this->query('
                SELECT a.*, c.*, b.* FROM students b
                INNER JOIN students_classes a ON a.student_id=b.student_id
                INNER JOIN classrooms c ON a.class_id=c.class_id
                WHERE c.classlevel_id="'.$classlevel_id.'" AND academic_year_id="'.$year_id.'"
            ');
        }else{
            $result = $this->query('
                SELECT a.*, c.*, b.* FROM students b
                INNER JOIN students_classes a ON a.student_id=b.student_id
                INNER JOIN classrooms c ON a.class_id=c.class_id
                WHERE a.class_id="'.$class_id.'" AND academic_year_id="'.$year_id.'"
            ');
        }
        return $result;
    }
}