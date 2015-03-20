<?php
// app/Model/User.php
App::uses('AppModel', 'Model');
//App::uses('BlowfishPasswordHasher', 'Controller/Component/Auth');
App::import('Vendor','PHPMailer',array('file'=>'PHPMailer/PHPMailerAutoload.php'));

class SponsorNew extends AppModel {

    public $useTable = 'sponsors';
    
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
        $no = trim('PAR'. str_pad($id, 4, '0', STR_PAD_LEFT));
        $val = 'sponsors/'.$id.'.jpg';
        if($created){
            $mobile_no = $this->data[$this->alias]['mobile_number1'];
            $pass = $this->generatePassword();
            $msg = 'Welcome To '.APP_NAME.' Application here is your Username='.$no.' and Password='.$pass.' to access the portal, login via '.DOMAIN_URL;
            $msg_email = 'Welcome To '.APP_NAME.' Application here is your <br><br>Username: '.$no.' <br>Password: '.$pass.' <br><br>to access the portal, login via '.DOMAIN_URL;
            $email = $this->data[$this->alias]['email'];
            $name = $this->data[$this->alias]['first_name'] . ' ' . $this->data[$this->alias]['other_name'];
//            $this->query('UPDATE sponsors SET sponsor_no=CONCAT("PAR", REPEAT("0", 4-LENGTH("'.$id.'")), CAST("'.$id.'" AS CHAR(10))) WHERE sponsor_id="'.$id.'"');
            $User->create();
            $User->data['User']['username'] = $no;
            $User->data['User']['password'] = $pass;
            $User->data['User']['display_name'] = trim(strtoupper($this->data[$this->alias]['first_name'] . ' ' . ucwords($this->data[$this->alias]['other_name'])));
            $User->data['User']['type_id'] = $id;
            $User->data['User']['group_alias'] = $Role['UserRole']['group_alias'];
            $User->data['User']['image_url'] = $val;
            $User->data['User']['user_role_id'] = 1;
            if($User->save()) {
                //Update The Sponsor ID
                $this->saveField('sponsor_no', $no);

                //Send SMS
                $this->SendSMS($mobile_no, $msg);

                //Send Mail
                $msg_body = 'Find Below your username and password to access the school application portal<br><br>';
                $msg_body .= $msg_email;
                if(!empty($email)){
                    $this->sendMail($msg_body, 'Login Details', $email, $name);
                }
            }
            //$this->createNewUser($no, $this->data[$this->alias]['first_name'], $this->data[$this->alias]['other_name'], $id, $val, 1);
        }
    }

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
        'mobile_number1' => array(
            'notEmpty' => array(
                'rule' => array('notEmpty'),
                'message' => 'A Mobile Number is required',
            ),
            'numeric' => array(
                'rule' => array('numeric'),
                'message' => 'A Valid Mobile Number is required',
            )
        ),
    );
}