<?php
App::uses('AppModel', 'Model');
/**
 * AcademicYear Model
 *
 */
class AcademicYear extends AppModel {

    public $primaryKey = 'academic_year_id';

    public $displayField = 'academic_year';

    public function beforeSave($options = array()) {
        if (!isset($this->data[$this->alias]['academic_year_id'])) {
            $this->data[$this->alias]['created_at'] = $this->dateFormatBeforeSave();
        }
        return parent::beforeSave($options);
    }

    public function getNextYearID($year_id){
        $SentYear = $this->find('first', array('conditions' => array('AcademicYear.academic_year_id' => $year_id), 'limit' => 1));
        if($SentYear) {
            $year = substr($SentYear['AcademicYear']['academic_year'], -4);
            $results = $this->find('all');
            foreach($results as $result){
                $next_year = substr($result['AcademicYear']['academic_year'], -4);
                if((intval($year) + 1) === intval($next_year)){
                    return $result['AcademicYear']['academic_year_id'];
                    break;
                }
            }
        }
        return null;
    }
}
