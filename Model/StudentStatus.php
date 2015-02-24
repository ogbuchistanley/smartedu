<?php
App::uses('AppModel', 'Model');
/**
 * StudentStatus Model
 *
 */
class StudentStatus extends AppModel {

/**
 * Use table
 *
 * @var mixed False or table name
 */
	public $useTable = 'student_status';

/**
 * Primary key field
 *
 * @var string
 */
	public $primaryKey = 'student_status_id';

/**
 * Display field
 *
 * @var string
 */
	public $displayField = 'student_status';

}
