<?php
App::uses('AppController', 'Controller');

class StudentsController extends AppController {

	public $components = array('Paginator');

    // only allow the login controllers only
    public function beforeFilter() {
        parent::beforeFilter();
        $this->masterRedirect();
    }
    
    public function validate_form() {
        $this->validateForm('Student');
    }

    public function index() {
        $this->set('title_for_layout', 'Students');
        //$this->layout = 'default_web'; 
        //$this->Student->createAROGroups();
        
        $result = $this->Acl->check($this->group_alias, 'StudentsController/index');
        if($result){
            //$this->Student->recursive = 0;
            $this->loadModels('StudentStatus');
            //$this->set('Status', $status);
            $this->set('students', $this->Student->find('all'));
        }else{
            $this->accessDenialError();
        }        
    }
    
    public function view($encrypt_id = null) {
        $this->set('title_for_layout','Student Details');
        $result = $this->Acl->check($this->group_alias, 'StudentsController/view', 'read');
        if($result){
            $decrypt_student_id = $this->encryption->decode($encrypt_id);
            if (!$this->Student->exists($decrypt_student_id)) {
                $this->accessDenialError('Invalid Student Record Requested for Viewing', 2);
            }
            $options = array('conditions' => array('Student.' . $this->Student->primaryKey => $decrypt_student_id));
            $this->set('student', $this->Student->find('first', $options));
            
        }else{
            $this->accessDenialError();
        }        
    }
    
    //CakeLog::write('debug 4', $dd[0]['academic_term_id']);
    
    public function register() {
        $this->set('title_for_layout','Create New Student Record');
        $result = $this->Acl->check($this->group_alias, 'StudentsController/register', 'create');
        if($result){
            $this->loadModels('RelationshipType');
            $this->loadModels('Classlevel');
            $StudentNew = ClassRegistry::init('StudentNew');

            if ($this->request->is('post')) {
                $this->Student->create();
                $data = $this->request->data['StudentNew'];

                $results = $StudentNew->query('SELECT a.*, b.first_name FROM students a INNER JOIN sponsors b ON a.sponsor_id=b.sponsor_id
                  WHERE a.sponsor_id="'.trim($data['sponsor_id']).'" AND a.first_name="'.trim($data['first_name']).'" LIMIT 1');
                $results = ($results) ? array_shift($results) : false;
                if($results){
                    $this->setFlashMessage(' The Student '.$data['first_name'].' With Sponsor Name '.$results['b']['first_name'].' Already Exist.', 2);
                    return $this->redirect(array('controller' => 'students', 'action' => 'register'));
                }else{
                    $StudentNew->create();
                    if ($StudentNew->save($data)) {
                        $this->setFlashMessage('The Student '.$data['first_name'].' '.$data['other_name'].' has been saved.', 1);
                        return $this->redirect(array('controller' => 'students', 'action' => 'register'));
                    }else {
                        $this->setFlashMessage('The Student could not be saved. Please,  Kindly Fill the Form Properly.', 2);
                    }
                }
//
//                if ($this->Student->save($data)) {
//                    if(isset($data['image_url'])){
//                        $this->uploadImage($this->Student->getLastInsertId(), 'students', $this->request->data['Student']);
//                        $this->setFlashMessage('The Student '.$data['first_name'].' '.$data['surname'].' has been saved.', 1);
//                    }else {
//                        $this->setFlashMessage('The Student '.$data['first_name'].' '.$data['surname'].' has been saved... But Image Was Not Uploaded', 1);
//                    }
//                    return $this->redirect(array('action' => 'register'));
//                } else {
//                    $this->setFlashMessage('The student could not be saved. Please, try again.', 2);
//                }
            }
        }else{
            $this->accessDenialError();
        }
    }

    public function adjust($encrypt_id = null) {
        $this->set('title_for_layout','Modify Existing Student Record');
        $result = $this->Acl->check($this->group_alias, 'StudentsController/adjust', 'update');
        if($result){
            $this->loadModels('Country');
            $this->loadModels('State', 'state_name');
            $this->loadModels('RelationshipType');
            $this->loadModels('Classlevel');
            $decrypt_student_id = $this->encryption->decode($encrypt_id);
            
            if (!$this->Student->exists($decrypt_student_id)) {
                $this->accessDenialError('Invalid Student Record Requested for Modification', 2);
            }
            if ($this->request->is(array('post', 'put'))) {
                $this->Student->id = $decrypt_student_id;
                $data = $this->request->data['Student'];
                if(!$data['image_url']['name']){
                    unset($data['image_url']);
                }
                if ($this->Student->save($data)) {
                    if(isset($data['image_url'])){
                        $this->uploadImage($decrypt_student_id, 'students', $this->request->data['Student']);
                        $this->setFlashMessage('The Student has been Updated.', 1);
                    }else {
                        $this->setFlashMessage('The Student has been Updated... But New Image Was Not Uploaded', 1);
                    }
                    return $this->redirect(array('action' => 'adjust/'.$encrypt_id));
                } else {
                    $this->setFlashMessage('The student could not be update. Please, try again.', 2);
                }
            }
            $options = array('conditions' => array('Student.' . $this->Student->primaryKey => $decrypt_student_id));
            $this->request->data = $this->Student->find('first', $options);
            $this->set('student', $this->Student->find('first', $options));
        }else{
            $this->accessDenialError();
        }
    }

    public function delete($encrypt_id) {
        $studClass = ClassRegistry::init('StudentsClass');
        $term_id = ClassRegistry::init('AcademicTerm');
        $result = $this->Acl->check($this->group_alias, 'StudentsController/delete', 'delete');
        if($result){
            $decrypt_student_id = $this->encryption->decode($encrypt_id);
            
            $this->Student->id = $decrypt_student_id;
            if (!$this->Student->exists()) {
                $this->accessDenialError('Invalid Student Record Requested for Deletion', 2);
            }
            $this->request->allowMethod('post', 'delete');
            if ($this->Student->delete()) {
                $studClass->query('DELETE FROM students_classes WHERE student_id="'.$decrypt_student_id.'" AND academic_year_id="'.$term_id->getCurrentYearID().'"');
                $this->setFlashMessage('The student has been deleted.', 1);   
            } else {
                $this->setFlashMessage('The student could not be deleted. Please, try again.', 2);   
            }
            return $this->redirect(array('action' => 'index'));
        }else{
            $this->accessDenialError();
        }
    }
    
    //Update Student Status
    public function statusUpdate() {
        $this->autoRender = false;
        if ($this->request->is('ajax')) {
            $this->Student->id = $this->request->data('student_id');
            if (!$this->Student->exists()) {
                echo 'Invalid Student Record Requested for Modification';
            }else{
                echo ($this->Student->saveField('student_status_id', $this->request->data('status_id'))) ? 1 : 0;
            }
        }
    }    
}

?>