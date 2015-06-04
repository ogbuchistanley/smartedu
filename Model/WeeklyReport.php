<?php
App::uses('AppModel', 'Model');
/**
 * Class Model
 *
 * @property Classlevel $Classlevel
 */
class WeeklyReport extends AppModel {

	public $primaryKey = 'weekly_report_id';
    
    public $belongsTo = array(
		'WeeklyDetailSetup' => array(
			'className' => 'WeeklyDetailSetup',
			'foreignKey' => 'weekly_detail_setup_id',
			'conditions' => '',
			'fields' => '',
			'order' => ''
		),
        'SubjectClasslevel' => array(
            'className' => 'SubjectClasslevel',
            'foreignKey' => 'subject_classlevel_id',
            'conditions' => '',
            'fields' => '',
            'order' => ''
        )
	);

	public function getWeeklyDetailReportSetup($sub_class_id, $classgroup_id, $term_id){
		$result = $this->query('SELECT null AS marked_status, null AS subject_classlevel_id, null AS notification_status, a.* FROM weekly_setupviews a WHERE a.classgroup_id="'.$classgroup_id.'" AND a.academic_term_id="'.$term_id.'"
		 AND a.weekly_report_no NOT IN
			(SELECT d.weekly_report_no FROM weekly_setupviews d INNER JOIN weekly_reports e ON d.weekly_detail_setup_id=e.weekly_detail_setup_id
			WHERE d.classgroup_id="'.$classgroup_id.'" AND e.subject_classlevel_id="'.$sub_class_id.'" AND d.academic_term_id="'.$term_id.'")
            UNION
            SELECT b.marked_status, b.subject_classlevel_id, b.notification_status, a.* FROM weekly_setupviews a INNER JOIN weekly_reports b
			ON a.weekly_detail_setup_id=b.weekly_detail_setup_id
			WHERE a.classgroup_id="'.$classgroup_id.'" AND b.subject_classlevel_id="'.$sub_class_id.'" AND a.academic_term_id="'.$term_id.'" ORDER BY weekly_report_no');
		return $result;
	}

	public function proc_insertWeeklyReportDetail($weekly_report_id){
		$result = $this->query('Call proc_insertWeeklyReportDetail("'.$weekly_report_id.'")');
		return $result;
	}

	//Get all the weekly reports that are due for submission
	public function getWeeklyReportDetails(){
		$result = $this->query('SELECT a.* FROM weeklyreport_studentdetailsviews a WHERE submission_date=CURDATE() - INTERVAL 1 DAY
		AND a.marked_status=1 GROUP BY a.student_id');
		return $result;
	}

	//Get all the weekly reports that are due for submission
	public function getStudentMidTermReport($term_id, $class_id, $student_id){
		$result = null;
		$result[0] = $this->query('SELECT a.* FROM weeklyreport_studentdetailsviews a WHERE a.academic_term_id="'.$term_id.'"
		AND a.class_id="'.$class_id.'" AND a.student_id="'.$student_id.'" AND a.marked_status=1 GROUP BY a.subject_name ORDER BY a.subject_name');
		$result[1] = $this->query('SELECT MAX(marked_report) as marked_report FROM (SELECT COUNT(a.subject_classlevel_id) AS marked_report FROM weeklyreport_studentdetailsviews a WHERE a.academic_term_id="'.$term_id.'"
		AND a.class_id="'.$class_id.'" AND a.student_id="'.$student_id.'" AND a.marked_status=1 GROUP BY a.subject_classlevel_id) as marked_report');
		return $result;
	}
}
