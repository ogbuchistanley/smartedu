<?php
// app/Model/User.php
App::uses('AppModel', 'Model');

class SubjectClasslevel extends AppModel {

	public $primaryKey = 'subject_classlevel_id';
    
    public $belongsTo = array(
		'Subject' => array(
			'className' => 'Subject',
			'foreignKey' => 'subject_id',
			'conditions' => '',
			'fields' => '',
			'order' => ''
		),
		'Classlevel' => array(
			'className' => 'Classlevel',
			'foreignKey' => 'classlevel_id',
			'conditions' => '',
			'fields' => '',
			'order' => ''
		),
		'Classroom' => array(
			'className' => 'Classroom',
			'foreignKey' => 'class_id',
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
    
    //Get the Teachers,assigned to a subject in classlevel or classroom 
    public function findSubjectsByClasslevelOrClass($term_id, $classlevel_id, $class_id=null) {
        $result = null;
        $res = $this->query('SELECT fun_getSubjectClasslevel("'.$term_id.'")');
        if($class_id === null){
            if($res !== '0') {
                $result = $this->query('SELECT c.exam_id, a.*, b.employee_id, b.employee_name, b.teachers_subjects_id from SubjectClasslevelResultTable a
                    LEFT OUTER JOIN teachers_subjectsviews b ON a.subject_classlevel_id=b.subject_classlevel_id AND a.class_id=b.class_id
                    LEFT OUTER JOIN exams c ON a.subject_classlevel_id=c.subject_classlevel_id AND a.class_id=c.class_id 
                    WHERE classlevel_id="'.$classlevel_id.'" AND a.academic_term_id="'.$term_id.'"
                ');
            }
        }else{
            if($res !== '0') {
                $result = $this->query('SELECT c.exam_id, a.*, b.employee_id, b.employee_name, b.teachers_subjects_id from SubjectClasslevelResultTable a
                    LEFT OUTER JOIN teachers_subjectsviews b ON a.subject_classlevel_id=b.subject_classlevel_id AND a.class_id=b.class_id
                    LEFT OUTER JOIN exams c ON a.subject_classlevel_id=c.subject_classlevel_id AND a.class_id=c.class_id
                    WHERE a.class_id="'.$class_id.'" AND a.academic_term_id="'.$term_id.'"
                ');
            }
        }
        return $result;
    }
    
    //Check to see if such record already exist
    public function validateIfExist($subject_id, $term_id, $classlevel_id, $class_id=null) {
        if($class_id === null){
            $result = $this->query('
                SELECT * FROM subject_classlevels WHERE subject_id="'.$subject_id.'" AND classlevel_id="'.$classlevel_id.'" AND academic_term_id="'.$term_id.'"
            ');
        }else{
            $result = $this->query('
                SELECT * FROM subject_classlevels WHERE subject_id="'.$subject_id.'" AND class_id="'.$class_id.'" AND academic_term_id="'.$term_id.'"
            ');
        }
        return $result;
    }
    
    //Find all subjects assigned to a classlevel in a specify academic term
    public function findSubjectsAssigned($term_id, $classlevel_id) {
        return $this->query('SELECT a.* FROM subject_classlevelviews a WHERE a.classlevel_id="'.$classlevel_id.'" AND academic_term_id="'.$term_id.'"');
    }
    
    //Find all the students offering the subjects in a classroom or classlevel
    public function findStudentsBySubjectClasslevel($subject_classlevel_id) {
        $result = $this->query('SELECT * FROM students_subjectsviews a WHERE subject_classlevel_id="'.$subject_classlevel_id.'"');
        return $result;
    }
    
    //Find the students in a classroom or classlevel not offering the subject
    public function findStudentsBySubjectsNot($subject_classlevel_id) {
        $query = $this->query('SELECT * FROM subject_classlevelviews a WHERE subject_classlevel_id="'.$subject_classlevel_id.'" LIMIT 1');
        //$options = array('conditions' => array('SubjectClasslevel.subject_classlevel_id' => $subject_classlevel_id));
        $record = array_shift($query);
        $academic_year_id = $record['a']['academic_year_id'];
        $classlevel_id = $record['a']['classlevel_id'];
        $class_id = (empty($record['a']['class_id'])) ? -1 :$record['a']['class_id'];
        if($class_id === -1) {
            $result = $this->query(
                'SELECT * FROM students_classlevelviews a WHERE a.classlevel_id="'.$classlevel_id.'" AND a.academic_year_id="'.$academic_year_id.'" '
                . 'AND a.student_id NOT IN (SELECT student_id FROM students_subjectsviews a WHERE subject_classlevel_id="'.$subject_classlevel_id.'")'
            );
        }  else {
            $result = $this->query(
                'SELECT * FROM students_classlevelviews a WHERE a.class_id="'.$class_id.'" AND a.academic_year_id="'.$academic_year_id.'" '
                . 'AND a.student_id NOT IN (SELECT student_id FROM students_subjectsviews a WHERE subject_classlevel_id="'.$subject_classlevel_id.'")'
            );
        }
        return $result;
    }
    
    //Update Subjects Students Registered Table with the list of students
    public function updateStudentsSubjects($subject_classlevel_id, $stud_ids) {
        $class_term = $this->query('SELECT a.* FROM subject_classlevels a WHERE a.subject_classlevel_id="'.$subject_classlevel_id.'" LIMIT 1');
        $class_term = ($class_term) ? array_shift($class_term) : false;
        if($class_term) {
            $this->query('DELETE FROM subject_students_registers WHERE subject_classlevel_id="' . $subject_classlevel_id . '"');
            $ids = explode(',', $stud_ids);
            for ($i = 0; $i < count($ids); $i++) {
                $this->query('INSERT INTO subject_students_registers(student_id, class_id, subject_classlevel_id)'
                    . ' SELECT "' . $ids[$i] . '", b.class_id, "' . $subject_classlevel_id . '" FROM students a INNER JOIN students_classes b ON a.student_id=b.student_id INNER JOIN'
                    . ' classrooms c ON c.class_id = b.class_id WHERE c.classlevel_id="' . $class_term['a']['classlevel_id'] . '" AND a.student_status_id = 1 AND a.student_id="'.$ids[$i].'" AND'
                    . ' b.academic_year_id = (SELECT academic_year_id FROM academic_terms WHERE academic_term_id="' . $class_term['a']['academic_term_id'] . '" LIMIT 1)'
                );
            }
        }
        return 1;
    }

    //Delete Subjects Classlevel Record and its equivalent Subjects Students Registered
    public function deleteSubjectClasslevel($subject_classlevel_id) {
        $this->query('DELETE FROM subject_students_registers WHERE subject_classlevel_id="'.$subject_classlevel_id.'"');

        $result = $this->query('DELETE FROM subject_classlevels WHERE subject_classlevel_id="'.$subject_classlevel_id.'"');

        return $result;
    }
}