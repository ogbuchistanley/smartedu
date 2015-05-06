<?php
App::uses('AppModel', 'Model');
/**
 * WeeklyDetail Model
 *
 */
class WeeklyReportDetail extends AppModel {

	public $primaryKey = 'weekly_report_detail_id';
    
    public $belongsTo = array(
		'WeeklyReport' => array(
			'className' => 'WeeklyReport',
			'foreignKey' => 'weekly_report_id',
			'conditions' => '',
			'fields' => '',
			'order' => ''
		),
        'Student' => array(
            'className' => 'Student',
            'foreignKey' => 'student_id',
            'conditions' => '',
            'fields' => '',
            'order' => ''
        )
	);
}
