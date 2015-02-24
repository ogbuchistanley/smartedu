<?php
App::uses('AppModel', 'Model');
/**
 * Status Model
 *
 */
class Status extends AppModel {

/**
 * Use table
 *
 * @var mixed False or table name
 */
	public $useTable = 'status';

/**
 * Primary key field
 *
 * @var string
 */
	public $primaryKey = 'status_id';

/**
 * Display field
 *
 * @var string
 */
	public $displayField = 'status';

}
