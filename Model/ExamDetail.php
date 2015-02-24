<?php
App::uses('AppModel', 'Model');
/**
 * ExamDetail Model
 *
 * @property Exam $Exam
 * @property Student $Student
 */
class ExamDetail extends AppModel {

/**
 * Primary key field
 *
 * @var string
 */
	public $primaryKey = 'exam_detail_id';


	//The Associations below have been created with all possible keys, those that are not needed can be removed

/**
 * belongsTo associations
 *
 * @var array
 */
	public $belongsTo = array(
		'Exam' => array(
			'className' => 'Exam',
			'foreignKey' => 'exam_id',
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
