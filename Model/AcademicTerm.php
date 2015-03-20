<?php
App::uses('AppModel', 'Model');
/**
 * AcademicTerm Model
 *
 * @property AcademicYear $AcademicYear
 */
class AcademicTerm extends AppModel {

    public $primaryKey = 'academic_term_id';

    public $displayField = 'academic_term';
    public $academic_term_id = 'academic_term_id';

    public $belongsTo = array(
        'AcademicYear' => array(
                'className' => 'AcademicYear',
                'foreignKey' => 'academic_year_id',
                'conditions' => '',
                'fields' => '',
                'order' => ''
        )
    );
    
    public function beforeSave($options = array()) {
        if (!isset($this->data[$this->alias]['academic_term_id'])) {
            $this->data[$this->alias]['created_at'] = $this->dateFormatBeforeSave();
        }
        return parent::beforeSave($options);
    }
        
    public function getCurrentTermID(){
        $options = array(
            'conditions' => array('AcademicTerm.term_status_id' => 1),
            'fields' => array('AcademicTerm.academic_term_id', 'AcademicTerm.term_status_id'),
            'limit' => 1,
        );
        $results = $this->find('first', $options);
        if($results) {
            $result = array_shift($results);
            return $result['academic_term_id'];
        }
        return '';
    }
    
    public function getCurrentTermName(){
        $options = array(
            'conditions' => array('AcademicTerm.term_status_id' => 1),
            'fields' => array('AcademicTerm.academic_term', 'AcademicTerm.term_status_id'),
            'limit' => 1,
        );
        $results = $this->find('first', $options);
        if($results) {
            $result = array_shift($results);
            return $result['academic_term'];
        }
        return '';
    }
    
    public function getCurrentYearID(){
        $options = array(
            'conditions' => array('AcademicTerm.term_status_id' => 1),
            'fields' => array('AcademicTerm.academic_term_id', 'AcademicTerm.term_status_id', 'AcademicTerm.academic_year_id'),
            'limit' => 1,
        );
        $results = $this->find('first', $options);
        if($results) {
            $result = array_shift($results);
            return $result['academic_year_id'];
        }
        return '';
    }
    
    public function getCurrentYearName(){
        $options = array(
            'conditions' => array('AcademicTerm.term_status_id' => 1),
            'fields' => array('AcademicYear.academic_year'),
            'limit' => 1,
        );
        $results = $this->find('first', $options);
        if($results) {
            $result = array_shift($results);
            return $result['academic_year'];
        }
        return '';
    }
    
    public function getYearID($term_id){
        $options = array(
            'conditions' => array('AcademicTerm.academic_term_id' => $term_id),
            'fields' => array('AcademicTerm.academic_term_id', 'AcademicTerm.academic_year_id'),
            'limit' => 1,
        );
        $results = $this->find('first', $options);
        if($results) {
            $result = array_shift($results);
            return $result['academic_year_id'];
        }
        return '';
    }
    
}
