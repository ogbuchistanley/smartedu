<?php
// app/Model/User.php
App::uses('AppModel', 'Model');

class SubjectGroup extends AppModel {

	public $primaryKey = 'subject_group_id';

	public $displayField = 'subject_group';
   
}