<?php
App::uses('AppController', 'Controller');
App::uses('BlowfishPasswordHasher', 'Controller/Component/Auth');
//App::uses('CakeEmail', 'Network/Email');

//App::import('Vendor', 'phpmailer', array('file' => 'phpmailer'.DS.'PHPMailerAutoload.php'));
//App::import('Vendor','PHPMailer',array('file'=>'PHPMailer/PHPMailerAutoload.php'));

// app/Controller/UsersController.php
class UsersController extends AppController {

    public $components = array('Paginator', 'Session');

    public function beforeFilter() {
        parent::beforeFilter();
        $this->masterRedirect();
    }
    
    public function login() {
//         $email = 'kingsley4united@yahoo.com';         
//         $admin_email = 'smartschool@yahoo.com';
//         $name = 'SmartSchoolApp Emailer';
//         $subject = 'Solid Step';
//         $msg_body = 'My message';
//         
//         // just to test out the sending email using SMTP is OK, create a method that will be able to access from public
//        $this->sendMail($msg_body, $subject, $admin_email, $email, $name);

         
         $this->set('title_for_layout','Login');
         $this->layout = 'default_login'; 
        //if already logged-in, redirect
        if($this->Session->check('Auth.User')){
            $group_alias = $this->Auth->user('group_alias');
            $status_id = $this->Auth->user('status_id');
            if($group_alias === 'expired_users' || $status_id !== '1'){
                $this->setFlashMessage('Your Access Has Been Restricted...Please Contact your Superior if you are Eligible to Access this App!!!', 2);
                return $this->redirect($this->Auth->logout());
            }
            $role = $this->Auth->user('user_role_id');
            $this->setFlashMessage('Welcome, '. $this->Auth->user('display_name'), 1);
            return ($role === '1' || $role === '2') ? $this->redirect(array('controller' => 'home', 'action' => 'index')) : $this->redirect($this->Auth->redirect());
        }
         
        // if we get the post information, try to authenticate
        if ($this->request->is('post')) {
            if ($this->Auth->login()) {
//                $id = $this->Auth->user('type_id');
//                $role = $this->Auth->user('user_role_id');
//                
//                if($role === '1'){
//                    $options = array('conditions' => array('Sponsor.' . $spo->primaryKey => $id));
//                    $this->set('login_user', $spo->find('first', $options));
//                }else if($role === '2'){
//                    $options = array('conditions' => array('Student.' . $stu->primaryKey => $id));
//                    $this->set('login_user', $stu->find('first', $options));
//                }else {
//                    $options = array('conditions' => array('Employee.' . $emp->primaryKey => $id));
//                    $this->set('login_user', $emp->find('first', $options));
//                }
                $group_alias = $this->Auth->user('group_alias');
                $status_id = $this->Auth->user('status_id');
                if($group_alias === 'expired_users' || $status_id !== '1'){
                    $this->setFlashMessage('Your Access Has Been Restricted...Please Contact your Superior if you are Eligible to Access this App!!!', 2);
                    return $this->redirect($this->Auth->logout());
                }
                $role = $this->Auth->user('user_role_id');
                $this->setFlashMessage('Welcome, '. $this->Auth->user('display_name'), 1);
                return ($role === '1' || $role === '2') ? $this->redirect(array('controller' => 'home', 'action' => 'index')) : $this->redirect($this->Auth->redirect());
                //$this->redirect(array('controller' => 'students', 'action' => 'index'));
            } else {
                $this->setFlashMessage('Invalid username or password, try again.', 2);
            }
        } 
    }

    public function logout() {
        CakeSession::delete('View_redirect');
        return $this->redirect($this->Auth->logout());
    }

    public function index() { 
        $this->set('title_for_layout','Users');
        //$this->layout = 'default_app'; 
        //$this->User->recursive = 0;
        $result = $this->Acl->check($this->group_alias, 'UsersController', 'read');
        if($result){
            $this->set('users', $this->User->find('all'));
        }else{
            $this->accessDenialError();
        }
    }

    public function register() {  
        $this->set('title_for_layout', 'Create New User');
        $result = $this->Acl->check($this->group_alias, 'UsersController', 'create');
        if($result){
            $this->loadModels('UserRole');
            //$this->layout = 'default_app';
            if ($this->request->is('post')) {
                $this->User->create();
                if ($this->User->save($this->request->data)) {
                    $this->setFlashMessage('The user has been saved.', 1);
                    return $this->redirect(array('action' => 'index'));
                }
                $this->setFlashMessage('The user could not be saved. Please, try again.', 2);
            }
        }else{
            $this->accessDenialError();
        }
    }
    
    public function forget_password() {
        if ($this->request->is('ajax')) {
            $this->layout = null;
            $this->autoRender = false;
            $output = '';
            $username = $this->request->data['User']['username'];
            $options = array('conditions' => array(
                    'User.username' => $username,
                    'User.status_id' => 1
                )
            );
            $result = $this->User->find('first', $options);
            $result = (!empty($result['User'])) ? $result : false;
            if($result){
                $email = null;
                $pass = $this->User->generatePassword();
                $no = null;
                $this->User->id = $result['User']['user_id'];
                $this->User->data['User']['password'] = $pass;
                //Employee
                if($result['User']['user_role_id'] > 2){
                    $Employee = ClassRegistry::init('Employee');
                    $emp = $Employee->find('first', array('conditions' => array('Employee.employee_id' => $result['User']['type_id'])));
                    $email = $emp['Employee']['email'];
                    $no = $emp['Employee']['mobile_number1'];
                }
                //Sponsor
                else {
                    $Sponsor = ClassRegistry::init('Sponsor');
                    $spn = $Sponsor->find('first', array('conditions' => array('Sponsor.sponsor_id' => $result['User']['type_id'])));
                    $email = $spn['Sponsor']['email'];
                    $no = $spn['Sponsor']['mobile_number1'];
                }
                if ($this->User->save()) {
                    $msg = 'Welcome To '.APP_NAME.' Application Username: '.$username.', Your Password Has Been Reset To Password: '.$pass.' to access the portal, login via '.DOMAIN_URL;
                    $msg_email = 'Welcome To '.APP_NAME.' Application <br><br>Username: '.$username.', <br>Your Password Has Been Reset To Password: '.$pass.' <br><br>to access the portal, login via '.DOMAIN_URL;
                    //Send SMS
                    $this->User->SendSMS($no, $msg);
                    //Send Mail
                    $check = null;

                    $name = $result['User']['display_name'];
                    $msg_body = 'Find Below your username and password to access the school app<br><br>';
                    $msg_body .= $msg_email;
                    if($email){                                 
                        $check = $this->User->sendMail($msg_body, 'Password Reset', $email, $name);
                    } 
                    $output = 'Your Password Has Been Reset... '.$check;
                    $this->setFlashMessage($output, 1);
                }
            }  else {
                $output = 'Invalid User.';
                $this->setFlashMessage($output, 2);
            }
            echo $output;
        }
    }
    
    public function adjust($encrypt_id = null) {
        $this->set('title_for_layout','Modify Existing Student Record');
        $result = $this->Acl->check($this->group_alias, 'UsersController', 'update');
        if($result){
            $userRole = ClassRegistry::init('UserRole');
            $this->loadModels('UserRole');
            $this->loadModels('Status');
            $decrypt_id = $this->encryption->decode($encrypt_id);
            $this->User->id = $decrypt_id;
            
            if (!$this->User->exists()) {
                $this->accessDenialError('Invalid User Record Requested for Modification', 2);
            }
            if ($this->request->is(array('post', 'put'))) {
                $data = $this->request->data['User'];
                $status = $data['status_id'];
                $role_id = $data['user_role_id'];
                if($status === '1'){
                    $Role = $userRole->find('first', array('conditions' => array('UserRole.' . $userRole->primaryKey => $role_id)));
                    $data['group_alias'] = $Role['UserRole']['group_alias'];
                }else {
                    $data['group_alias'] = 'expired_users';
                }                
                if ($this->User->save($data)) {
                    $this->setFlashMessage('The User Record has been Updated.', 1);   
                    return $this->redirect(array('action' => 'index'));
                } else {
                    $this->setFlashMessage('The User Record could not be updated. Please, try again.', 2);
                }
            } else {
                $options = array('conditions' => array('User.' . $this->User->primaryKey => $decrypt_id));
                $this->request->data = $this->User->find('first', $options);
                $this->set('user', $this->User->find('first', $options));
            }
        }else{
            $this->accessDenialError();
        }
    }

    //Password Change
    public function change() {
        $this->set('title_for_layout','Password Change');
        if ($this->request->is('ajax')) {
            $this->layout = null;
            $this->autoRender = false;
            $id = $this->Auth->user('user_id');
            $old_pass = $this->request->data['User']['old_pass'];
            $new_pass = $this->request->data['User']['new_pass'];
            $new_pass2 = $this->request->data['User']['new_pass2'];
            $user = $this->User->find('first', array('conditions' => array('User.' . $this->User->primaryKey => $id)));
            $storedHash = $user['User']['password'];
            $newHash = Security::hash($old_pass, 'blowfish', $storedHash);
            //$output = null;
            if($storedHash === $newHash){
                if($new_pass === $new_pass2){                    
                    $this->User->id = $id;
                    $output = ($this->User->saveField('password', $new_pass2)) ? 1 : 0;
                }else{
                    $output = -1;
                }
            }else{
                $output = -2;
            }
            echo trim($output);
        }
    }
    
    //Update User Status
    public function statusUpdate() {
        if ($this->request->is('ajax')) {
            $this->layout = null;
            $this->autoRender = false;
            $userRole = ClassRegistry::init('UserRole');
            $this->User->id = $this->request->data('user_id');
            if (!$this->User->exists()) {
                echo 'Invalid User Record Requested for Modification';
            }else{            
                $User = $this->User->find('first', array('conditions' => array('User.' . $this->User->primaryKey => $this->request->data('user_id'))));
                $this->User->data['User']['status_id'] = $this->request->data('status_id');
                if($this->request->data('status_id') === '1'){
                $Role = $userRole->find('first', array('conditions' => array('UserRole.' . $userRole->primaryKey => $User['User']['user_role_id'])));
                    $this->User->data['User']['group_alias'] = $Role['UserRole']['group_alias'];
                }else {
                    $this->User->data['User']['group_alias'] = 'expired_users';
                } 
                echo ($this->User->save()) ? 1 : 0;
            }
        }
    }
    
}