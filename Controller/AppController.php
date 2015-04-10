<?php
/**
 * Application level Controller
 *
 * This file is application-wide controller file. You can put all
 * application-wide controller-related methods here.
 *
 * @link          http://cakephp.org CakePHP(tm) Project
 * @package       app.Controller
 * @since         CakePHP(tm) v 0.2.9
 */

App::uses('Controller', 'Controller');

//Loads The Utility Library For Encription
App::uses('Encryption', 'Utility');
//Email Sending
//App::import('Vendor', 'PHPMailer', array('file' => 'PHPMailer/PHPMailerAutoload.php'));
/**
 * Application Controller
 *
 * Add your application-wide methods in the class below, your controllers
 * will inherit them.
 *
 * @package		app.Controller
 * @link		http://book.cakephp.org/2.0/en/controllers.html#the-app-controller
 */
class AppController extends Controller {
    //public $components = array('DebugKit.Toolbar');
        
    public $helpers = array('Html', 'Form', 'Js');
    
    public $group_alias;

    public $master_record_id;

    public $master_record_count;

    //Global Variable for encryption
    public $encryption;

    public $paginator_settings = array(
        'limit' => 3
    );
    //$this->Auth->actionPath = 'controllers/';
    public $components = array(
        'Acl',
        //'DebugKit.Toolbar',
        'Session',
        'Auth' => array(
            'authenticate' => array(
                'Form' => array(
                    'passwordHasher' => 'Blowfish',
                )//'scope' => array('User.status_id' => 1)
            ),
            'loginRedirect' => array('controller' => 'dashboard', 'action' => 'index'),
            'logoutRedirect' => array('controller' => 'users', 'action' => 'login'),
            'authError' => 'You must be logged in to view this page.',
            'loginError' => 'Invalid Username or Password entered, please try again.',
            'actionPath' => 'controllers/'
        )
    );
    
    function simple_encrypt($text) {
        return trim(base64_encode(mcrypt_encrypt(MCRYPT_RIJNDAEL_256, Configure::read('Security.key'), $text, MCRYPT_MODE_ECB, mcrypt_create_iv(mcrypt_get_iv_size(MCRYPT_RIJNDAEL_256, MCRYPT_MODE_ECB), MCRYPT_RAND))));
    }

    function simple_decrypt($text)  {
        return trim(mcrypt_decrypt(MCRYPT_RIJNDAEL_256, Configure::read('Security.key'), base64_decode($text), MCRYPT_MODE_ECB, mcrypt_create_iv(mcrypt_get_iv_size(MCRYPT_RIJNDAEL_256, MCRYPT_MODE_ECB), MCRYPT_RAND)));
    }


    // 1 Success // 2 Error
    function setFlashMessage($msg, $type=0) {
        $temp = 'alert alert-info';
        $icon = '<i class="fa fa-info-circle fa-2x"></i> ';
        if($type === 1){
            $temp = 'alert alert-success';
            $icon = '<i class="fa fa-thumbs-o-up fa-2x"></i> ';
        }else if($type === 2){
            $temp = 'alert alert-danger';
            $icon = '<i class="fa fa-thumbs-o-down fa-2x"></i> ';
        }else if($type === 3){
            $temp = 'alert alert-warning';
            $icon = '<i class="fa fa-warning fa-2x"></i> ';
        }
        $this->Session->setFlash(__('<b>'.$icon.' '.$msg.'</b>'), 'default', array('class' => $temp));
    }

    // only allow the login controllers only
    function beforeFilter() {
        //////////////////////////////////////////////////////////////////////
        //Remove This While on Production Enviroment
        //$this->buildAcl();
        //$this->initDB();

        $this->Auth->allow('login');           
        $this->Auth->allow('forget_password');           
        $this->encryption  = new Encryption();
        // Change layout for Ajax requests
        if ($this->request->is('ajax')) {
            $this->layout = 'ajax';
        }
        if(AuthComponent::user('group_alias')){
            $this->group_alias = AuthComponent::user('group_alias');
        }else{
            $this->group_alias = 'expired_users';
        }

        //Get The Current Master Record That HAs Been Setup
        $MasterSetupModel = ClassRegistry::init('MasterSetup');
        $MasterSetup = $MasterSetupModel->find('first', array('conditions' => array('MasterSetup.master_setup_id' => 1)));
        $val = intval($MasterSetup['MasterSetup']['master_record_id']);

        //Set the master_setup_id to be accessed globally both in views and controllers
        $this->master_record_id = $val;
        $this->master_record_count = 8;
        Configure::write('master_record_id', $val);
        Configure::write('master_record_count', $this->master_record_count);

    }

    //Redirect To The Master Record To Be Setup
    public function masterRedirect(){
        $val = $this->master_record_id;
        if($val === 0)
            $this->redirect(array('controller' => 'records', 'action' => 'academic_year'));
            //$this->response->location(DOMAIN_URL.'/records/academic_year');
        elseif($val === 1)
            $this->redirect(array('controller' => 'records', 'action' => 'index'));
        elseif($val === 2)
            $this->redirect(array('controller' => 'records', 'action' => 'class_group'));
        elseif($val === 3)
            $this->redirect(array('controller' => 'records', 'action' => 'class_level'));
        elseif($val === 4)
            $this->redirect(array('controller' => 'records', 'action' => 'class_room'));
        elseif($val === 5)
            $this->redirect(array('controller' => 'records', 'action' => 'subject_group'));
        elseif($val === 6)
            $this->redirect(array('controller' => 'records', 'action' => 'subject'));
        elseif($val === 7)
            $this->redirect(array('controller' => 'records', 'action' => 'grade'));
    }

    // Set all the access links for all the controllers
    function beforeRender() {        
        $auth = $this->group_alias;
        Configure::write('employee_index', $this->Acl->check($auth, 'EmployeesController/index'));
        Configure::write('employee_register', $this->Acl->check($auth, 'EmployeesController/register', 'create'));
        Configure::write('employee_adjust', $this->Acl->check($auth, 'EmployeesController/adjust', 'update'));
        Configure::write('employee_delete', $this->Acl->check($auth, 'EmployeesController/delete', 'delete'));
        
        Configure::write('student_index', $this->Acl->check($auth, 'StudentsController/index'));
        Configure::write('student_register', $this->Acl->check($auth, 'StudentsController/register', 'create'));
        Configure::write('student_delete', $this->Acl->check($auth, 'StudentsController/delete', 'delete'));
        
        Configure::write('sponsor_index', $this->Acl->check($auth, 'SponsorsController/index'));
        Configure::write('sponsor_register', $this->Acl->check($auth, 'SponsorsController/register', 'create'));
        Configure::write('sponsor_delete', $this->Acl->check($auth, 'SponsorsController/delete', 'delete'));
        
        Configure::write('item_index', $this->Acl->check($auth, 'ItemsController'));
        Configure::write('item_process_fees', $this->Acl->check($auth, 'ItemsController/process_fees'));
        
        Configure::write('classroom_index', $this->Acl->check($auth, 'ClassroomsController'));
        Configure::write('classroom_myclass', $this->Acl->check($auth, 'ClassroomsController/myclass'));
        
        Configure::write('exam_index', $this->Acl->check($auth, 'ExamsController/index'));
        Configure::write('setup_exam', $this->Acl->check($auth, 'ExamsController/setup_exam'));

        Configure::write('subject_index', $this->Acl->check($auth, 'SubjectsController'));
        Configure::write('subject_add2class', $this->Acl->check($auth, 'SubjectsController/add2class'));

        Configure::write('attend_index', $this->Acl->check($auth, 'AttendsController'));
        Configure::write('msg_index', $this->Acl->check($auth, 'MessagesController'));
        Configure::write('record_index', $this->Acl->check($auth, 'RecordsController'));
        Configure::write('user_index', $this->Acl->check($auth, 'UsersController'));
        
        //Disable The Links For Sponsors During Error Displays
        Configure::write('user_role', $this->Auth->user('user_role_id'));
    }
    
    function loadModels($model, $field=null, $order='ASC') {
        $this->loadModel($model);
        if($field != null){
            $result = $this->$model->find('list', array(
                'order' => array($model.'.'.$field => $order)
            )); 
        }else{
            $result = $this->$model->find('list'); 
        }
        $this->set($model.'s', $result);
    }
    
    // Auto Completes The Field
    function autoCompleteField($model, $field_name, $field_id, $field_name2) {
		$this->autoRender = false;
        $response = array();
		$search_string = trim($this->request->query['term']);
		if (!is_null($search_string) && $search_string != '') {
			$results = $this->$model->find('all',
				array(
                    'conditions' => array($model . '.' . $field_name . ' LIKE ' => $search_string . '%'),
					'fields' => array($model . '.' . $field_name, $model . '.' . $field_name2, $model . '.' . $field_id),
					'recursive' => 0
				)
			);
			$i=0;
            if($results){
                foreach($results as $result){
                    $response[$i]['id'] = $result[$model][$field_id];
                    $response[$i]['value'] = strtoupper($result[$model][$field_name]) . ', ' . ucwords($result[$model][$field_name2]);
                    $i++;
                }
            }else{
                $response[0]['id'] = -1;
                $response[0]['value'] = 'No Record Found';
            }
			echo json_encode($response);
		}
	}
    
    // Ajax Auto Validation
    function validateForm($model) {
        if($this->request->is('ajax')){
            $this->request->data[$model][$this->request->data('field')] = $this->request->data('value');
            $this->$model->set($this->data);
            if($this->$model->validates()){
                $this->autoRender = FALSE;
            }else{
                $error = $this->validateErrors($this->$model);
                $this->set('error', $error[$this->request->data('field')]);
            }
        }
    }
    
    //Uploading of image
    function uploadImage($id, $type, $data = array()) {
        if(!isset($data['image_url']['name'])){
            return FALSE;
        }
        $image_url = $data['image_url']['name'];
        $ext = pathinfo($image_url, PATHINFO_EXTENSION);
        //$ext = explode('.', $image_url)[1];
        $name = $id.'.'.$ext;
        $src = $data['image_url']['tmp_name'];
        $des = getcwd() . DS . 'img' . DS . 'uploads' . DS . $type . DS . $name;
        if (!is_uploaded_file($data['image_url']['tmp_name'])) {
            return FALSE;
        }

        if (!is_readable($src))
            die("Very bad hosting juju. The file was uploaded but I can't read it?!?");

//        if (!is_writeable($des))
//            die("As expected, you can't upload a file here. This is not a good thing.");

        if (!move_uploaded_file($src, $des)) {
            return FALSE;
        }
        return TRUE;
    }
    
    //Dispaly Access Error Pages  1 => Access Denied 2 => Invalid Id
    function accessDenialError($msg=null, $type=1) {
        if($msg === null){
            $msg = 'You are not authorize to view this page nor perform this action...Contact your Administrator';
            Configure::write('disable_links', TRUE);
        }
        if($type === 1){
            $this->set('icon', 'fa-lock');
            $this->set('code', '401');
            $this->set('msg', ' Access Denied');
        }else if($type === 2){
            $this->set('icon', 'fa-bolt');
            $this->set('code', '404.0');
            $this->set('msg', $msg);
        }
        $this->setFlashMessage($msg, 2);
        $this->render('/Errors/error_access');
    }
    
    /**
    * Rebuild the Acl based on the current controllers in the application
    *
    * @return void
    */
    function buildAcl() {
        //$this->Auth->actionPath = 'controllers/';
        $log = array();
 
        $aco =& $this->Acl->Aco;
        $root = $aco->node('controllers');
        if (!$root) {
            $aco->create(array('parent_id' => null, 'model' => null, 'alias' => 'controllers'));
            $root = $aco->save();
            $root['Aco']['id'] = $aco->id; 
            $log[] = 'Created Aco node for controllers';
        } else {
            $root = $root[0];
        }   
 
        App::import('Core', 'File');
        $Controllers = App::objects('controller');
        $appIndex = array_search('App', $Controllers);
        if ($appIndex !== false ) {
            unset($Controllers[$appIndex]);
        }
        $baseMethods = get_class_methods('AppController');
        $baseMethods[] = 'buildAcl';
 
        // look at each controller in app/controllers
        foreach ($Controllers as $ctrlName) {
            App::import('Controller', $ctrlName);
            
            if ($ctrlName !== 'AppController') {
                // Load the controller
                App::import('Controller', str_replace('Controller', '', $ctrlName));
            }
            $ctrlclass = $ctrlName . 'Controller';
            $methods = get_class_methods($ctrlName);
 
            // find / make controller node
            $controllerNode = $aco->node('controllers/'.$ctrlName);
            if (!$controllerNode) {
                $aco->create(array('parent_id' => $root['Aco']['id'], 'model' => null, 'alias' => $ctrlName));
                $controllerNode = $aco->save();
                $controllerNode['Aco']['id'] = $aco->id;
                $log[] = 'Created Aco node for '.$ctrlName;
            } else {
                $controllerNode = $controllerNode[0];
            }
 
            //clean the methods. to remove those in Controller and private actions.
            foreach ($methods as $k => $method) {
                if (strpos($method, '_', 0) === 0) {
                    unset($methods[$k]);
                    continue;
                }
                if (in_array($method, $baseMethods)) {
                    unset($methods[$k]);
                    continue;
                }
                $methodNode = $aco->node('controllers/'.$ctrlName.'/'.$method);
                if (!$methodNode) {
                    $aco->create(array('parent_id' => $controllerNode['Aco']['id'], 'model' => null, 'alias' => $method));
                    $methodNode = $aco->save();
                    $log[] = 'Created Aco node for '. $method;
                }
            }
        }
        debug($log);
    }

    function initDB() {
        //Deny access to everything ==> 1                   EXPIRED_USERS
        $this->Acl->deny('EXPIRED_USERS', 'controllers');
        
        //allow users (Students, Parents) ==> 2            PAR_USERS
        $this->Acl->deny('PAR_USERS', 'controllers');
        $this->Acl->allow('PAR_USERS', 'HomeController');
        $this->Acl->allow('PAR_USERS', 'StudentsController/view');
        $this->Acl->allow('PAR_USERS', 'SponsorsController/view');
        $this->Acl->allow('PAR_USERS', 'SponsorsController/adjust', 'update');
        $this->Acl->deny('PAR_USERS', 'SponsorsController/index');

        
        //Access Controls (Staffs or Teachers)==> 3      STF_USERS
        $this->Acl->deny('STF_USERS', 'controllers');
        $this->Acl->allow('STF_USERS', 'DashboardController');
        $this->Acl->allow('STF_USERS', 'ExamsController');
        $this->Acl->allow('STF_USERS', 'SubjectsController');
        $this->Acl->deny('STF_USERS', 'SubjectsController/add2class');
        $this->Acl->deny('STF_USERS', 'ExamsController/setup_exam');
        $this->Acl->allow('STF_USERS', 'AttendsController');
        $this->Acl->allow('STF_USERS', 'StudentsController/view');
        $this->Acl->allow('STF_USERS', 'ClassroomsController/myclass');
        $this->Acl->allow('STF_USERS', 'ClassroomsController/view');
        $this->Acl->allow('STF_USERS', 'EmployeesController/adjust', 'update');
        
        //Access Controls (ICT)==> 4                        ICT_USERS
        $this->Acl->deny('ICT_USERS', 'controllers');
        $this->Acl->allow('ICT_USERS', 'DashboardController');
        $this->Acl->allow('ICT_USERS', 'RecordsController');
        $this->Acl->allow('ICT_USERS', 'AttendsController');
        //ExamsController
        $this->Acl->allow('ICT_USERS', 'ExamsController');
        $this->Acl->deny('ICT_USERS', 'ExamsController/setup_exam');
        //ClassroomsController
        $this->Acl->allow('ICT_USERS', 'ClassroomsController');
        //$this->Acl->allow('ICT_USERS', 'ClassroomsController/myclass');
        //$this->Acl->allow('ICT_USERS', 'ClassroomsController/view');
        ////StudentsController
        $this->Acl->allow('ICT_USERS', 'StudentsController');
        $this->Acl->allow('ICT_USERS', 'StudentsController/index');
        $this->Acl->allow('ICT_USERS', 'StudentsController/view');
        $this->Acl->allow('ICT_USERS', 'StudentsController/register', 'create');
        $this->Acl->allow('ICT_USERS', 'StudentsController/adjust', 'update');
        $this->Acl->deny('ICT_USERS', 'StudentsController/delete', 'delete');
        //SponsorsController
        $this->Acl->allow('ICT_USERS', 'SponsorsController');
        $this->Acl->allow('ICT_USERS', 'SponsorsController/index');
        $this->Acl->allow('ICT_USERS', 'SponsorsController/view');
        $this->Acl->allow('ICT_USERS', 'SponsorsController/register', 'create');
        $this->Acl->allow('ICT_USERS', 'SponsorsController/adjust', 'update');
        $this->Acl->deny('ICT_USERS', 'SponsorsController/delete', 'delete');
        //EmployeesController
        $this->Acl->allow('ICT_USERS', 'EmployeesController');
        $this->Acl->allow('ICT_USERS', 'EmployeesController/index');
        $this->Acl->allow('ICT_USERS', 'EmployeesController/register', 'create');
        $this->Acl->allow('ICT_USERS', 'EmployeesController/adjust', 'update');
        $this->Acl->deny('ICT_USERS', 'EmployeesController/delete', 'delete');
        //SubjectsController
        $this->Acl->allow('ICT_USERS', 'SubjectsController');
        $this->Acl->allow('ICT_USERS', 'SubjectsController/add2class');
        //ItemsController
        $this->Acl->allow('ICT_USERS', 'ItemsController');
        $this->Acl->deny('ICT_USERS', 'ItemsController/process_fees');
        

        //Access Control (Super Admin) to everything ==> 5    ADM_USERS
        $this->Acl->allow('ADM_USERS', 'controllers');
        $this->Acl->deny('ADM_USERS', 'HomeController');
    }
}