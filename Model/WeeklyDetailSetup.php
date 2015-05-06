<?php
App::uses('AppModel', 'Model');
/**
 * Class Model
 *
 * @property Classlevel $Classlevel
 */
class WeeklyDetailSetup extends AppModel {

	public $primaryKey = 'weekly_detail_setup_id';
    
    public $belongsTo = array(
		'WeeklyReportSetup' => array(
			'className' => 'WeeklyReportSetup',
			'foreignKey' => 'weekly_report_setup_id',
			'conditions' => '',
			'fields' => '',
			'order' => ''
		)
	);

	public function beforeSave($options = array()) {
		if(isset($this->data[$this->alias]['submission_date'])){
			$this->data[$this->alias]['submission_date'] = $this->dateFormatBeforeSave($this->data[$this->alias]['submission_date']);
		}
		return parent::beforeSave($options);
	}
}
