<?php
// app/Model/User.php
App::uses('AppModel', 'Model');
App::import('Vendor','PHPMailer',array('file'=>'PHPMailer/PHPMailerAutoload.php'));

class Employee extends AppModel {

	public $primaryKey = 'employee_id';

	public $displayField = 'first_name';
        
    public $virtualFields = array(
        'full_name' => "CONCAT(UCASE(Employee.first_name), ', ', Employee.other_name)"
    );
    
    public function beforeSave($options = array()) {
        if (!isset($this->data[$this->alias]['employee_id'])) {
            $this->data[$this->alias]['created_at'] = $this->dateFormatBeforeSave();
            $this->data[$this->alias]['created_by'] = AuthComponent::user('type_id');
        }
        if(isset($this->data[$this->alias]['image_url'])){
            $this->data[$this->alias]['image_url'] = basename($this->data[$this->alias]['image_url']['name']);
            if(isset($this->data[$this->alias]['employee_id'])) {
                $image_url = $this->data[$this->alias]['image_url'];
                $this->data[$this->alias]['image_url'] = $this->data[$this->alias]['employee_id'].'.'.explode('.', $image_url)[1];
            }
        }
        if(isset($this->data[$this->alias]['identity_expiry_date'])){
            $this->data[$this->alias]['identity_expiry_date'] = $this->dateFormat($this->data[$this->alias]['identity_expiry_date']);
        }
        if(isset($this->data[$this->alias]['birth_date'])) {
            $this->data[$this->alias]['birth_date'] = $this->dateFormatBeforeSave($this->data[$this->alias]['birth_date']);
        }
        $this->data[$this->alias]['status_id'] = (isset($this->data[$this->alias]['status_id'])) ? $this->data[$this->alias]['status_id'] : 1;
        return parent::beforeSave($options);
    }
    public function afterSave($created, $options = array()) {
        $id = $this->id;
        //$no = 'emp'. str_pad($id, 4, '0', STR_PAD_LEFT);
        $ext = '.jpg';   
        if(isset($this->data[$this->alias]['image_url'])){
            $image_url = $this->data[$this->alias]['image_url'];
            $ext = explode('.', $image_url)[1];
            $this->saveField('image_url', "employees/'.$id.'.'.$ext.'");
//            $this->query('UPDATE employees SET '
//                . 'image_url="employees/'.$id.'.'.$ext.'", '
//                . 'employee_no=CONCAT("emp", REPEAT("0", 4-LENGTH("'.$id.'")), CAST("'.$id.'" AS CHAR(10))) '
//                . 'WHERE employee_id="'.$id.'"');
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
//        'EmployeeType' => array(
//			'className' => 'EmployeeType',
//			'foreignKey' => 'employee_type_id',
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
		),
        'Status' => array(
			'className' => 'Status',
			'foreignKey' => 'status_id',
		)
	);
    
    public $validate = array(
        'salutation_id' => array(
            'notEmpty' => array(
                'rule' => array('notEmpty'),
                'message' => 'A Employee Title is required'
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
        'marital_status' => array(
            'notEmpty' => array(
                'rule' => array('notEmpty'),
                'message' => 'A Marital Status is required',                
            )
        ),
        'email' => array(
            'rule' => array('email'),
            'message' => 'Please enter a valid email address',
            'allowEmpty' => false,
            'isUnique' => array( 'rule' => 'isUnique', 'message' => 'This email has already been added')
        ),
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
        'contact_address' => array(
            'notEmpty' => array(
                'rule' => array('notEmpty'),
                'message' => 'A Contact Address is required',                
            )
        ),
        'country_id' => array(
            'notEmpty' => array(
                'rule' => array('notEmpty'),
                'message' => 'A Nationality is required',                
            )
        ),
        'next_ofkin_name' => array(
            'notEmpty' => array(
                'rule' => array('notEmpty'),
                'message' => 'Next of Kin Full Name is required',                
            )
        ),
        'next_ofkin_number' => array(
            'notEmpty' => array(
                'rule' => array('notEmpty'),
                'message' => 'Next of Kin Mobile Number is required',                
            )
        ),
        'next_ofkin_relate' => array(
            'notEmpty' => array(
                'rule' => array('notEmpty'),
                'message' => 'Next of Kin Relatioship is required',                
            )
        ),
//        'employee_type_id' => array(
//            'notEmpty' => array(
//                'rule' => array('notEmpty'),
//                'message' => 'A Employee Type is required',                
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