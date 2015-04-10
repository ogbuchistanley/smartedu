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
        if(isset($this->data[$this->alias]['term_begins']) && $this->data[$this->alias]['term_begins'] !== '') {
            $this->data[$this->alias]['term_begins'] = $this->dateFormatBeforeSave($this->data[$this->alias]['term_begins']);
        }
        if(isset($this->data[$this->alias]['term_ends']) && $this->data[$this->alias]['term_ends'] !== '') {
            $this->data[$this->alias]['term_ends'] = $this->dateFormatBeforeSave($this->data[$this->alias]['term_ends']);
        }
        return parent::beforeSave($options);
    }

    public function getNextTerm($term_id=null){
        $AcademicYear = ClassRegistry::init('AcademicYear');
        $term_id = ($term_id === null) ? $this->getCurrentTermID() : $term_id;
        $record = $this->find('first', array('conditions' => array('AcademicTerm.academic_term_id' => $term_id)));
        $year_id = $record['AcademicTerm']['academic_year_id'];
        $term_type_id = $record['AcademicTerm']['term_type_id'];
        $next_year_id = $AcademicYear->getNextYearID($year_id);

        if($term_type_id == 1) {
            //if its first term then get second term
            return $this->find('first', array('conditions' => array('AcademicTerm.academic_year_id' => $year_id, 'AcademicTerm.term_type_id' => 2)));
        }elseif($term_type_id == 2) {
            //if its second term then get third term
            return $this->find('first', array('conditions' => array('AcademicTerm.academic_year_id' => $year_id, 'AcademicTerm.term_type_id' => 3)));
        }elseif($term_type_id == 3) {
            //if its second term then get third term
            return $this->find('first', array('conditions' => array('AcademicTerm.academic_year_id' => $next_year_id, 'AcademicTerm.term_type_id' => 1)));
        }
        return null;
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
