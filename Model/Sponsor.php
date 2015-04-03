<?php
// app/Model/User.php
App::uses('AppModel', 'Model');
App::uses('BlowfishPasswordHasher', 'Controller/Component/Auth');

class Sponsor extends AppModel {

	public $primaryKey = 'sponsor_id';

	public $displayField = 'first_name';
    
    public function beforeSave($options = array()) {
        if (!isset($this->data[$this->alias]['sponsor_id'])) {
            $this->data[$this->alias]['created_at'] = $this->dateFormatBeforeSave();
            $this->data[$this->alias]['created_by'] = AuthComponent::user('type_id');
        }
        if(isset($this->data[$this->alias]['image_url'])){
            $image_url = $this->data[$this->alias]['image_url']['name'];
            $this->data[$this->alias]['image_url'] = basename($image_url);
            $ext = pathinfo($image_url, PATHINFO_EXTENSION);
            if(isset($this->data[$this->alias]['sponsor_id'])) {
                $this->data[$this->alias]['image_url'] = 'sponsors/' . $this->data[$this->alias]['sponsor_id'] . '.' . $ext;
            }
        }
        //$this->data[$this->alias]['updated_at'] = $this->dateFormatBeforeSave();
        return parent::beforeSave($options);
    }
    
     public function afterSave($created, $options = array()) {
         $id = $this->id;
         $UserModel = ClassRegistry::init('User');
         $UserModel->id = AuthComponent::user('user_id');
         //$no = 'emp'. str_pad($id, 4, '0', STR_PAD_LEFT);
         if(isset($this->data[$this->alias]['image_url'])){
             $image_url = $this->data[$this->alias]['image_url'];
             $ext = pathinfo($image_url, PATHINFO_EXTENSION);
             $name = 'sponsors/' . $id . '.' . $ext;
             //User Image URL
             $UserModel->saveField('image_url', $name);
        }
    }
    
    public $belongsTo = array(
//        'User' => array(
//                'className' => 'User',
//                'foreignKey' => 'type_id',
//        ),
        'Salutation' => array(
                'className' => 'Salutation',
                'foreignKey' => 'salutation_id',
        ),
//        'SponsorshipType' => array(
//			'className' => 'SponsorshipType',
//			'foreignKey' => 'sponsorship_type_id',
//		),
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
		)
	);
    
    public $hasMany = array(
		'Student' => array(
			'className' => 'Student',
			'foreignKey' => 'sponsor_id'
		)
	);
    
    public $validate = array(
        'salutation_id' => array(
            'notEmpty' => array(
                'rule' => array('notEmpty'),
                'message' => 'A Sponsor Title is required'
            )
        ),
        'first_name' => array(
            'notEmpty' => array(
                'rule' => array('notEmpty'),
                'message' => 'A First Name is required',                
            )
        ),
        'other_name' => array(
            'notEmpty' => array(
                'rule' => array('notEmpty'),
                'message' => 'A Other Names is required',                
            )
        ),
//        'email' => array(
//            'rule' => array('email'),
//            'message' => 'Please enter a valid email address',
//            'allowEmpty' => false,
//            'isUnique' => array( 'rule' => 'isUnique', 'message' => 'This email has already been added')
//        ),
        'mobile_number1' => array(
            'notEmpty' => array(
                'rule' => array('notEmpty'),
                'message' => 'A Mobile Number One is required',                
            ),
            'numeric' => array(
                'rule' => array('numeric'),
                'message' => 'A Valid Mobile Number is required',                
            )
        ),
//        'contact_address' => array(
//            'notEmpty' => array(
//                'rule' => array('notEmpty'),
//                'message' => 'A Contact Address is required',
//            )
//        ),
//        'country_id' => array(
//            'notEmpty' => array(
//                'rule' => array('notEmpty'),
//                'message' => 'A Nationality is required',
//            )
//        ),
//        'occupation' => array(
//            'notEmpty' => array(
//                'rule' => array('notEmpty'),
//                'message' => 'A Occupation is required',
//            )
//        ),
        'image_url' => array(
            'uploadError' => array(
                'rule' => 'uploadError',
                'message' => 'The image upload failed.',
                'allowEmpty' => TRUE
            ),
            'fileSize' => array(
                'rule' => array('fileSize', '<=', '1MB'),
                'message' => 'Image must be less than 1MB.',
                'allowEmpty' => TRUE
            )
        )
    );
}