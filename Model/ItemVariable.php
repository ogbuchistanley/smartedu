<?php
App::uses('AppModel', 'Model');
/**
 * AcademicYear Model
 *
 */
class ItemVariable extends AppModel {

    public $primaryKey = 'item_variable_id';

    public function proc_processItemVariable($item_variable_id){
        $result = $this->query('CALL `proc_processItemVariable`("'.$item_variable_id.'")');
        return $result;
    }
}
