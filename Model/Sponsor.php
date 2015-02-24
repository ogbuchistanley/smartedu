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
        //$this->data[$this->alias]['updated_at'] = $this->dateFormatBeforeSave();
        return parent::beforeSave($options);
    }
    
     public function afterSave($created, $options = array()) {
        $User = ClassRegistry::init('User');
        $userRole = ClassRegistry::init('UserRole');
        $Role = $userRole->find('first', array('conditions' => array('UserRole.' . $userRole->primaryKey => 1)));
        $id = $this->id;
        $no = trim(strtolower('spn'. str_pad($id, 4, '0', STR_PAD_LEFT)));
        $ext = '.jpg';
        $val = 'sponsors/'.$id.$ext;
         if($created){
            $this->query('UPDATE sponsors SET sponsor_no=CONCAT("spn", REPEAT("0", 4-LENGTH("'.$id.'")), '
                . 'CAST("'.$id.'" AS CHAR(10))) WHERE sponsor_id="'.$id.'"');
             if(isset($id)){
                $User->create();
                $User->data['User']['username'] = $no;
                $User->data['User']['password'] = 'Password1';
                $User->data['User']['display_name'] = trim(strtoupper($this->data[$this->alias]['first_name'] . ' ' . ucwords($this->data[$this->alias]['other_name'])));
                $User->data['User']['type_id'] = $id;
                $User->data['User']['group_alias'] = $Role['UserRole']['group_alias'];
                $User->data['User']['image_url'] = $val;
                $User->data['User']['user_role_id'] = 1;
                if($User->save()) {
                    //Send SMS
                    //$mobile_no = $this->data[$this->alias]['mobile_number1'];
                    //$this->SendSMS($mobile_no, 'SmartSchool', 'Username = '.trim(strtolower($no)).' and Password = Password1');
                    //Send Mail
                    $email = $this->data[$this->alias]['email'];
                    $name = $this->data[$this->alias]['first_name'] . ' ' . $this->data[$this->alias]['other_name'];
                    $msg_body = 'Find Below your username and password to access the school app<br><br>';
                    $msg_body .= 'Username: '.$no.' <br>Password: Password1';
                    if(!empty($email)){                                 
                        $this->sendMail($msg_body, 'Authentication', $email, $name);
                    } 
                }
            }
            //$this->createNewUser($no, $this->data[$this->alias]['first_name'], $this->data[$this->alias]['other_name'], $id, $val, 1);
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
        'occupation' => array(
            'notEmpty' => array(
                'rule' => array('notEmpty'),
                'message' => 'A Occupation is required',                
            )
        ),
//        'sponsorship_type_id' => array(
//            'notEmpty' => array(
//                'rule' => array('notEmpty'),
//                'message' => 'A Sponsorship Type is required',                
//            )
//        )
    );
}