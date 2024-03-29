<?php
App::uses('AppController', 'Controller');
App::import('Vendor','PHPMailer',array('file'=>'PHPMailer/PHPMailerAutoload.php'));

class SponsorsController extends AppController {

    //public $helpers = array('Html', 'Form', 'Js');
    public $components = array('Paginator');

    public function beforeFilter() {
        parent::beforeFilter();
        $this->masterRedirect();
    }
    
    public function autoComplete() {
        //$model, $field_name1, $field_id $field_name2 // Auto Completes The Field.
        $this->autoCompleteField('Sponsor', 'first_name', 'sponsor_id', 'other_name');
    }
    
    public function validate_form() {
        $this->validateForm('Sponsor');
    }
    
    public function index() {
        $result = $this->Acl->check($this->group_alias, 'SponsorsController/index');
        if($result){
            //$this->Sponsor->recursive = 0;
            $this->set('sponsors', $this->Sponsor->find('all'));
        }else{
            $this->accessDenialError();
        }
    }    
    
    public function register() {
        //$this->Sponsor->sendMail('Work', 'Authentication', 'kingsley4united@yahoo.com', 'Kingsley Chinaka');
        //$this->Sponsor->SendSMS('08030734377', 'Dude' );
        $result = $this->Acl->check($this->group_alias, 'SponsorsController/register', 'create');
        if($result){
            $this->loadModels('Salutation', 'salutation_name');
            $SponsorNew = ClassRegistry::init('SponsorNew');

            if ($this->request->is('post')) {
                $data = $this->request->data['SponsorNew'];
                $results = $SponsorNew->query('SELECT * FROM sponsors WHERE mobile_number1="'.trim($data['mobile_number1']).'" LIMIT 1');
                $results = ($results) ? array_shift($results) : false;
                if($results && strtolower($results['sponsors']['first_name']) === strtolower(trim($data['first_name']))){
                    $this->setFlashMessage(' The Parent '.$data['first_name'].' With Mobile Number '.$data['mobile_number1'].' Already Exist.', 2);
                    return $this->redirect(array('action' => 'register'));
                }else{
                    $SponsorNew->create();
                    if ($SponsorNew->save($data)){
                        $this->setFlashMessage('The Parent '.$data['first_name'].' '.$data['other_name'].' has been saved.', 1);
                        return $this->redirect(array('controller' => 'sponsors', 'action' => 'register'));
                    }else {
                        $this->setFlashMessage('The Parent could not be saved. Please, Kindly Fill the Form Properly.', 2);
                    }
                } 
            }
        }else{
            $this->accessDenialError();
        }
    }
    
    public function view($encrypt_id = null) {
        $result = $this->Acl->check($this->group_alias, 'SponsorsController/view');
        if($result){
            $decrypt_sponsor_id = $this->encryption->decode($encrypt_id);
            
            if (!$this->Sponsor->exists($decrypt_sponsor_id)) {
                $this->accessDenialError('Invalid Parent Record Requested for Viewing', 2);
            }
            $options = array('conditions' => array('Sponsor.' . $this->Sponsor->primaryKey => $decrypt_sponsor_id));
            $this->set('sponsor', $this->Sponsor->find('first', $options));
        }else{
            $this->accessDenialError();
        }
    }

    public function adjust($encrypt_id = null) {
        $result = $this->Acl->check($this->group_alias, 'SponsorsController/adjust', 'update');
        if($result){
            $this->loadModels('Salutation', 'salutation_name');
            $decrypt_sponsor_id = $this->encryption->decode($encrypt_id);

            if (!$this->Sponsor->exists($decrypt_sponsor_id)) {
                $this->accessDenialError('Invalid Parent Record Requested for Modification', 2);
            }
            if ($this->request->is(array('post', 'put'))) {
                $this->Sponsor->id = $decrypt_sponsor_id;
                $data = $this->request->data['Sponsor'];
                if ($this->Sponsor->save($data)) {
                    $this->setFlashMessage('The Parent has been Updated.', 1);

                    return $this->redirect(array('action' => 'adjust/'.$encrypt_id));
                } else {
                    $this->setFlashMessage('The Parent could not be Updated. Please, try again.', 2);
                }
            }
            $options = array('conditions' => array('Sponsor.' . $this->Sponsor->primaryKey => $decrypt_sponsor_id));
            $this->request->data = $this->Sponsor->find('first', $options);
            $this->set('sponsor', $this->Sponsor->find('first', $options));
        }else{
            $this->accessDenialError();
        }
    }
    
    /*public function adjust($encrypt_id = null) {
        $result = $this->Acl->check($this->group_alias, 'SponsorsController/adjust', 'update');
        if($result){
            $this->loadModels('Salutation', 'salutation_name');
            $this->loadModels('Country');
            $this->loadModels('State', 'state_name');
            $this->loadModels('SponsorshipType', 'sponsorship_type');
            $decrypt_sponsor_id = $this->encryption->decode($encrypt_id);

            if (!$this->Sponsor->exists($decrypt_sponsor_id)) {
                $this->accessDenialError('Invalid Parent Record Requested for Modification', 2);
            }
            if ($this->request->is(array('post', 'put'))) {
                $this->Sponsor->id = $decrypt_sponsor_id;
                $data = $this->request->data['Sponsor'];
                if(!$data['image_url']['name']){
                    unset($data['image_url']);
                }
                if ($this->Sponsor->save($data)) {
                    //Uploading The Image Provided
                    if(isset($data['image_url'])){
                        if($this->uploadImage($decrypt_sponsor_id, 'sponsors', $this->request->data['Sponsor'])) {
                            $this->setFlashMessage('The Parent has been Updated.', 1);
                        }
                    }else {
                        $this->setFlashMessage('The Parent has been Updated... But New Image Was Not Uploaded', 1);
                    }
                    return $this->redirect(array('action' => 'adjust/'.$encrypt_id));
                } else {
                    $this->setFlashMessage('The Parent could not be Updated. Please, try again.', 2);
                }
            }
            $options = array('conditions' => array('Sponsor.' . $this->Sponsor->primaryKey => $decrypt_sponsor_id));
            $this->request->data = $this->Sponsor->find('first', $options);
            $this->set('sponsor', $this->Sponsor->find('first', $options));
            //debug($this->request->data);
        }else{
           $this->accessDenialError();
        }
    }*/
    
    public function delete($encrypt_id = null) {
        $result = $this->Acl->check($this->group_alias, 'SponsorsController/delete', 'delete');
        $user = ClassRegistry::init('User');
        if($result){
            $decrypt_sponsor_id = $this->encryption->decode($encrypt_id);
            $this->Sponsor->id = $decrypt_sponsor_id;
            $options = array('conditions' => array('Sponsor.' . $this->Sponsor->primaryKey => $decrypt_sponsor_id));
            $sponsor_record = $this->Sponsor->find('first', $options);
            
            if (!$this->Sponsor->exists()) {
                $this->accessDenialError('Invalid Parent Record Requested for Deletion', 2);
            }
            $this->request->allowMethod('post', 'delete');
            if ($this->Sponsor->delete()) {
                //Delete the equivalent users record
                $user->query('DELETE FROM users WHERE username="'.$sponsor_record['Sponsor']['sponsor_no'].'" LIMIT 1');
                $this->setFlashMessage('The Parent ' . $sponsor_record['Sponsor']['sponsor_no'] .' and its Equivalent User Record has been deleted.', 1);
            } else {
                $this->setFlashMessage('The Parent could not be deleted. Please, try again.', 2);
            }
            return $this->redirect(array('action' => 'index'));
        }else{
           $this->accessDenialError();
        }
    }
}