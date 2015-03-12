<?php
App::uses('AppController', 'Controller');

class MessagesController extends AppController {

    
    // only allow the login controllers only
    public function beforeFilter() {
        parent::beforeFilter();
        $this->masterRedirect();
    }
    
    public function index() {
        //$student = ClassRegistry::init('Student');
        //$student->createNewUser('spn0001 ', 'KayOh', 'China', 1, 'sponsors/1.jpg', 1);
        $result = $this->Acl->check($this->group_alias, 'MessagesController');
        if($result){
            $this->loadModels('Classlevel');
            $this->loadModels('AcademicYear', 'academic_year', 'DESC');
            
            $employee = ClassRegistry::init('Employee');
            $this->set('employees', $employee->find('all'));
        }else{
            $this->accessDenialError();            
        }
    }
    
    public function recipient($encrypt_id=null) {
        $result = $this->Acl->check($this->group_alias, 'MessagesController');
        if($result){
            $MessageRecipient = ClassRegistry::init('MessageRecipient');
            $recipient_id = ($encrypt_id === null) ? null : $this->encryption->decode($encrypt_id);
            $d = '';//$MessageRecipient->SendSMS('08030734377', 'Dude work na joker');
            if ($this->request->is('post')) {
                $data = $this->request->data['MessageRecipient'];
                $MessageRecipient->id = $recipient_id;
                if($MessageRecipient->save($data)){
                    $this->setFlashMessage($data['recipient_name'] . ' Has Been Sucessfully Saved', 1);  
                    return $this->redirect(array('action' => 'recipient'));
                }else{
                    $this->setFlashMessage('Error Adding The Recipient...', 2);   
                }
            }
            if($recipient_id !== null){
                $result = $MessageRecipient->find('first', array('conditions' => array('MessageRecipient.' . $MessageRecipient->primaryKey => $recipient_id)));
            }
            $this->set('Recipient', $result);
            $this->set('d', $d);
            $this->set('MessageRecipients', $MessageRecipient->find('all'));
        }else{
            $this->accessDenialError();            
        }
    }
    
    //Delete a Recipient Record
    public function delete_recipient($encrypt_id = null) {
        $decrypt_recipient_id = $this->encryption->decode($encrypt_id);
        $MessageRecipient = ClassRegistry::init('MessageRecipient');
        $MessageRecipient->id = $decrypt_recipient_id;
        if (!$MessageRecipient->exists()) {
            $this->accessDenialError('Invalid Recipient Record Requested for Deletion', 2);
        }
        $this->request->allowMethod('post', 'delete');
        if ($MessageRecipient->delete()) {
            $this->setFlashMessage('The Recipient has been deleted.', 1);
        } else {
            $this->setFlashMessage('The Recipient could not be deleted. Please, try again.', 2);
        }
        return $this->redirect(array('action' => 'recipient'));
    }
    
    //Multiple Message Sending
    public function send($encrypt_param) {
        $result_check = $this->Acl->check($this->group_alias, 'MessagesController');
        if($result_check){
            $decrypted = $this->encryption->decode($encrypt_param);
            $receiver_ids = explode('/', $decrypted)[0];
            $type = explode('/', $decrypted)[1];
            $id_s = explode(',', $receiver_ids);
            //Remove Duplicates
            $ids = array_unique($id_s);
            if ($this->request->is('post')) {
                $subject = $this->request->data['Send']['subject'];
                $option = $this->request->data['Send']['option'];
                $message = $this->request->data['Send']['message'];
                
                //Type emp = employees while spn = sponsors
                if($type === 'emp'){
                    $this->message_emp($subject, $option, $message, $ids);
                }elseif($type === 'rcp'){
                    $this->message_rcp($subject, $option, $message, $ids);
                }elseif ($type === 'spn') {
                    $this->message_spn($subject, $option, $message, $ids, 'spn');
                }elseif ($type === 'spn_class') {
                    $this->message_spn($subject, $option, $message, $ids, 'spn_class');
                }elseif($receiver_ids === 'all' and $type === 'spn_all') {
                    $this->message_spn($subject, $option, $message, null, 'spn_all');
                }
                return $this->redirect(array('action' => 'index'));
            } else {
                $this->set('type', $type);
            }
        }else{
            $this->accessDenialError();            
        }
    }
    
    //Single Message Sending
    public function sendOne() {
        $this->autoRender = false;
        if ($this->request->is('ajax')) {
            $id = $this->request->data['Send']['hidden_id'];
            $subject = $this->request->data['Send']['subject'];
            $option = $this->request->data['Send']['option'];
            $message = $this->request->data['Send']['message'];
            $type = $this->request->data['Send']['type'];

            //Type emp = employees while spn = sponsors
            if($type === 'rcp'){
                echo $this->sendRecipient($id, $subject, $option, $message);
            }elseif($type === 'emp'){
                echo $this->sendEmployee($id, $subject, $option, $message);
            }
        }
    }
    
    //Message Sending to employees
    private function message_emp($subject, $option, $message, $ids) {
        $sms_count = 0;
        $email_count = 0;
        
        for ($i=0; $i<count($ids); $i++){
            $out = $this->sendEmployee($ids[$i], $subject, $option, $message);
            $sms_count += explode('_', $out)[0];
            $email_count += explode('_', $out)[1];
        }
        $this->saveMassage($subject, $message, $sms_count, $email_count);
        $this->setFlashMessage($sms_count . ' SMS and ' . $email_count . ' email Massages Has Been Sent to the Employees', 1);   
    }
    
    //Message Sending to recipients
    private function message_rcp($subject, $option, $message, $ids) {
        $sms_count = 0;
        $email_count = 0;
        
        for ($i=0; $i<count($ids); $i++){
            $out = $this->sendRecipient($ids[$i], $subject, $option, $message);
            $sms_count += explode('_', $out)[0];
            $email_count += explode('_', $out)[1];
        }
        $this->saveMassage($subject, $message, $sms_count, $email_count);
        $this->setFlashMessage($sms_count . ' SMS and ' . $email_count . ' email Massages Has Been Sent to the Recipients', 1);   
    }
    
    //Message Sending to Sponsors 
    private function message_spn($subject, $option, $message, $ids, $type=null) {
        $StudentsClass = ClassRegistry::init('StudentsClass');
        $term_id = ClassRegistry::init('AcademicTerm');
        $sms_count = 0;
        $email_count =0;
                
        if($type == 'spn_all'){
            //All the Sponsors with wards in the current academic year
//            $sponsor_ids = $StudentsClass->query('SELECT DISTINCT a.sponsor_id FROM students_classlevelviews a '
//                    . 'WHERE a.academic_year_id="'.$term_id->getCurrentYearID().'"');
            $sponsor_ids = $StudentsClass->query('SELECT DISTINCT a.sponsor_id FROM students_classlevelviews a '
                    . 'WHERE a.academic_year_id="'.$term_id->getCurrentYearID().'"');
            if($sponsor_ids){
                foreach ($sponsor_ids as $sponsor_id){
                    $result = $this->sposnorHelper($subject, $option, $message, $sponsor_id['a']['sponsor_id'], $sms_count, $email_count);
                    $sms_count = explode(',', $result)[0];
                    $email_count = explode(',', $result)[1];
                }
            }
        }  else if($type == 'spn_class'){
            //All the classrooms Marked
            for ($i=0; $i<count($ids); $i++){
                $sponsor_ids = $StudentsClass->query('SELECT DISTINCT a.sponsor_id FROM students_classlevelviews a '
                        . 'WHERE a.class_id="'.$ids[$i].'" AND a.academic_year_id="'.$term_id->getCurrentYearID().'"');
                if($sponsor_ids){
                    foreach ($sponsor_ids as $sponsor_id){
                        $result = $this->sposnorHelper($subject, $option, $message, $sponsor_id['a']['sponsor_id'], $sms_count, $email_count);
                        $sms_count = explode(',', $result)[0];
                        $email_count = explode(',', $result)[1];
                    }
                }
            }
        }  else if($type == 'spn') {
            //All the Sponosrs Marked
            for ($i=0; $i<count($ids); $i++){
                $result = $this->sposnorHelper($subject, $option, $message, $ids[$i], $sms_count, $email_count);
                $sms_count = explode(',', $result)[0];
                $email_count = explode(',', $result)[1];
            }
        }
        $this->saveMassage($subject, $message, $sms_count, $email_count);
        $this->setFlashMessage($sms_count . ' SMS and ' . $email_count . ' email Massages Has Been Sent to the Sponsors', 1);   
    }
    
    //Sponsor Message Helper
    private function sposnorHelper($subject, $option, $message, $id, $sms_count, $email_count) {
        $sponsor = ClassRegistry::init('Sponsor');
        $result = $sponsor->find('first', array('conditions' => array('Sponsor.' . $sponsor->primaryKey => $id)));
        $email = (!(empty($result['Sponsor']['email']))) ? $result['Sponsor']['email'] : null;
        $mobile_no = (!(empty($result['Sponsor']['mobile_number1']))) ? $result['Sponsor']['mobile_number1'] : null;
        $name = $result['Sponsor']['first_name'] . ', ' . $result['Sponsor']['other_name'];

        ////// Message Sending ///////////////
        //Option 1 = S.M.S Only while 2 = S.M.S and e-mail
        if($option === '2' and $email !== null){
            //Send E-Mail
            ($sponsor->sendMail($message, $subject, $email, $name)) ? $email_count++ : '';
        }
        if($mobile_no !== null){
            //Send S.M.S
            ($sponsor->SendSMS($mobile_no, $message, $subject)[0] == " Message Sent Successfully.") ? $sms_count++ : '';

        }
        return $sms_count . ', ' .$email_count;
    }
    
    
    //Search for Sudents in a class or classrooms in a classlevel
    public function search_student_classlevel() {
        $Exam = ClassRegistry::init('Exam');
        $StudentsClass = ClassRegistry::init('StudentsClass');
        $this->autoRender = false;
        $resultCheck = $this->Acl->check($this->group_alias, 'MessagesController');
        if($resultCheck){
            if ($this->request->is('ajax')) {
                $year_id = $this->request->data['SearchForm']['academic_year_id'];
                $classlevel_id = $this->request->data['SearchForm']['classlevel_id'];
                $class_id = $this->request->data['SearchForm']['class_id'];
                $response = array();            
                if($class_id !== '') {
                    $results = $Exam->findStudentClasslevel($year_id, $classlevel_id, $class_id);                
                }else if ($class_id === '') {
                    $results2 = $Exam->findStudentClasslevel($year_id, $classlevel_id);
                }
                if(!empty($results)) {   
                    //All the students by classroom
                    foreach ($results as $result){
                        $res[] = array(						
                            "student_name"=>$result['a']['student_name'],
                            "student_no"=>$result['a']['student_no'],
                            "sponsor_id"=>$result['a']['sponsor_id'],
                            "spn_typ_id"=>$this->encryption->encode($result['a']['sponsor_id'] . '/spn'),
                            "sponsor_name"=>$result['a']['sponsor_name'],
                        );
                    }
                    $response['SearchResult'] = $res;
                    $response['Flag'] = 1;
                } elseif(!empty($results2)) {   
                    //All the students by classroom
                    foreach ($results2 as $result){
                        $student_count = $StudentsClass->find('count', array('conditions' => 
                            array(
                                'StudentsClass.academic_year_id' => $year_id,
                                'StudentsClass.class_id' => $result['a']['class_id']
                            )
                        ));
                        $res[] = array(						
                            "class_name"=>$result['a']['class_name'],
                            "student_count"=>$student_count,
                            "class_id"=>$result['a']['class_id'],
                            "cls_typ_id"=>$this->encryption->encode($result['a']['class_id'] . '/spn_class')
                        );
                    }
                    $response['SearchResult'] = $res;
                    $response['Flag'] = 2;
                } else {
                    $response['SearchResult'] = null;
                    $response['Flag'] = 0;
                }
                echo json_encode($response);
            }
        }else{
            $this->accessDenialError();
        }
    }
    
    //Encrpt the values sent
    public function encrypt($value, $type) {
        $this->autoRender = false;
        if ($this->request->is('ajax')) {
            echo $this->encryption->encode($value . '/' . $type);
        }
    }
    
    //Save Messages sent
    private function saveMassage($subject, $message, $sms_count, $email_count) {
        $Message = ClassRegistry::init('Message');
        $Message->create();
        $Message->data['Message']['message_subject'] = $subject;
        $Message->data['Message']['message'] = $message;
        $Message->data['Message']['sms_count'] = $sms_count;
        $Message->data['Message']['email_count'] = $email_count;
        $Message->save();
    }
    
    //Single Recipient
    private function sendRecipient($id, $subject, $option, $message) {
        $sms_count = 0;
        $email_count = 0;
        $recipient = ClassRegistry::init('MessageRecipient');
        $result = $recipient->find('first', array('conditions' => array('MessageRecipient.' . $recipient->primaryKey => $id)));
        $email = (!(empty($result['MessageRecipient']['email']))) ? $result['MessageRecipient']['email'] : null;
        $mobile_no = (!(empty($result['MessageRecipient']['mobile_number']))) ? $result['MessageRecipient']['mobile_number'] : null;
        $name = $result['MessageRecipient']['recipient_name'];
        ////// Message Sending ///////////////
        //Option 1 = S.M.S Only while 2 = S.M.S and e-mail
        if($option === '2' and $email !== null){
            //Send E-Mail
            ($recipient->sendMail($message, $subject, $email, $name)) ? $email_count++ : '';
        }
        if($mobile_no !== null){
            //Send S.M.S
            ($recipient->SendSMS($mobile_no, $message, $subject)[0] == " Message Sent Successfully.") ? $sms_count++ : '';
        }
        $this->setFlashMessage($sms_count . ' SMS and ' . $email_count . ' email Massages Has Been Sent to the Recipients', 1); 
        return $sms_count . '_' . $email_count;
    }
    
    //Single Employee
    private function sendEmployee($id, $subject, $option, $message) {
        $sms_count = 0;
        $email_count = 0;
        $employee = ClassRegistry::init('Employee');
        $result = $employee->find('first', array('conditions' => array('Employee.' . $employee->primaryKey => $id)));
        $email = (!(empty($result['Employee']['email']))) ? $result['Employee']['email'] : null;
        $mobile_no = (!(empty($result['Employee']['mobile_number1']))) ? $result['Employee']['mobile_number1'] : null;
        $name = $result['Employee']['first_name'] . ', ' . $result['Employee']['other_name'];
        ////// Message Sending ///////////////
        //Option 1 = S.M.S Only while 2 = S.M.S and e-mail
        if($option === '2' and $email !== null){
            //Send E-Mail
            ($employee->sendMail($message, $subject, $email, $name)) ? $email_count++ : '';
        }
        if($mobile_no !== null){
            //Send S.M.S
            ($employee->SendSMS($mobile_no, $message, $subject)[0] == " Message Sent Successfully.") ? $sms_count++ : '';
        }
        $this->setFlashMessage($sms_count . ' SMS and ' . $email_count . ' email Massages Has Been Sent to the Employees', 1); 
        return $sms_count . '_' . $email_count;
    }
}
?>