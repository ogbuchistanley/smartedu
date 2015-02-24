<?php
App::uses('AppModel', 'Model');
/**
 * ExamDetail Model
 *
 * @property Exam $Exam
 * @property Student $Student
 */
class SpouseDetail extends AppModel {

/**
 * Primary key field
 *
 * @var string
 */
    public $primaryKey = 'spouse_detail_id';


	//The Associations below have been created with all possible keys, those that are not needed can be removed

/**
 * belongsTo associations
 *
 * @var array
 */
    public $belongsTo = array(
        'Employee' => array(
            'className' => 'Employee',
            'foreignKey' => 'employee_id',
            'conditions' => '',
            'fields' => '',
            'order' => ''
        )
    );
}
