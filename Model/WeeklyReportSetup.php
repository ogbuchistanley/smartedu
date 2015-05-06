<?php
App::uses('AppModel', 'Model');
/**
 * Class Model
 *
 * @property Classlevel $Classlevel
 */
class WeeklyReportSetup extends AppModel {

	public $primaryKey = 'weekly_report_setup_id';
    
    public $belongsTo = array(
		'AcademicTerm' => array(
			'className' => 'AcademicTerm',
			'foreignKey' => 'academic_term_id',
			'conditions' => '',
			'fields' => '',
			'order' => ''
		),
        'Classgroup' => array(
            'className' => 'Classgroup',
            'foreignKey' => 'classgroup_id',
            'conditions' => '',
            'fields' => '',
            'order' => ''
        )
	);
}
