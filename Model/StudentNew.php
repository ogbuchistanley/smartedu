<?php
// app/Model/User.php
App::uses('AppModel', 'Model');
//App::uses('BlowfishPasswordHasher', 'Controller/Component/Auth');

class StudentNew extends AppModel {

    public $useTable = 'students';
    
    public $primaryKey = 'student_id';

    public $displayField = 'first_name';

    public function beforeSave($options = array()) {
        if (!isset($this->data[$this->alias]['student_id'])) {
            $this->data[$this->alias]['created_at'] = $this->dateFormatBeforeSave();
            $this->data[$this->alias]['created_by'] = AuthComponent::user('type_id');
        }
        //$this->data[$this->alias]['updated_at'] = $this->dateFormatBeforeSave();
        return parent::beforeSave($options);
    }

    public function afterSave($created, $options = array()) {
        $studClass = ClassRegistry::init('StudentsClass');
        $term_id = ClassRegistry::init('AcademicTerm');
        $id = $this->id;
        $no = trim('STD'. str_pad($id, 4, '0', STR_PAD_LEFT));

        if($created){
            $class_id = $this->data['StudentNew']['class_id'];

            //Update The Student ID
            $this->saveField('student_no', $no);

            if($class_id !== ''){
                $studClass->create();
                $studClass->data['StudentsClass']['student_id'] = $id;
                $studClass->data['StudentsClass']['class_id'] = $class_id;
                $studClass->data['StudentsClass']['academic_year_id'] = $term_id->getCurrentYearID();
                $studClass->save();
            }
        }
    }

    public $validate = array(
        'sponsor_id' => array(
            'notEmpty' => array(
                'rule' => array('notEmpty'),
                'message' => 'A Sponsor Name is required'
            ),
            'rule' => '/^[0-9]+/',
            'message' => 'A Valid Sponsor Name is required'
        ),
        'relationtype_id' => array(
            'notEmpty' => array(
                'rule' => array('notEmpty'),
                'message' => 'A Relationship Type is required',
            )
        ),
        'first_name' => array(
            'notEmpty' => array(
                'rule' => array('notEmpty'),
                'message' => 'A First Name is required',
            )
        ),
        'surname' => array(
            'notEmpty' => array(
                'rule' => array('notEmpty'),
                'message' => 'A Surname is required',
            )
        ),
        'gender' => array(
            'notEmpty' => array(
                'rule' => array('notEmpty'),
                'message' => 'A Gender is required',
            )
        )
    );
}