<?php
App::uses('AppController', 'Controller');

class ItemsController extends AppController {

    public $components = array('Paginator');

        // only allow the login controllers only
    public function beforeFilter() {
        parent::beforeFilter();
        $this->masterRedirect();
    }
    
    /////////////////////////////////////// actions ///////////////////////////////////////////////
    public function index() {
        $this->set('title_for_layout', 'Fess / Item Bills');
        $resultCheck = $this->Acl->check($this->group_alias, 'ItemsController');
        if($resultCheck){
            $this->loadModels('AcademicYear', 'academic_year', 'DESC');
            $this->loadModels('Classlevel');
            $this->loadModels('Item');
        }else{
            $this->accessDenialError();
        }        
    }
    
    public function summary() {
        $ClasslevelObject = ClassRegistry::init('Classlevel'); 
        $Classlevels = $ClasslevelObject->find('all');
        $this->set('Classlevels', $Classlevels);
    }

    /*public function summaryAngular() {
        $ClasslevelObject = ClassRegistry::init('Classlevel');
        $Classlevels = $ClasslevelObject->find('all');
        $this->autoRender = false;
        echo json_encode($Classlevels);
    }*/
    
    public function payment_status() {
        $this->autoRender = false;
        if ($this->request->is('ajax')) {
            //$term = $this->request->data['SearchPayment']['search_academic_term_id'];
            $Item = ClassRegistry::init('Item');
            $AcademicTerm = ClassRegistry::init('AcademicTerm');
            $ClasslevelObject = ClassRegistry::init('Classlevel');
            $Classroom = ClassRegistry::init('Classroom');
            //$term_id = empty($term) ? $AcademicTerm->getCurrentTermID() : $term;
            $term_id = $AcademicTerm->getCurrentTermID();
            $response = array();
            
            $Classlevels = $ClasslevelObject->find('all');
            foreach ($Classlevels as $Classlevel){
                $results = $Classroom->find('all', array('conditions' => array('Classroom.classlevel_id'=>$Classlevel['Classlevel']['classlevel_id'])));
                $total_paid = 0; $total_Npaid = 0;
                $re[] = $Classlevel['Classlevel']['classlevel'];
                $res = null;
                
                foreach ($results as $result){
                    $count_paid = $Item->countClassPaid($term_id, $result['Classroom']['class_id']);
                    $count_not_paid = $Item->countClassNotPaid($term_id, $result['Classroom']['class_id']);
                    $res[] = array(						
                        "classrooms"=>$result['Classroom']['class_name'],
                        "paid"=>$count_paid,
                        "not_paid"=>$count_not_paid
                    );
                    $total_paid += $count_paid;
                    $total_Npaid += $count_not_paid;
                }
                
                $response[$Classlevel['Classlevel']['classlevel']] = $res;
                $response[$Classlevel['Classlevel']['classlevel']][0][0] = $total_paid;
                $response[$Classlevel['Classlevel']['classlevel']][0][1] = $total_Npaid;
            }
            $response['ClasslevelName'] = $re;
            echo json_encode($response);
        }
    }
    
    
    
    //Validate if the fees has been processed for the academic term
    public function validateIfExist() {        
        $this->autoRender = false;
        $ProcessItem = ClassRegistry::init('ProcessItem');
        if ($this->request->is('ajax')) {
            //$class = ($this->request->data['SubjectClasslevel']['class_id'] !== '') ? $this->request->data['SubjectClasslevel']['class_id'] : null;
            $term_id = $this->request->data['ProcessItem']['academic_term_id'];
            $results = $ProcessItem->find('first', array('conditions' => array('ProcessItem.academic_term_id' => $term_id)));
            echo (!empty($results)) ? 1 : 0;
        }
    }
    
    //Process Fees for an Academic Term
    public function process_fees() {
        $this->autoRender = false;
        $resultCheck = $this->Acl->check($this->group_alias, 'ItemsController/process_fees');
        if($resultCheck){
            $ProcessItem = ClassRegistry::init('ProcessItem');
            if ($this->request->is('ajax')) {
                $ProcessItem->create();
                $data = $this->request->data['ProcessItem'];     
                if($ProcessItem->save($data)) {
                    $ProcessItem->proc_processTerminalFees($ProcessItem->getLastInsertId());
                    echo $ProcessItem->getLastInsertId();
                }else { echo 0; }
            }
        }else{
            $this->accessDenialError();
        }  
    }
    
    //Billing of Student
    public function bill_students() {
        $this->autoRender = false;
        $resultCheck = $this->Acl->check($this->group_alias, 'ItemsController');
        if($resultCheck){
            $ItemVariable = ClassRegistry::init('ItemVariable');
            if ($this->request->is('ajax')) {
                $ItemVariable->create();
                $data = $this->request->data['ItemVariable'];
                $data['item_id'] = $data['itemIV_id'];
                $data['student_id'] = ($data['studentIV_id'] !== '') ? $this->encryption->decode($data['studentIV_id']) : null;
                $data['class_id'] = ($data['classIV_id'] !== '') ? $this->encryption->decode($data['classIV_id']) : null;
                $data['academic_term_id'] = $data['academic_termIV_id'];
                $data['price'] = $data['priceIV'];
                if($ItemVariable->save($data)) {
                    $ItemVariable->proc_processItemVariable($ItemVariable->getLastInsertId());
                    echo $ItemVariable->getLastInsertId();
                }else { echo 0; }
            }
        }else{
            $this->accessDenialError();
        }
    }
    
    //Displays Students Fees Charges for an academic term
    public function view_stdfees($encrypt_id) {
        //Decrypt the id sent
        $resultCheck = $this->Acl->check($this->group_alias, 'ItemsController');
        if($resultCheck){
            $decrypt_id = $this->encryption->decode($encrypt_id);
            $student_id = explode('/', $decrypt_id)[0];
            $term_id = explode('/', $decrypt_id)[1];

            $this->set('title_for_layout','Terminal Fees Charges');
            $results = $this->Item->findStudentTerminalFees($student_id, $term_id);  
            $response = array();  

            if(!empty($results)) {   
                //All the items charges
                foreach ($results as $result){
                    $res[] = array(						
                        "student_id"=>$result['a']['student_id'],
                        "order_id"=>$result['a']['order_id'],
                        "student_name"=>$result['a']['student_name'],
                        "student_status_id"=>$result['a']['student_status_id'],
                        "student_status"=>$result['a']['student_status'],
                        "sponsor_name"=>$result['a']['sponsor_name'],
                        "sponsor_id"=>$this->encryption->encode($result['a']['sponsor_id']),
                        "salutation_name"=>$result['a']['salutation_name'],
                        "class_name"=>$result['a']['class_name'],
                        "image_url"=>$result['a']['image_url'],
                        "academic_term"=>$result['a']['academic_term'],
                        "item_name"=>$result['a']['item_name'],
                        "order_status_id"=>$result['a']['order_status_id'],
                        "price"=>$result['a']['price'],
                        "subtotal"=>$result['a']['subtotal']
                    );
                }
                $response['ItemBill'] = $res;
                $response['Flag'] = 1;
            } else {
                $response['ItemBill'] = null;
                $response['Flag'] = 0;
            }
            $this->set('ItemBills', $response);       
        }else{
            $this->accessDenialError();
        }
    }
    
    //Displays Students Fees Charges for an academic term
    public function view_clsfees($encrypt_id) {
         $this->set('title_for_layout','Terminal Fees Charges');
         $resultCheck = $this->Acl->check($this->group_alias, 'ItemsController');
        if($resultCheck){
            //Decrypt the id sent
            $decrypt_id = $this->encryption->decode($encrypt_id);
            $class_id = explode('/', $decrypt_id)[0];
            $term_id = explode('/', $decrypt_id)[1];
            $results = $this->Item->findClassTerminalFees($class_id, $term_id);  
            $response = array();  

            if(!empty($results)) {   
                //All the items charges
                foreach ($results as $result){
                    $res[] = array(						
                        "student_id"=>$result['student_feesviews']['student_id'],
                        "order_id"=>$result['student_feesviews']['order_id'],
                        "student_name"=>$result['student_feesviews']['student_name'],
                        "student_no"=>$result['student_feesviews']['student_no'],
                        "student_status_id"=>$result['student_feesviews']['student_status_id'],
                        "student_status"=>$result['student_feesviews']['student_status'],
                        "sponsor_name"=>$result['student_feesviews']['sponsor_name'],
                        "sponsor_id"=>$this->encryption->encode($result['student_feesviews']['sponsor_id']),
                        "class_name"=>$result['student_feesviews']['class_name'],
                        "academic_term"=>$result['student_feesviews']['academic_term'],
                        "academic_term_id"=>$result['student_feesviews']['academic_term_id'],
                        "order_status_id"=>$result['student_feesviews']['order_status_id'],
                        "grand_total"=>$result[0]['grand_total'],
                    );
                }
                $response['ClassBill'] = $res;
                $response['Flag'] = 1;
            } else {
                $response['ClassBill'] = null;
                $response['Flag'] = 0;
            }
            $this->set('ClassBills', $response);       
        }else{
            $this->accessDenialError();
        }
    }
    
    //http://www.mediafire.com/download/nc7w322rgent86h/project@14-04-2014.zip
    //
    //Update Order Item Status
    public function statusUpdate() {
        $this->autoRender = false;
        $order = ClassRegistry::init('Order');
        if ($this->request->is('ajax')) {
            $order->id = $this->request->data('order_id');
            if (!$order->exists()) {
                echo 'Invalid Order Record Requested for Modification';
            }else{
                echo ($order->saveField('status_id', $this->request->data('status_id'))) ? 1 : 0;
            }
        }
    }
    /////////////////////////////////////// \\\ actions ///////////////////////////////////////////////
}

?>