<?php
App::uses('AppModel', 'Model');
/**
 * Class Model
 *
 * @property Classlevel $Classlevel
 */
class Exam extends AppModel {

	public $primaryKey = 'exam_id';
    
    public $belongsTo = array(
		'SubjectClasslevel' => array(
			'className' => 'SubjectClasslevel',
			'foreignKey' => 'subject_classlevel_id',
			'conditions' => '',
			'fields' => '',
			'order' => ''
		)
	);
    
    public $hasMany = array(
		'ExamDetail' => array(
			'className' => 'ExamDetail',
			'foreignKey' => 'exam_id',
			'dependent' => false,
			'conditions' => '',
			'fields' => ''
		)
	);

    public function beforeSave($options = array()) {
        if (!isset($this->data[$this->alias]['exam_id'])) {
            $this->data[$this->alias]['exammarked_status_id'] = 2;
        }
        $this->data[$this->alias]['employee_id'] = AuthComponent::user('type_id');
        $this->data[$this->alias]['setup_date'] = $this->dateFormatBeforeSave();
        return parent::beforeSave($options);
    }
    
    public function proc_insertExamDetails($ExamID){
        $result = $this->query('CALL `proc_insertExamDetails`("'.$ExamID.'")');
        return $result;
    }
    
    //Find all subjects exams has been setup to a classlevel in a specify academic term
    public function findExamSetupSubjects($term_id, $classlevel_id) {
        return $this->query('SELECT a.* FROM exam_subjectviews a INNER JOIN teachers_subjectsviews b '
                . 'ON a.subject_classlevel_id=b.subject_classlevel_id AND a.class_id=b.class_id '
                . 'WHERE a.classlevel_id="'.$classlevel_id.'" AND a.academic_term_id="'.$term_id.'" '
                . 'AND b.employee_id="'.AuthComponent::user('type_id').'"');
    }
    
    //Find all subjects exams has been setup to a classlevel in a specify academic term
    public function findExamSubjectView($exam_id) {
        return $this->query('SELECT Exam.* FROM exam_subjectviews Exam WHERE Exam.exam_id="'.$exam_id.'" LIMIT 1');
    }
    
    //Get the subjects assigned to a classlevel or classroom for exams setup
    public function findSubjectsByClasslevelOrClass($term_id, $classlevel_id, $class_id=null) {
        $result = null;
        $res = $this->query('SELECT fun_getSubjectClasslevel("'.$term_id.'")');
        if($class_id === null){
            if($res !== '0') {
                $result = $this->query('SELECT c.exam_id, a.*, b.employee_id, b.employee_name, b.teachers_subjects_id from SubjectClasslevelResultTable a
                    LEFT OUTER JOIN teachers_subjectsviews b ON a.subject_classlevel_id=b.subject_classlevel_id AND a.class_id=b.class_id
                    LEFT OUTER JOIN exams c ON a.subject_classlevel_id=c.subject_classlevel_id AND a.class_id=c.class_id 
                    WHERE classlevel_id="'.$classlevel_id.'" AND a.academic_term_id="'.$term_id.'" AND b.employee_id="'.AuthComponent::user('type_id').'"
                ');
            }
        }else{
            if($res !== '0') {
                $result = $this->query('SELECT c.exam_id, a.*, b.employee_id, b.employee_name, b.teachers_subjects_id from SubjectClasslevelResultTable a
                    LEFT OUTER JOIN teachers_subjectsviews b ON a.subject_classlevel_id=b.subject_classlevel_id AND a.class_id=b.class_id
                    LEFT OUTER JOIN exams c ON a.subject_classlevel_id=c.subject_classlevel_id AND a.class_id=c.class_id
                    WHERE a.class_id="'.$class_id.'" AND a.academic_term_id="'.$term_id.'" AND b.employee_id="'.AuthComponent::user('type_id').'"
                ');
            }
        }
        return $result;
    }
    
    //Find all subjects exams has been setup to a classlevel in a specify academic term
    public function findStudentClasslevel($year_id, $classlevel_id, $class_id=null) {
        if($class_id !== null) {
            $result = $this->query(
                'SELECT a.* FROM students_classlevelviews a WHERE a.class_id="'.$class_id.'" AND a.academic_year_id="'.$year_id.'" '
            );
        }else if($class_id === null) {
            $result = $this->query(
                'SELECT a.*, b.classlevel FROM classrooms a INNER JOIN classlevels b ON '
                .'a.classlevel_id=b.classlevel_id WHERE b.classlevel_id="'.$classlevel_id.'" '
            );
        }
        return $result;
    }
    
    //Find all students for a sponsor
    public function findSponsorStudents($year_id) {
        return $this->query('SELECT a.* FROM students_classlevelviews a WHERE a.sponsor_id="'.AuthComponent::user('type_id').'" AND a.academic_year_id="'.$year_id.'"');
    }
    
    //Get the Students Terminal Exam Details and position
    public function findStudentExamTerminalDetails($student_id, $term_id, $class_id) {
        $result = null;
        $res = $this->query('CALL proc_terminalClassPositionViews("'.$class_id.'", "'.$term_id.'")');
        if($res) {
            $result[0] = $this->query('SELECT a.* FROM ExamsDetailsResultTable a WHERE a.student_id="'.$student_id.'"');
            $result[1] = $this->query('SELECT a.* FROM TerminalClassPositionResultTable a WHERE a.student_id="'.$student_id.'"');
        }
        return $result;
    }
    
    //Get the Classroom Terminal Positions
    public function findClassTerminalPositions($class_id, $term_id) {
        $result = null;
        $res = $this->query('CALL proc_terminalClassPositionViews("'.$class_id.'", "'.$term_id.'")');
        if($res) {
            $result = $this->query('SELECT a.* FROM TerminalClassPositionResultTable a WHERE a.academic_term_id="'.$term_id.'"');
        }
        return $result;
    }
    
    //Get the Students Annual Exam Details and position
    public function findStudentExamAnnualDetails($student_id, $term_id, $class_id) {
        $result = null;
        $res = $this->query('CALL proc_terminalClassPositionViews("'.$class_id.'", "'.$term_id.'")');
        if($res) {
            $result = $this->query('SELECT a.* FROM ExamsDetailsResultTable a WHERE a.student_id="'.$student_id.'" '
                . 'AND a.academic_term_id="'.$term_id.'"');
        }
        return $result;
    }
    
    //Get the Students Annual Subjects Details
    public function findStudentAnnualSubjectsDetails($student_id, $year_id) {
        $result = null;
        $res = $this->query('SELECT func_annualExamsViews("'.$student_id.'", "'.$year_id.'")');
        if($res > 0) {
            $result = $this->query('SELECT a.* FROM AnnualSubjectViewsResultTable a');
        }
        return $result;
    }
    
    //Get the Students Annual Classroom Positions
    public function findStudentAnnualClassPositions($student_id, $class_id, $year_id) {
        $result = null;
        $res = $this->query('Call proc_annualClassPositionViews("'.$class_id.'", "'.$year_id.'")');
        if($res) {
            $result = $this->query('SELECT a.* FROM AnnualClassPositionResultTable a WHERE a.student_id="'.$student_id.'"');
        }
        return $result;
    }
    
    //Get the Classroom Annual Positions
    public function findClassAnnuallPositions($class_id, $year_id) {
        $result = null;
        $res = $this->query('CALL proc_annualClassPositionViews("'.$class_id.'", "'.$year_id.'")');
        if($res) {
            $result = $this->query('SELECT a.* FROM AnnualClassPositionResultTable a WHERE a.academic_year_id="'.$year_id.'" '
                    . 'ORDER BY a.class_annual_position');
        }
        return $result;
    }
}
