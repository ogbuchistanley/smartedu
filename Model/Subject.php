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

    //Find all the students offering the subjects in a classroom
    public function findStudentsBySubjectClassroom($subject_classlevel_id, $class_id) {
        $result = $this->query('SELECT a.* FROM students_subjectsviews a WHERE a.subject_classlevel_id="'.$subject_classlevel_id.'"
            AND a.class_id="'.$class_id.'" ORDER BY a.student_name');
        return $result;
    }

    //Find the students in a classroom not offering the subject
    public function findStudentsBySubjectsNotClassroom($subject_classlevel_id, $class_id) {
        $query = $this->query('SELECT * FROM subject_classlevelviews a WHERE subject_classlevel_id="'.$subject_classlevel_id.'" LIMIT 1');
        $record = array_shift($query);
        $academic_year_id = $record['a']['academic_year_id'];

        $result = $this->query(
            'SELECT * FROM students_classlevelviews a WHERE a.class_id="'.$class_id.'" AND a.academic_year_id="'.$academic_year_id.'" '
            . 'AND a.student_id NOT IN (SELECT student_id FROM students_subjectsviews a WHERE subject_classlevel_id="'.$subject_classlevel_id.'") ORDER BY a.student_name'
        );
        return $result;
    }

    //Update Subjects Students Registered Table with the list of students
    public function updateStudentsSubjects($subject_classlevel_id, $stud_ids, $class_id) {
        $class_term = $this->query('SELECT a.* FROM subject_classlevels a WHERE a.subject_classlevel_id="'.$subject_classlevel_id.'" LIMIT 1');
        $class_term = ($class_term) ? array_shift($class_term) : false;
        $count = 0;
        if($class_term) {
            $this->query('DELETE FROM subject_students_registers WHERE subject_classlevel_id="'.$subject_classlevel_id.'" AND class_id="'.$class_id.'"');
            $ids = explode(',', $stud_ids);
            for ($i = 0; $i < count($ids); $i++) {
                $out = $this->query('INSERT INTO subject_students_registers(student_id, class_id, subject_classlevel_id)
                              VALUES("'.$ids[$i].'", "'.$class_id.'", "'.$subject_classlevel_id.'")');
                if($out) $count++;
            }
        }
        return $count;
    }

    //Find students that offered a subject in a class for an academic term
    public function findStudentsSubject($term_id, $subject_id, $class_id) {
        return $this->query('SELECT a.*, a.ca1+a.ca2+a.exam AS sum_total'
                . ' FROM examsdetails_reportviews a WHERE a.academic_term_id="'.$term_id.'"'
                . ' AND a.subject_id="'.$subject_id.'"'
                . ' AND a.class_id="'.$class_id.'" ORDER BY sum_total DESC');
    }

    //Find students subject summary analysis in a class for an academic term
    public function findStudentsSubjectSummary($student_id, $subject_id, $class_id, $term_id) {
        $result[0] = $this->query('SELECT b.grade, b.grade_abbr, a.*, (a.ca1+a.ca2+a.exam) AS sum_total, (a.weightageCA1+a.weightageCA2+a.weightageExam) AS wa_total'
            . ' FROM examsdetails_reportviews a INNER JOIN grades b ON a.classgroup_id=b.classgroup_id'
            . ' WHERE a.academic_term_id="'.$term_id.'" AND a.subject_id="'.$subject_id.'"'
            . ' AND (a.ca1+a.ca2+a.exam) BETWEEN b.lower_bound AND b.upper_bound'
            . ' AND a.student_id="'.$student_id.'" LIMIT 1');
        $result[1] = $this->query('SELECT a.ca1+a.ca2+a.exam AS sum_total, COUNT(*) AS count_total,'
            . ' MAX(((a.ca1+a.ca2+a.exam) * 100) / (a.weightageCA1+a.weightageCA2+a.weightageExam)) AS max_total,'
            . ' MIN(((a.ca1+a.ca2+a.exam) * 100) / (a.weightageCA1+a.weightageCA2+a.weightageExam)) AS min_total,'
            . ' AVG(((a.ca1+a.ca2+a.exam) * 100) / (a.weightageCA1+a.weightageCA2+a.weightageExam)) AS avg_total'
            . ' FROM examsdetails_reportviews a'
            . ' WHERE a.academic_term_id="'.$term_id.'" AND a.subject_id="'.$subject_id.'"'
            . ' AND a.class_id="'.$class_id.'" ORDER BY sum_total DESC');

        return $result;

    }
}