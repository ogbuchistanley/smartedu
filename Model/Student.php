<?php
App::uses('AppModel', 'Model');

//App::import('model', 'AcademicTerm');

class Student extends AppModel {

	public $primaryKey = 'student_id';

	public $displayField = 'first_name';
    
    public function beforeSave($options = array()) {
        $term_id = ClassRegistry::init('AcademicTerm');
        if (!isset($this->data[$this->alias]['student_id'])) {
            $this->data[$this->alias]['created_at'] = $this->dateFormatBeforeSave();
            $this->data[$this->alias]['created_by'] = AuthComponent::user('type_id');
            
        }
        if(isset($this->data[$this->alias]['image_url'])){
            $image_url = $this->data[$this->alias]['image_url']['name'];
            $this->data[$this->alias]['image_url'] = basename($image_url);
            $ext = pathinfo($image_url, PATHINFO_EXTENSION);
            if(isset($this->data[$this->alias]['student_id'])) {
                $this->data[$this->alias]['image_url'] = 'students/' . $this->data[$this->alias]['student_id'] . '.' . $ext;
            }
        }
        if(isset($this->data[$this->alias]['birth_date'])){
            $this->data[$this->alias]['birth_date'] = $this->dateFormatBeforeSave($this->data[$this->alias]['birth_date']);
        }
        $this->data[$this->alias]['academic_term_id'] = $term_id->getCurrentTermID();        
        //$this->data[$this->alias]['updated_at'] = $this->dateFormatBeforeSave();
        return parent::beforeSave($options);
    }

    public function afterSave($created, $options = array()) {
        $studClass = ClassRegistry::init('StudentsClass');
        $term_id = ClassRegistry::init('AcademicTerm');
        $id = $this->id;
        //$no = 'emp'. str_pad($id, 4, '0', STR_PAD_LEFT);

        if(isset($this->data[$this->alias]['image_url'])){
            $image_url = $this->data[$this->alias]['image_url'];
            $ext = pathinfo($image_url, PATHINFO_EXTENSION);
            $this->query('UPDATE students SET '
                . 'image_url="students/'.$id.'.'.$ext.'", '
                . 'student_no=CONCAT("stu", REPEAT("0", 4-LENGTH("'.$id.'")), CAST("'.$id.'" AS CHAR(10))) '
                . 'WHERE student_id="'.$id.'"');
        }else{
            $this->query('UPDATE students SET student_no=CONCAT("stu", REPEAT("0", 4-LENGTH("'.$id.'")), '
            . 'CAST("'.$id.'" AS CHAR(10))) WHERE student_id="'.$id.'"');
        }
        if($created){
            if($this->data[$this->alias]['class_id'] !== ''){
                $studClass->create();
                $studClass->data['StudentsClass']['student_id'] = $id;
                $studClass->data['StudentsClass']['class_id'] = $this->data[$this->alias]['class_id'];
                $studClass->data['StudentsClass']['academic_year_id'] = $term_id->getCurrentYearID();
                $studClass->save();
            }
        }
    }

    public $belongsTo = array(
		'Sponsor' => array(
			'className' => 'Sponsor',
			'foreignKey' => 'sponsor_id',
		),
        'AcademicTerm' => array(
			'className' => 'AcademicTerm',
			'foreignKey' => 'academic_term_id',
		),
        'RelationshipType' => array(
			'className' => 'RelationshipType',
			'foreignKey' => 'relationtype_id',
		),
        'Country' => array(
			'className' => 'Country',
			'foreignKey' => 'country_id',
		),
        'State' => array(
			'className' => 'State',
			'foreignKey' => 'state_id',
		),
        'LocalGovt' => array(
			'className' => 'LocalGovt',
			'foreignKey' => 'local_govt_id',
		),
        'Classroom' => array(
			'className' => 'Classroom',
			'foreignKey' => 'class_id',
		),
        'StudentStatus' => array(
			'className' => 'StudentStatus',
			'foreignKey' => 'student_status_id',
		)	
	);
    
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
        ),
        'birth_date' => array(
            'notEmpty' => array(
                'rule' => array('notEmpty'),
                'message' => 'A Date of Birth is required',                
            )
        ),
        'country_id' => array(
            'notEmpty' => array(
                'rule' => array('notEmpty'),
                'message' => 'A Nationality is required',                
            )
        ),
//        'religion' => array(
//            'notEmpty' => array(
//                'rule' => array('notEmpty'),
//                'message' => 'A Religion is required',                
//            )
//        ),
        'image_url' => array(
            'uploadError' => array(
                'rule' => 'uploadError',
                'message' => 'The image upload failed.',
                'allowEmpty' => TRUE
            ),
//            'mimeType' => array(
//                'rule' => array('mimeType', array('image/gif', 'image/png', 'image/jpg', 'image/jpeg')),
//                'message' => 'Please only upload images (gif, png, jpg).',
//                'allowEmpty' => TRUE
//            ),
            'fileSize' => array(
                'rule' => array('fileSize', '<=', '1MB'),
                'message' => 'Image must be less than 1MB.',
                'allowEmpty' => TRUE
            )
        )
    );
}
