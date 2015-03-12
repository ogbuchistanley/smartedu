<?php
App::uses('AppController', 'Controller');
App::import('Vendor','PHPMailer',array('file'=>'PHPMailer/PHPMailerAutoload.php'));

class EmployeesController extends AppController {

    //public $helpers = array('Html', 'Form', 'Js');
    public $components = array('Paginator');

    public function beforeFilter() {
        parent::beforeFilter();
        $this->masterRedirect();
    }

    public function autoComplete() {
        //$model, $field_name1, $field_id $field_name2 // Auto Completes The Field.
        $this->autoCompleteField('Employee', 'first_name', 'employee_id', 'other_name');
    }

    public function validate_form() {
        $this->validateForm('Employee');
    }

    public function index() {
        $result = $this->Acl->check($this->group_alias, 'EmployeesController/index');
        if($result){
            //$this->Employee->recursive = 0;
            $this->set('employees', $this->Employee->find('all'));
        }else{
            $this->accessDenialError();
        }
    }

    //Create New Employee Adim Access Only
    public function register() {
        $result = $this->Acl->check($this->group_alias, 'EmployeesController/register', 'create');
        if($result){
            $this->loadModels('Salutation', 'salutation_name');
            $EmployeeNew = ClassRegistry::init('EmployeeNew');

            if ($this->request->is('post')) {
                $data = $this->request->data['EmployeeNew'];
//                $results = $EmployeeNew->find('first', array('conditions' => array('Employee.mobile_number1' => trim($data['mobile_number1']))));
                $results = $EmployeeNew->query('SELECT * FROM employees WHERE mobile_number1="'.trim($data['mobile_number1']).'" LIMIT 1');
                $results = ($results) ? array_shift($results) : false;
                if($results && strtolower($results['employees']['first_name']) === strtolower(trim($data['first_name']))){
                    $this->setFlashMessage(' The Employee '.$data['first_name'].' With Mobile Number '.$data['mobile_number1'].' Already Exist.', 2);
                    return $this->redirect(array('controller' => 'employees', 'action' => 'register'));
                }else{
                    $EmployeeNew->create();
                    if ($EmployeeNew->save($data)) {
                        $this->setFlashMessage('The Employee '.$data['first_name'].' '.$data['other_name'].' has been saved.', 1);
                        return $this->redirect(array('controller' => 'employees', 'action' => 'register'));
                    }else {
                        $this->setFlashMessage('The Employee could not be saved. Please,  Kindly Fill the Form Properly.', 2);
                    }
                }
            }
        }else{
            $this->accessDenialError();
        }
    }

    /*public function register() {
        $result = $this->Acl->check($this->group_alias, 'EmployeesController/register', 'create');
        if($result){
            $this->loadModels('Salutation', 'salutation_name');
            $this->loadModels('Country');
            $this->loadModels('State', 'state_name');
            $this->loadModels('EmployeeType', 'employee_type');

            if ($this->request->is('post')) {
                $data = $this->request->data['Employee'];
                $results = $this->Employee->query('SELECT * FROM employees WHERE mobile_number1="'.trim($data['mobile_number1']).'" LIMIT 1');
                $results = ($results) ? array_shift($results) : false;
                if($results && strtolower($results['employees']['first_name']) === strtolower(trim($data['first_name']))){
                    $this->setFlashMessage(' The Employee '.$data['first_name'].' With Mobile Number '.$data['mobile_number1'].' Already Exist.', 2); 
                    return $this->redirect(array('action' => 'register'));
                }else{
                    $this->Employee->create();
                    if(!$data['image_url']['name']){
                        unset($data['image_url']);
                    }
                    if ($this->Employee->save($this->request->data)) {
                        //Uploading The Image Provided
                        if(isset($data['image_url'])){
                            if($this->uploadImage($this->Employee->getLastInsertId(), 'employees', $this->request->data['Employee'])) {
                                $this->setFlashMessage('The Employee '.$data['first_name'].' '.$data['other_name'].' has been saved.', 1);   
                            }
                        }else {
                            $this->setFlashMessage('The Employee '.$data['first_name'].' '.$data['other_name'].' has been saved... But Image Was Not Uploaded', 1);
                        }
                        //Create The Spouse Record if Married
                        if(!empty($data['spouse_name'])) {
                            $SpouseDetail = ClassRegistry::init('SpouseDetail');
                            $SpouseDetail->create();
                            $SpouseDetail->data['SpouseDetail']['employee_id'] = $this->Employee->getLastInsertId();
                            $SpouseDetail->data['SpouseDetail']['spouse_name'] = $data['spouse_name'];
                            $SpouseDetail->data['SpouseDetail']['spouse_number'] = $data['spouse_number'];
                            $SpouseDetail->data['SpouseDetail']['spouse_employer'] = $data['spouse_employer'];
                            $SpouseDetail->save();
                        }
                        //Create The Employee Qualifications Record
                        if(!empty($data['institution'][0])) {
                            $EmpQua = ClassRegistry::init('EmployeeQualification');
                            for ($i=0; $i<count($data['institution']); $i++){
                                $EmpQua->create();
                                $EmpQua->data['EmployeeQualification']['employee_id'] = $this->Employee->getLastInsertId();
                                $EmpQua->data['EmployeeQualification']['institution'] = $data['institution'][$i];
                                $EmpQua->data['EmployeeQualification']['date_from'] = $data['date_from'][$i];
                                $EmpQua->data['EmployeeQualification']['date_to'] = $data['date_to'][$i];
                                $EmpQua->data['EmployeeQualification']['qualification'] = $data['qualification'][$i];
                                $EmpQua->data['EmployeeQualification']['qualification_date'] = $data['qualification_date'][$i];
                                $EmpQua->save();
                            }
                        }     
                        return $this->redirect(array('action' => 'register'));
                    }else {
                        $this->setFlashMessage('The Employee could not be saved. Please,  Kindly Fill the Form Properly.', 2);
                    }
                }
            }
        }else{
            $this->accessDenialError();
        }
    }*/

    public function view($encrypt_id = null) {
        $result = $this->Acl->check($this->group_alias, 'EmployeesController');
        if($result){
            $EmpQua = ClassRegistry::init('EmployeeQualification');
            $SpouseDetail = ClassRegistry::init('SpouseDetail');
            $decrypt_employee_id = $this->encryption->decode($encrypt_id);

            if (!$this->Employee->exists($decrypt_employee_id)) {
                $this->accessDenialError('Invalid Employee Record Requested for Viewing', 2);
            }
            $options = array('conditions' => array('Employee.' . $this->Employee->primaryKey => $decrypt_employee_id));
            $this->set('employee', $this->Employee->find('first', $options));
            $options3 = array('conditions' => array('EmployeeQualification.employee_id' => $decrypt_employee_id));
            $this->set('EmpQuas', $EmpQua->find('all', $options3));
            $options2 = array('conditions' => array('SpouseDetail.employee_id' => $decrypt_employee_id));
            $this->set('SpouseDetail', $SpouseDetail->find('first', $options2));
        }else{
            $this->accessDenialError();
        }
    }

    public function adjust($encrypt_id = null) {
        $result = $this->Acl->check($this->group_alias, 'EmployeesController/adjust', 'update');
        if($result){
            $SpouseDetail = ClassRegistry::init('SpouseDetail');
            $EmpQua = ClassRegistry::init('EmployeeQualification');
            $this->loadModels('Salutation', 'salutation_name');
            $this->loadModels('Country');
            $this->loadModels('State', 'state_name');
            $this->loadModels('EmployeeType', 'employee_type');
            $decrypt_employee_id = $this->encryption->decode($encrypt_id);

            if (!$this->Employee->exists($decrypt_employee_id)) {
                $this->accessDenialError('Invalid Employee Record Requested for Modification', 2);
            }
            if ($this->request->is(array('post', 'put'))) {
                $this->Employee->id = $decrypt_employee_id;
                $data = $this->request->data['Employee'];
                if(!$data['image_url']['name']){
                    unset($data['image_url']);
                }
                if ($this->Employee->save($data)) {
                    //Uploading The Image Provided
                    if(isset($data['image_url'])){
                        if($this->uploadImage($decrypt_employee_id, 'employees', $this->request->data['Employee'])) {
                            $this->setFlashMessage('The Employee has been Updated.', 1);
                        }
                    }else {
                        $this->setFlashMessage('The Employee has been Updated... But New Image Was Not Uploaded', 1);
                    }
                    //Update The Spouse Record if Married
                    if(!empty($data['spouse_name'])) {
                        $dataValue = $this->data;
                        $dataValue['spouse_detail_id'] = ($data['spouse_detail_id'] === '') ? null : $data['spouse_detail_id'];
                        $dataValue['employee_id'] = $decrypt_employee_id;
                        $dataValue['spouse_name'] = $data['spouse_name'];
                        $dataValue['spouse_number'] = $data['spouse_number'];
                        $dataValue['spouse_employer'] = $data['spouse_employer'];
                        $SpouseDetail->save($dataValue);
                    }
                    //Update The Employee Qualifications Record
                    if(!empty($data['employee_qualification_id'])) {
                        for ($i=0; $i<count($data['institution']); $i++){
                            $dataValue = $this->data;
                            $dataValue['employee_qualification_id'] = ($data['employee_qualification_id'][$i] === '') ? null : $data['employee_qualification_id'][$i];
                            $dataValue['employee_id'] = $decrypt_employee_id;
                            $dataValue['institution'] = $data['institution'][$i];
                            $dataValue['date_from'] = !(empty($data['date_from'][$i])) ? $data['date_from'][$i] : null;
                            $dataValue['date_to'] = !(empty($data['date_to'][$i])) ? $data['date_to'][$i] : null;
                            $dataValue['qualification'] = $data['qualification'][$i];
                            $dataValue['qualification_date'] = !(empty($data['qualification_date'][$i])) ? $data['qualification_date'][$i] : null;
                            $EmpQua->save($dataValue);
                        }
                    }
                    return $this->redirect(array('action' => 'adjust/'.$encrypt_id));
                    //return $this->redirect(array('controller' => 'dashboard', 'action' => 'index'));
                } else {
                    $this->setFlashMessage('The Employee could not be saved. Please, try again.', 2);
                }
            } else {
                $options2 = array('conditions' => array('SpouseDetail.employee_id' => $decrypt_employee_id));
                $options3 = array('conditions' => array('EmployeeQualification.employee_id' => $decrypt_employee_id));
                $this->set('SpouseDetail', $SpouseDetail->find('first', $options2));
                $this->set('EmpQuas', $EmpQua->find('all', $options3));
            }
            $options = array('conditions' => array('Employee.' . $this->Employee->primaryKey => $decrypt_employee_id));
            $this->request->data = $this->Employee->find('first', $options);
            $this->set('employee', $this->Employee->find('first', $options));
        }else{
            $this->accessDenialError();
        }
    }

    public function delete($encrypt_id = null) {
        $result = $this->Acl->check($this->group_alias, 'EmployeesController/delete', 'delete');
        $user = ClassRegistry::init('User');
        if($result){
            $decrypt_employee_id = $this->encryption->decode($encrypt_id);
            $options = array('conditions' => array('Employee.' . $this->Employee->primaryKey => $decrypt_employee_id));
            $employee_record = $this->Employee->find('first', $options);
            $this->Employee->id = $decrypt_employee_id;

            if (!$this->Employee->exists()) {
                $this->accessDenialError('Invalid Employee Record Requested for Deletion', 2);
            }
            $this->request->allowMethod('post', 'delete');
            if ($this->Employee->delete()) {
                //Delete the equivalent users record
                $user->query('DELETE FROM users WHERE username="'.$employee_record['Employee']['mployee_no'].'" LIMIT 1');
                $this->setFlashMessage('The Employee ' . $employee_record['Employee']['mployee_no'] . ' and its Equivalent User Record has been deleted.', 1);
            } else {
                $this->setFlashMessage('The Employee could not be deleted. Please, try again.', 2);
            }
            return $this->redirect(array('action' => 'index'));
        }else{
            $this->accessDenialError();
        }
    }

    //Update Employee Status
    public function statusUpdate() {
        $this->autoRender = false;
        if ($this->request->is('ajax')) {
            $this->Employee->id = $this->request->data('employee_id');
            if (!$this->Employee->exists()) {
                echo 'Invalid Employee Record Requested for Modification';
            }else{
                echo ($this->Employee->saveField('status_id', $this->request->data('status_id'))) ? 1 : 0;
            }
        }
    }
}