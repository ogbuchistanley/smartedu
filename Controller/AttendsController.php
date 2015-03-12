<?php
App::uses('AppController', 'Controller');

class AttendsController extends AppController {

        // only allow the login controllers only
    public function beforeFilter() {
        parent::beforeFilter();
        $this->masterRedirect();
    }
    
    /////////////////////////////////////// actions ///////////////////////////////////////////////
    public function index() {
        $this->set('title_for_layout', 'Attendance');
        $resultCheck = $this->Acl->check($this->group_alias, 'AttendsController');
        if($resultCheck){
            $this->loadModels('Classlevel');
            $this->loadModels('AcademicYear', 'academic_year', 'DESC');
            $Classroom = ClassRegistry::init('Classroom');
            $results = $Classroom->findHeadTutorClassrooms();
            $response = array();            
            if($results) {   
                foreach ($results as $result){
                    $res[] = array(						
                        "class_id"=>$this->encryption->encode($result['a']['class_id']),
                        "class_name"=>$result['a']['class_name'],
                        "employee_id"=>$result['a']['employee_id'],
                        "employee_name"=>$result['a']['employee_name'],
                        "academic_year_id"=>$result['a']['academic_year_id'],
                        "academic_year"=>$result['a']['academic_year'],
                        "cls_yr_id"=>$this->encryption->encode($result['a']['class_id'].'/'.$result['a']['academic_year_id']),
                    );
                }
                $response['Classroom'] = $res;
                $response['Flag'] = 1;
            }
            $this->set('ClassRooms', $response);      
        }else{
            $this->accessDenialError();
        }        
    }
    
    //Seacrh for all the students in a classroom for a current academic year
    public function search_students() {
        $this->autoRender = false;
        $resultCheck = $this->Acl->check($this->group_alias, 'AttendsController');
        if($resultCheck){
            if ($this->request->is('ajax')) {
                $decrypt_id = $this->encryption->decode($this->request->data('cls_yr_id'));
                $class_id = explode('/', $decrypt_id)[0];
                $year_id = explode('/', $decrypt_id)[1];
                $results = $this->Attend->findStudentClassroom($year_id, $class_id);
                $response = array();            
                if($results) {
                    //All the students in the classroom
                    foreach ($results as $result){
                        $res[] = array(						
                            "student_id"=>$result['a']['student_id'],
                            "student_name"=>$result['a']['student_name'],
                            "student_no"=>$result['a']['student_no']
                        );
                    }
                    $response['Students'] = $res;
                    $response['ClassID'] = $class_id;
                    $response['Flag'] = 1;
                } else {
                    $response['Students'] = null;
                    $response['Flag'] = 0;
                }
                echo json_encode($response);
            }
        }else{
            $this->accessDenialError('You Are Not Authorize To Perform Such Task', 2);
        }
    }
    
    //Take Attendance of students in the class
    public function take_attend() {
        $this->autoRender = false;
        $resultCheck = $this->Acl->check($this->group_alias, 'AttendsController');
        if($resultCheck){
            if ($this->request->is('ajax')) {
                $this->Attend->create();
                $data = $this->request->data['Attend'];     
                $stud_ids = $data['student_ids'];
                if($this->Attend->save($data)){
                    $Attend = $this->Attend->find('first', array('conditions' => array('Attend.attend_id' => $this->Attend->getLastInsertId())));
                    $out = $Attend['Classroom']['class_name'].' '.$Attend['AcademicTerm']['academic_term'].' on '.$Attend['Attend']['attend_date'];
                    //Procedure Call $stud_idss
                    $this->Attend->proc_insertAttendDetails($this->Attend->getLastInsertId(), $stud_ids);
                    $this->setFlashMessage('The Attendance Has Been Taken for '.$out, 1);   
                    echo $this->Attend->getLastInsertId();
                }
            }
         }else{
            $this->accessDenialError('You Are Not Authorize To Perform Such Task', 2);
        }
    }
    
    //Validate if the attendance has been taken for the class on that date
    public function validateIfExist() {        
        $this->autoRender = false;
        if ($this->request->is('ajax')) {
            $AcademicTerm = ClassRegistry::init('AcademicTerm');
            $attend_date = $this->request->data['Attend']['attend_date'];
            $class_id = $this->request->data['Attend']['class_id'];
            $results = $this->Attend->find('first', array(
                'conditions' => array(
                        'Attend.academic_term_id' => $AcademicTerm->getCurrentTermID(),
                        'Attend.class_id' => $class_id,
                        'Attend.attend_date' => $this->Attend->dateFormat($attend_date)
                    )
                )
            );
            echo (!empty($results['Attend'])) ? '1' : '0';
        }
    }
    
    //Seacrh for all the attendance taken
    public function search_attend() {
        $this->autoRender = false;
        $resultCheck = $this->Acl->check($this->group_alias, 'AttendsController');
        if($resultCheck){
            if ($this->request->is('ajax')) {
                $data = $this->request->data['SearchAttend'];
                $term_id = $data['academic_term_id'];
                $classlevel_id = ($data['classlevel_id'] === '') ? null : $data['classlevel_id'];
                $search_date = ($data['search_date'] === '') ? null : $this->Attend->dateFormat($data['search_date']);
                $date_from = ($data['date_from'] === '') ? null : $this->Attend->dateFormat($data['date_from']);
                $date_to = ($data['date_to'] === '') ? null : $this->Attend->dateFormat($data['date_to']);
                $results = $this->Attend->findAttendance($term_id, $classlevel_id, $search_date, $date_from, $date_to);
                $response = array();      
                if($results) {
                    foreach ($results as $result){
                        $res[] = array(						
                            "attend_id"=>$this->encryption->encode($result['a']['attend_id']),
                            "class_id"=>$result['a']['class_id'],
                            "academic_term_id"=>$result['a']['academic_term_id'],
                            "class_name"=>$result['a']['class_name'],
                            "academic_term"=>$result['a']['academic_term'],
                            "head_tutor"=>$result['a']['head_tutor'],
                            "attend_date"=>  $this->Attend->SQLDateToPHP($result['a']['attend_date']),
                        );
                    }
                    $response['Attend'] = $res;
                    $response['Flag'] = 1;
                } else {
                    $response['Attend'] = null;
                    $response['Flag'] = 0;
                }
                echo json_encode($response);
            }
        }else{
            $this->accessDenialError('You Are Not Authorize To Perform Such Task', 2);
        }
    }
    
    //Seacrh for all the attendance taken
    public function view($encrypt_id) {
        $this->set('title_for_layout', 'Attendance Status');
        $resultCheck = $this->Acl->check($this->group_alias, 'AttendsController');
        if($resultCheck){
            $decrypt_id = $this->encryption->decode($encrypt_id);
            $options = array('conditions' => array('Attend.' . $this->Attend->primaryKey => $decrypt_id));
            $Attend = $this->Attend->find('first', $options);
            $results = $this->Attend->findAttendDetails($decrypt_id, $Attend['AcademicTerm']['academic_year_id'], $Attend['Classroom']['class_id']);
            $response = array();      
            if($results) {
                foreach ($results as $result){
                    $res[] = array(						
                        "student_id"=>$this->encryption->encode($result[0]['student_id']),
                        "student_name"=>$result[0]['student_name'],
                        "student_no"=>$result[0]['student_no'],
                        "class_name"=>$result[0]['class_name'],
                        "attend_id"=>$result[0]['attend_id']
                    );
                }
                $response['AttendDetail'] = $res;
                $response['Flag'] = 1;
            } else {
                $response['AttendDetail'] = null;
                $response['Flag'] = 0;
            }
            $this->set('AttendDetails', $response);
            $this->set('Attends', $Attend);
        }else{
            $this->accessDenialError('You Are Not Authorize To Perform Such Task', 2);
        }
    }
    
    //Take Attendance of students in the class
    public function edit($encrypt_id) {
        $this->set('title_for_layout', 'Modify Attendance');
        $this->loadModels('AcademicYear', 'academic_year', 'DESC');
        $resultCheck = $this->Acl->check($this->group_alias, 'AttendsController');
        if($resultCheck){
            $decrypt_id = $this->encryption->decode($encrypt_id);
            $Attend = $this->Attend->find('first', array('conditions' => array('Attend.' . $this->Attend->primaryKey => $decrypt_id)));
            
            if ($this->request->is('post')) {
                $data = $this->request->data['AttendDetails'];     
                $out = $Attend['Classroom']['class_name'].' '.$Attend['AcademicTerm']['academic_term'].' on '.$Attend['Attend']['attend_date'];
                //Procedure Call $stud_idss
                $this->Attend->proc_insertAttendDetails($decrypt_id, $data['student_ids']);
                $this->setFlashMessage('The Attendance Has Been Modified for '.$out, 1);   
                return $this->redirect(array('action' => 'view/'.$encrypt_id));
            }  else {
                $this->set('Presents', $this->Attend->findStudentsPresent($decrypt_id));
                $this->set('Absents', $this->Attend->findStudentsAbsent($decrypt_id, $Attend['AcademicTerm']['academic_year_id'], $Attend['Classroom']['class_id']));
                $this->set('Attend', $Attend);
            }
         }else{
            $this->accessDenialError('You Are Not Authorize To Perform Such Task', 2);
        }
    }
    
    //Seacrh for all the attendance summary taken
    public function search_summary() {
        $this->autoRender = false;
        $resultCheck = $this->Acl->check($this->group_alias, 'AttendsController');
        if($resultCheck){
            if ($this->request->is('ajax')) {
                $data = $this->request->data['SummaryAttend'];
                $term_id = $data['academic_term_id_all'];
                $classlevel_id = ($data['classlevel_id_all'] === '') ? null : $data['classlevel_id_all'];
                $results = $this->Attend->searchSummary($term_id, $classlevel_id);
                $response = array();      
                if($results) {
                    foreach ($results as $result){
                        $res[] = array(						
                            "class_id"=>$result['a']['class_id'],
                            "academic_term_id"=>$result['a']['academic_term_id'],
                            "class_name"=>$result['a']['class_name'],
                            "academic_term"=>$result['a']['academic_term'],
                            "head_tutor"=>$result['a']['head_tutor'],
                            "cls_term_id"=>$this->encryption->encode($result['a']['class_id'].'/'.$result['a']['academic_term_id']),
                        );
                    }
                    $response['Summary'] = $res;
                    $response['Flag'] = 1;
                } else {
                    $response['Summary'] = null;
                    $response['Flag'] = 0;
                }
                echo json_encode($response);
            }
        }else{
            $this->accessDenialError('You Are Not Authorize To Perform Such Task', 2);
        }
    }
    
    
    //Get for the attenance summary for number of days present and absent
    public function summary($encrypt_id) {
        $this->set('title_for_layout', 'Attendance Summary');
        $resultCheck = $this->Acl->check($this->group_alias, 'AttendsController');
        if($resultCheck){
            $decrypt_id = $this->encryption->decode($encrypt_id);
            $class_id = explode('/', $decrypt_id)[0];
            $term_id = explode('/', $decrypt_id)[1];
            
            $results = $this->Attend->findAttendDaysSummary($term_id, $class_id);
            $response = array();      
            if($results) {
                foreach ($results as $result){
                    $res[] = array(						
                        "student_id"=>$this->encryption->encode($result['a']['student_id']),
                        "term_cls_std_id"=>$this->encryption->encode($term_id.'/'.$class_id.'/'.$result['a']['student_id']),
                        "student_no"=>$result['a']['student_no'],
                        "student_name"=>$result['a']['student_name'],
                        "total_attendance"=>$result['a']['total_attendance'],
                        "days_present"=>$result['a']['days_present'],
                        "days_absent"=>$result['a']['days_absent'],
                        "class_name"=>$result['a']['class_name'],
                        "head_tutor"=>$result['a']['head_tutor'],
                        "academic_term"=>$result['a']['academic_term']
                    );
                }
                $response['AttendSummary'] = $res;
            } 
            $this->set('AttendSummarys', $response);
        }else{
            $this->accessDenialError('You Are Not Authorize To Perform Such Task', 2);
        }
    }
    
    
    //Get for the attenance deatils for number of days present and absent with date
    public function details($encrypt_id) {
        $this->set('title_for_layout', 'Attendance Details');
        $resultCheck = $this->Acl->check($this->group_alias, 'AttendsController');
        if($resultCheck){
            $decrypt_id = $this->encryption->decode($encrypt_id);
            $term_id = explode('/', $decrypt_id)[0];
            $class_id = explode('/', $decrypt_id)[1];
            $std_id = explode('/', $decrypt_id)[2];
            
            $results = $this->Attend->findAttendDaysDetails($term_id, $class_id, $std_id);
            $response = array();      
            if($results) {
                foreach ($results as $result){
                    $res[] = array(						
                        "student_no"=>$result[0]['student_no'],
                        "student_name"=>$result[0]['student_name'],
                        "class_name"=>$result[0]['class_name'],
                        "academic_term"=>$result[0]['academic_term'],
                        "head_tutor"=>$result[0]['head_tutor'],
                        "attend_date"=>$result[0]['attend_date'],
                        "attend_status_id"=>$result[0]['attend_status_id'],
                        "attend_status"=>$result[0]['attend_status']
                    );
                }
                $response['AttendDetail'] = $res;
            } 
            $this->set('AttendDetails', $response);
        }else{
            $this->accessDenialError('You Are Not Authorize To Perform Such Task', 2);
        }
    }
    /////////////////////////////////////// \\\ actions ///////////////////////////////////////////////
}

?>