<?php
// app/Model/User.php
App::uses('AppModel', 'Model');
    
class Country extends AppModel {

	public $primaryKey = 'country_id';

	public $displayField = 'country_name';

}