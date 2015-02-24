<?php
App::uses('AppController', 'Controller');

class DashboardController extends AppController {

    public $components = array('Paginator');
    
    private $student;
    
    // only allow the login controllers only
    public function beforeFilter() {
        parent::beforeFilter();
        $this->student = ClassRegistry::init('Student');
        //$this->layout = 'default_web'; 
    }
    
    /////////////////////////////////////// Sponsors or Students actions ///////////////////////////////////////////////
    public function index() {
        //$student = ClassRegistry::init('Student');
        //$student->createNewUser('spn0001 ', 'KayOh', 'China', 1, 'sponsors/1.jpg', 1);
        $result = $this->Acl->check($this->group_alias, 'DashboardController', 'read');
        if($result){
            $employee = ClassRegistry::init('Employee');
            $sponsor = ClassRegistry::init('Sponsor');
            $Classroom = ClassRegistry::init('Classroom');
            $Subject = ClassRegistry::init('Subject');

            $class = $Classroom->findHeadTutorCurrentClassrooms();
            $subj = $Subject->findCurrentTermSubjectTutor();

            $this->set('class_count', count($class));
            $this->set('subject_count', count($subj));
            //$options = array('conditions' => array('Student.student_status_id' => 1));
            $this->set('students', $this->student->find('count'));
            $this->set('active_students', $this->student->find('count', array('conditions' => array('Student.student_status_id' => 1))));

            $this->set('employees', $employee->find('count'));
            $this->set('active_employees', $employee->find('count', array('conditions' => array('Employee.status_id' => 1))));

            $this->set('sponsors', $sponsor->find('count'));
            
            //$StudentStatus = ClassRegistry::init('StudentStatus');
            //echo ($StudentStatus->sendMail('Test', 'Authentication', 'kingsley4united@yahoo.com', 'KayOh')) ? 'Sent' : 'Not Sent';
        }else{
            $this->accessDenialError();            
        }
    }
    
    public function tutor() {
        //$student = ClassRegistry::init('Student');
//        $body = 'Your Password Has Been Reset<br>';
//        $body .= 'New Password = <b>786tfu</b><br>';
//        
//        $this->layout = 'Emails/html/default';
//        $this->set('name', 'KayOh');
//        $this->set('heading', 'Password Reset');
//        $this->set('content', $body);
//        return $this->render('/Emails/html/default');
        $result = $this->Acl->check($this->group_alias, 'DashboardController');
        if($result){
            //$student = ClassRegistry::init('Student');
            $employee = ClassRegistry::init('Employee');
            $sponsor = ClassRegistry::init('Sponsor');
            //$options = array('conditions' => array('Student.student_status_id' => 1));
            $this->set('students', $this->student->find('count'));
            $this->set('active_students', $this->student->find('count', array('conditions' => array('Student.student_status_id' => 1))));
            
            $this->set('employees', $employee->find('count'));
            $this->set('active_employees', $employee->find('count', array('conditions' => array('Employee.status_id' => 1))));
            
            $this->set('sponsors', $sponsor->find('count'));
            
        }else{
            $this->accessDenialError();            
        }
    }
    
    //Get all the students by gender including past and present
    public function studentGender() {
        $this->autoRender = false;
        if ($this->request->is('ajax')) {
            $response = array();
            $count = $this->student->find('count');
            $male_students = $this->student->find('count', array('conditions' => array('Student.gender' => 'Male')));
            $active_male_students = $this->student->find('count', array('conditions' => array('Student.gender' => 'Male', 'Student.student_status_id' => 1)));
            $female_students = $this->student->find('count', array('conditions' => array('Student.gender' => 'Female')));
            $active_female_students = $this->student->find('count', array('conditions' => array('Student.gender' => 'Female', 'Student.student_status_id' => 1)));
            $res[] = array("value" => (($male_students / $count) * 100), "label"=>'Male');
            $res[] = array("value" => (($female_students / $count) * 100), "label"=>'Female');
            $response['Gender'] = $res;
            $response['Count'] = $count;
            $response['Male'] = $male_students;
            $response['ActiveMale'] = $active_male_students;
            $response['Female'] = $female_students;
            $response['ActiveFemale'] = $active_female_students;
            //return $response;  
            echo json_encode($response);
        }
    }

    //Get all the students by status including past and present
    public function studentStauts() {
        $this->autoRender = false;
        if ($this->request->is('ajax')) {
            $StudentStatus = ClassRegistry::init('StudentStatus');
            $results = $StudentStatus->find('all');
            $count = $this->student->find('count');
            $response = array();
            foreach ($results as $result){
                $result_count = $this->student->find('count', array('conditions' => array('Student.student_status_id' => $result['StudentStatus']['student_status_id'])));
                $res[] = array(						
                    "value"=>(($result_count / $count) * 100),
                    "label"=>$result['StudentStatus']['student_status']
                );
                $res2[] = array(						
                    "count"=>$result_count,
                    "label"=>$result['StudentStatus']['student_status']
                );
            }
            $response['Count'] = $count;
            $response['CountEach'] = $res2;
            $response['Status'] = $res;
            echo json_encode($response);
        }
    }
    
    //Get all the students by payemnts status for the current academic term
    public function studentPaymentStatus() {
        $this->autoRender = false;
        if ($this->request->is('ajax')) {
            $Item = ClassRegistry::init('Item');
            $AcademicTerm = ClassRegistry::init('AcademicTerm');
            $results = $Item->CurrentTermPaymentStatus();
            $response = array();
            $res[] = array("value"=> intval($results[0]), "label"=>'Paid');
            $res[] = array("value"=>intval($results[1]), "label"=>'Not Paid');
            $response['CountAll'] = intval($results[0] + $results[1]);
            $response['Status'] = $res;
            $response['CurrentTerm'] = $AcademicTerm->getCurrentTermName();
            echo json_encode($response);
        }
    }
    
    //Get all the students by status including past and present
    public function studentClasslevel() {
        $this->autoRender = false;
        if ($this->request->is('ajax')) {
            $Classlevel = ClassRegistry::init('Classlevel');
            $AcademicTerm = ClassRegistry::init('AcademicTerm');
            $StudentsClass = ClassRegistry::init('StudentsClass');
            $results = $Classlevel->find('all');
            $response = array();
            foreach ($results as $result){
                $result_count = $StudentsClass->find('count', array('conditions' => 
                        array(
                            'StudentsClass.academic_year_id' => $AcademicTerm->getCurrentYearID(),
                            'Classroom.classlevel_id' => $result['Classlevel']['classlevel_id']
                        )
                    ));
                $res[] = array(						
                    "label"=>$result['Classlevel']['classlevel'],
                    "value"=>  intval($result_count)
                );
            }
            $response['CurrentYear'] = $AcademicTerm->getCurrentYearName();
            $response['Classlevel'] = $res;
            echo json_encode($response);
        }
    }
    
    
    //Get all the Classes Assigned to a Head Tutor for the current Academic Year
    public function classHeadTutor() {
        $this->autoRender = false;
        if ($this->request->is('ajax')) {
            $Classroom = ClassRegistry::init('Classroom');
            $AcademicTerm = ClassRegistry::init('AcademicTerm');
            $StudentsClass = ClassRegistry::init('StudentsClass');

            $results = $Classroom->findHeadTutorCurrentClassrooms();
            $response = array();
            if($results){
                foreach ($results as $result){
                    $result_count = $StudentsClass->find('count', array('conditions' => 
                            array(
                                'StudentsClass.academic_year_id' => $AcademicTerm->getCurrentYearID(),
                                'StudentsClass.class_id' => $result['a']['class_id']
                            )
                        ));
                    $res[] = array(						
                        "label"=>$result['a']['class_name'],
                        "value"=>  intval($result_count)
                    );
                }
                $response['CurrentYear'] = $AcademicTerm->getCurrentYearName();
                $response['Classroom'] = $res;
                echo json_encode($response);
            }else{
                echo 'No Class Room Assigned Yet';
            }
        }
    }
    
    //Get all the Subjects Assigned to a Head Tutor for the current Academic Term
    public function subjectHeadTutor() {
        $this->autoRender = false;
        if ($this->request->is('ajax')) {
            $Subject = ClassRegistry::init('Subject');
            $AcademicTerm = ClassRegistry::init('AcademicTerm');
            $count = 5;
            $results = $Subject->findCurrentTermSubjectTutor();
            $response = array();
            if($results){
                foreach ($results as $result){
                    $res[] = array(						
                        "label"=>$result['a']['class_name'],
                        "value"=>$count//
                    );
                    $Subj[] = $result['a']['subject_name'];
                    $SubjCount[] = $count;
                    $count = $count + 5;
                }
                $response['CurrentTerm'] = $AcademicTerm->getCurrentTermName();
                $response['Subject'] = $res;
                $response['Subj'] = $Subj;
                $response['Count'] = $SubjCount;
                echo json_encode($response);
            }else{
                echo 'No Subject Has Been Assigned To You Yet';
            }
        }
    }
}

?>