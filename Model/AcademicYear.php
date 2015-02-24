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
}
