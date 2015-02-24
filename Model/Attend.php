<?php
App::uses('AppModel', 'Model');
/**
 * Class Model
 *
 * @property Classlevel $Classlevel
 */
class Attend extends AppModel {

	public $primaryKey = 'attend_id';
    
    public $belongsTo = array(
        'Classroom' => array(
            'className' => 'Classroom',
            'foreignKey' => 'class_id',
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
        $this->data[$this->alias]['attend_date'] = $this->dateFormat($this->data[$this->alias]['attend_date']);
        return parent::beforeSave($options);
    }
    
    
    //Find all subjects exams has been setup to a classlevel in a specify academic term
    public function findStudentClassroom($year_id, $class_id) {
        return $this->query('SELECT a.* FROM students_classlevelviews a WHERE a.class_id="'.$class_id.'" AND a.academic_year_id="'.$year_id.'" ');
    }
    
    
    public function proc_insertAttendDetails($AttendID, $StudentIDS){
        $result = $this->query('CALL `proc_insertAttendDetails`("'.$AttendID.'", "'.$StudentIDS.'")');
        return $result;
    }
    
    
    //Find the attendance taken
    public function findAttendance($term_id, $classlevel_id, $search_date, $date_from, $date_to) {
        if($classlevel_id !== null && $search_date === null && $date_from === null){
            $result = $this->query('SELECT a.* FROM attend_headerviews a '
                . 'WHERE a.classlevel_id="'.$classlevel_id.'" AND a.academic_term_id="'.$term_id.'" '
                . 'AND a.employee_id="'.AuthComponent::user('type_id').'" ORDER BY a.attend_date DESC');
        }else if($search_date !== null && $classlevel_id === null && $date_from === null){
            $result = $this->query('SELECT a.* FROM attend_headerviews a '
                . 'WHERE a.attend_date="'.$search_date.'" AND a.academic_term_id="'.$term_id.'" '
                . 'AND a.employee_id="'.AuthComponent::user('type_id').'" ORDER BY a.attend_date DESC');
        }else if($date_from !== null && $date_to !== null && $classlevel_id === null && $search_date === null){
            $result = $this->query('SELECT a.* FROM attend_headerviews a '
                . 'WHERE a.attend_date BETWEEN "'.$date_from.'" AND "'.$date_to.'" AND a.academic_term_id="'.$term_id.'" '
                . 'AND a.employee_id="'.AuthComponent::user('type_id').'" ORDER BY a.attend_date DESC');
        }else if($classlevel_id !== null && $search_date !== null && $date_from === null){
            $result = $this->query('SELECT a.* FROM attend_headerviews a '
                . 'WHERE a.classlevel_id="'.$classlevel_id.'" AND a.academic_term_id="'.$term_id.'" '
                . 'AND a.attend_date="'.$search_date.'" AND a.employee_id="'.AuthComponent::user('type_id').'" ORDER BY a.attend_date DESC');
        }else if($classlevel_id !== null && $date_from !== null && $date_to !== null && $search_date === null){
            $result = $this->query('SELECT a.* FROM attend_headerviews a '
                . 'WHERE a.classlevel_id="'.$classlevel_id.'" AND a.academic_term_id="'.$term_id.'" '
                . 'AND a.attend_date BETWEEN "'.$date_from.'" AND "'.$date_to.'" AND a.employee_id="'.AuthComponent::user('type_id').'" ORDER BY a.attend_date DESC');
        }else {
            $result = $this->query('SELECT a.* FROM attend_headerviews a '
                . 'WHERE a.academic_term_id="'.$term_id.'" AND  a.employee_id="'.AuthComponent::user('type_id').'" ORDER BY a.attend_date DESC');
        }
        return $result;
    }
    
    //Find all the attenance details for those present and absent
    public function findAttendDetails($attend_id, $year_id, $class_id) {
        return $this->query('SELECT b.attend_id, a.* FROM students_classlevelviews a RIGHT OUTER JOIN attend_details b'
                . ' ON a.student_id=b.student_id WHERE b.attend_id="'.$attend_id.'" AND a.academic_year_id ="'.$year_id.'" AND a.class_id="'.$class_id.'"'
                . ' UNION ALL'
                . ' SELECT -1, a.* FROM students_classlevelviews a WHERE a.student_id NOT IN ('
                . ' SELECT student_id FROM attend_details WHERE attend_id="'.$attend_id.'")'
                . ' AND a.academic_year_id="'.$year_id.'" AND a.class_id="'.$class_id.'"');
    }
    
    //Find all the attenance details for those present
    public function findStudentsPresent($attend_id) {
        return $this->query('SELECT a.student_id, a.student_name, a.student_no FROM students_classlevelviews a RIGHT OUTER JOIN'
            . ' attend_details b ON a.student_id=b.student_id WHERE b.attend_id="'.$attend_id.'"');
    }
    
    //Find all the attenance details for those absent
    public function findStudentsAbsent($attend_id, $year_id, $class_id) {
        return $this->query('SELECT a.student_id, a.student_name, a.student_no FROM students_classlevelviews a WHERE a.student_id NOT IN'
            . ' (SELECT student_id FROM attend_details WHERE attend_id="'.$attend_id.'") AND '
            . ' a.academic_year_id="'.$year_id.'" AND a.class_id="'.$class_id.'"');
    }
    
    //Find all the attenance details for those absent
    public function searchSummary($term_id, $classlevel_id) {
        if($classlevel_id === null){
            $result = $this->query('SELECT a.* FROM attend_headerviews a WHERE a.employee_id="'.AuthComponent::user('type_id').'"'
                . ' AND a.academic_term_id="'.$term_id.'" GROUP BY a.class_id, a.academic_term_id');
        }else{
            $result = $this->query('SELECT a.* FROM attend_headerviews a WHERE a.employee_id="'.AuthComponent::user('type_id').'"'
                . ' AND a.academic_term_id="'.$term_id.'" AND a.classlevel_id="'.$classlevel_id.'" GROUP BY a.class_id, a.academic_term_id');
        }
        return $result;
    }  
    
    //Find all the attenance summary for number of days present and absent
    public function findAttendDaysSummary($term_id, $class_id) {
        $result = null;
        $res = $this->query('SELECT fun_getAttendSummary("'.$term_id.'", "'.$class_id.'")');
        if($res) {
            $result = $this->query('SELECT a.* FROM AttendSummaryResultTable a');
        }
        return $result;
    }  
    
    //Find all the attenance summary for number of days present and absent
    public function findAttendDaysDetails($term_id, $class_id, $stud_id) {
        return $this->query('SELECT c.student_no, c.student_name, b.attend_date, b.class_name, b.academic_term, b.head_tutor, 1 AS attend_status_id, "Present" AS attend_status'
                . ' FROM attend_headerviews b INNER JOIN attend_details a ON a.attend_id=b.attend_id INNER JOIN students_classlevelviews c ON c.student_id=a.student_id'
                . ' WHERE b.class_id="'.$class_id.'" AND b.academic_term_id ="'.$term_id.'" AND a.student_id="'.$stud_id.'"'
                . ' UNION ALL'
                . ' SELECT null, null, c.attend_date, c.class_name, c.academic_term, c.head_tutor, 2, "Absent" FROM attend_headerviews c'
                . ' WHERE c.attend_id NOT IN (SELECT b.attend_id FROM attend_headerviews b INNER JOIN attend_details a ON a.attend_id=b.attend_id'
                . ' WHERE b.class_id="'.$class_id.'" AND b.academic_term_id="'.$term_id.'" AND a.student_id="'.$stud_id.'")'
                . ' AND c.class_id="'.$class_id.'" AND c.academic_term_id="'.$term_id.'" ORDER BY attend_date DESC');
        
        
//        $result = null;
//        $res = $this->query('SELECT fun_getAttendDetails("'.$term_id.'", "'.$class_id.'", "'.$stud_id.'")');
//        if($res) {
//            $result = $this->query('SELECT a.* FROM AttendDetailsResultTable a');
//        }
//        return $result;
    }  
    
}
