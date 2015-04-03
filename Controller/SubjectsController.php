<?php
App::uses('AppController', 'Controller');

class SubjectsController extends AppController {

    public function beforeFilter() {
        parent::beforeFilter();
        $this->masterRedirect();
    }

    public function ajax_get_subjects($model, $parentLB) {
        $parentLB = str_replace('#', '', $parentLB);
        $id = $this->request->data[$model][$parentLB];
        $subjects = $this->Subject->find('list', array(
			'conditions' => array('Subject.subject_group_id' => $id),
            'order'=>array('Subject.subject_name'),
			'recursive' => -1
			));
        $this->set('subjects', $subjects);
		$this->layout = 'ajax';
    }
    //Add Subjects to class room Parent Page and loads all the required drop downs
    public function add2class() {
        $result = $this->Acl->check($this->group_alias, 'SubjectsController/add2class');
        if($result){
            $this->loadModels('SubjectGroup');
            $this->loadModels('Classlevel');
            $this->loadModels('AcademicYear', 'academic_year', 'DESC');
            $Employee = ClassRegistry::init('Employee');
            $result = $Employee->find('list',
                array('conditions' => array('Employee.status_id' => 1), 'fields'=>array('employee_id', 'full_name'), 'order'=>array('Employee.full_name'))
            );
            $this->set('Employees', $result);
        }else{
            $this->accessDenialError();
        }
    }
    //Assign a subject to a classlevel or classroom
    public function assign() {
        $this->autoRender = false;
        $result = $this->Acl->check($this->group_alias, 'SubjectsController');
        $count = 0;
        if($result){
            $subjectClasslevel = ClassRegistry::init('SubjectClasslevel');
            if ($this->request->is('ajax')) {
                //$options = array('conditions' => array('Classroom.classlevel_id' => $this->request->data['SubjectClasslevel']['classlevel_id']));
//                $subject_id = $this->request->data['SubjectClasslevel']['subject_id'];
//                $classlevel_id = $this->request->data['SubjectClasslevel']['classlevel_id'];
//                $academic_term_id = $this->request->data['SubjectClasslevel']['academic_term_id'];
//                $class_id = ($this->request->data['SubjectClasslevel']['class_id'] !== '') ? $this->request->data['SubjectClasslevel']['class_id'] : null;
                
                $subjectClasslevel->create();
                $data = $subjectClasslevel->data['SubjectClasslevel'];                
                $data['class_id'] = $this->request->data['SubjectClasslevel']['class_id'];
                $data['subject_id'] = $this->request->data['SubjectClasslevel']['subject_id'];
                $data['classlevel_id'] = $this->request->data['SubjectClasslevel']['classlevel_id'];
                $data['academic_term_id'] = $this->request->data['SubjectClasslevel']['academic_term_id'];
                if($subjectClasslevel->save($data)) {
                    $this->Subject->proc_assignSubject2Students($subjectClasslevel->getLastInsertId());
                    echo $subjectClasslevel->getLastInsertId();
                }
                
//                if($class_id !== null){                    
//                    
//                    if($subjectClasslevel->save($data)) {
//                        $this->Subject->proc_assignSubject2Students($subjectClasslevel->getLastInsertId());
//                        $count++;
//                    }
//                }else{
//                    $Classrooms = $ClassroomModel->find('all', $options);
//                    foreach ($Classrooms as $Classroom) {
//                        $subjectClasslevel->create();
//                        $data['class_id'] = $Classroom['Classroom']['class_id'];
//                        if($subjectClasslevel->save($data)) {
//                           $this->Subject->proc_assignSubject2Students($subjectClasslevel->getLastInsertId());
//                            $count++;
//                        }
//                    }
//                }
//                echo $count;
            }
        }else{
            $this->accessDenialError('You Are Not Authorize To Perform Such Task', 2);
        }
    }
    //Validate if the subject has been assigned to a classlevel or classroom
    public function validateIfExist() {        
        $this->autoRender = false;
        $SubjectClasslevel = ClassRegistry::init('SubjectClasslevel');
        if ($this->request->is('ajax')) {
            $class = ($this->request->data['SubjectClasslevel']['class_id'] !== '') ? $this->request->data['SubjectClasslevel']['class_id'] : null;
            $classlevel = $this->request->data['SubjectClasslevel']['classlevel_id'];
            $term_id = $this->request->data['SubjectClasslevel']['academic_term_id'];
            $subject_id = $this->request->data['SubjectClasslevel']['subject_id'];
            $results = $SubjectClasslevel->validateIfExist($subject_id, $term_id, $classlevel, $class);
            echo (($results)) ? 1 : 0;
        }
    }
    //Seacrh for all the subjects assigned to a classlevel or classroom for a specific academic year
    public function search_all() {
        $this->autoRender = false;
        $resultCheck = $this->Acl->check($this->group_alias, 'SubjectsController');
        if($resultCheck){
            $SubjectClasslevel = ClassRegistry::init('SubjectClasslevel');
            if ($this->request->is('ajax')) {
                $class = ($this->request->data['SubjectClasslevel']['class_id_all'] !== '') ? $this->request->data['SubjectClasslevel']['class_id_all'] : null;
                $classlevel = $this->request->data['SubjectClasslevel']['classlevel_id_all'];
                $term_id = $this->request->data['SubjectClasslevel']['academic_term_id_all'];
                $results = $SubjectClasslevel->findSubjectsByClasslevelOrClass($term_id, $classlevel, $class);
                $response = array();            
                if($results) {   
                    //All the subjects by classlevel or classroom
                    foreach ($results as $result){
                        $res[] = array(						
                            "subject_name"=>$result['a']['subject_name'],
                            "subject_id"=>$result['a']['subject_id'],
                            "class_name"=>$result['a']['class_name'],
                            "class_id"=>$result['a']['class_id'],
                            "exam_id"=>(empty($result['c']['exam_id'])) ? '-1' : $result['c']['exam_id'],
                            "classlevel"=>$result['a']['classlevel'],
                            "subject_classlevel_id"=>$result['a']['subject_classlevel_id'],
                            "exam_status"=>(empty($result['c']['exam_id'])) ? '<span class="label label-danger">Not Setup</span>' : '<span class="label label-success">Already Setup</span>',
                            "examstatus_id"=>$result['a']['examstatus_id'],
                            "employee_id"=>(empty($result['b']['employee_id'])) ? -1 : $result['b']['employee_id'],
                            "teachers_subjects_id"=>(empty($result['b']['teachers_subjects_id'])) ? -1 : $result['b']['teachers_subjects_id'],
                            "employee_name"=>(empty($result['b']['employee_name'])) ? '<span class="label label-danger">nill</span>' : $result['b']['employee_name'] 
                        );
                    }
                    $response['SubjectClasslevel'] = $res;
                    $response['Flag'] = 1;
                }  else {
                    $response['SubjectClasslevel'] = null;
                    $response['Flag'] = 0;
                }
                echo json_encode($response);
            }
        }else{
            $this->accessDenialError('You Are Not Authorize To Perform Such Task', 2);
        }
    }
    
    //Assign Tutor to Subjects in a class room
    public function assign_tutor() {
        $this->autoRender = false;
        $resultCheck = $this->Acl->check($this->group_alias, 'SubjectsController');
        if($resultCheck){
            $TeachersSubject = ClassRegistry::init('TeachersSubject');
            if ($this->request->is('ajax')) {
                //when teachers_subjects_id => -1 assign new else update existing
                if($this->request->data('teac_sub_id') === '-1'){
                    $TeachersSubject->create();//$this->request->data('class_id')
                    $TeachersSubject->data['TeachersSubject']['employee_id'] = $this->request->data('emp_id');
                    $TeachersSubject->data['TeachersSubject']['class_id'] = $this->request->data('class_id');
                    $TeachersSubject->data['TeachersSubject']['subject_classlevel_id'] = $this->request->data('sub_class_id');
                    $TeachersSubject->data['TeachersSubject']['assign_date'] = $TeachersSubject->dateFormatBeforeSave();
                    echo ($TeachersSubject->save()) ? $TeachersSubject->getLastInsertId() : 0;
                }else{
                    $TeachersSubject->id = $this->request->data('teac_sub_id');
                    $TeachersSubject->data['TeachersSubject']['employee_id'] = $this->request->data('emp_id');
                    $TeachersSubject->data['TeachersSubject']['class_id'] = $this->request->data('class_id');
                    $TeachersSubject->data['TeachersSubject']['subject_classlevel_id'] = $this->request->data('sub_class_id');
                    echo ($TeachersSubject->save()) ? $TeachersSubject->id : 0;
                }
            }
         }else{
            $this->accessDenialError('You Are Not Authorize To Perform Such Task', 2);
        }
    }
    //Search for subjects Assigned to a classlevel or classroom for modifications
    public function search_assigned() {
        $this->autoRender = false;
        $resultCheck = $this->Acl->check($this->group_alias, 'SubjectsController');
        if($resultCheck){
            $SubjectClasslevel = ClassRegistry::init('SubjectClasslevel');
            if ($this->request->is('ajax')) {
                //$class = ($this->request->data['SubjectClasslevel']['class_search_id'] !== '') ? $this->request->data['SubjectClasslevel']['class_search_id'] : null;
                $classlevel = $this->request->data['SubjectClasslevel']['classlevel_search_id'];
                $term_id = $this->request->data['SubjectClasslevel']['academic_term_search_id'];
                $results = $SubjectClasslevel->findSubjectsAssigned($term_id, $classlevel);
                $response = array();            
                if($results) {   
                    //All the subjects by classlevel or classroom
                    foreach ($results as $result){
                        $res[] = array(						
                            "subject_name"=>$result['a']['subject_name'],
                            "subject_id"=>$result['a']['subject_id'],
                            "class_name"=>(empty($result['a']['class_name'])) ? '<span class="label label-danger">nill</span>' : $result['a']['class_name'],
                            "class_id"=>(empty($result['a']['class_id'])) ? -1 : $result['a']['class_id'],
                            "classlevel"=>$result['classlevels']['classlevel'],
                            "classlevel_id"=>$result['classlevels']['classlevel_id'],
                            "academic_term"=>$result['a']['academic_term'],
                            "academic_term_id"=>$result['a']['academic_term_id'],
                            "subject_classlevel_id"=>$result['a']['subject_classlevel_id'],
                            "exam_status"=>($result['a']['examstatus_id'] === '2') ? '<span class="label label-danger">'.$result['a']['exam_status'].'</span>' : '<span class="label label-success">'.$result['a']['exam_status'].'</span>',
                            "examstatus_id"=>$result['a']['examstatus_id'],
                            //"exam_id"=>$result['b']['exam_id']
                        );
                    }
                    $response['SubjectClasslevel'] = $res;
                    $response['Flag'] = 1;
                } else {
                    $response['SubjectClasslevel'] = null;
                    $response['Flag'] = 0;
                }
                echo json_encode($response);
            }
        }else{
            $this->accessDenialError('You Are Not Authorize To Perform Such Task', 2);
        }
    }
    
    //Modify Subject Assigned to a Class Level or Class Room
    public function modify_assign() {
        $this->autoRender = false;
        $resultCheck = $this->Acl->check($this->group_alias, 'SubjectsController');
        if($resultCheck){
            $SubjectClasslevel = ClassRegistry::init('SubjectClasslevel');
            if ($this->request->is('ajax')) {
                //when teachers_subjects_id => -1 assign new else update existing
                $data = $this->request->data['ModifySubjectClasslevel'];
                $SubjectClasslevel->id = $data['subject_classlevel_modify_id'];
                $SubjectClasslevel->data['SubjectClasslevel']['subject_id'] = $data['subject_modify_id'];
                $SubjectClasslevel->data['SubjectClasslevel']['classlevel_id'] = $data['classlevel_modify_id'];
                $SubjectClasslevel->data['SubjectClasslevel']['class_id'] = ($data['class_modify_id'] === -1) ? NULL : $data['class_modify_id'];
                $SubjectClasslevel->data['SubjectClasslevel']['academic_term_id'] = $data['academic_term_modify_id'];
                if($SubjectClasslevel->save()) {
                    $this->Subject->proc_assignSubject2Students($data['subject_classlevel_modify_id']);
                    echo $data['subject_classlevel_modify_id'];
                }else {
                    echo 0;
                }
            }
        }else{
            $this->accessDenialError('You Are Not Authorize To Perform Such Task', 2);
        }
    }

    //Delete Subject Assigned to a Class Level or Class Room
    public function delete_assign() {
        $this->autoRender = false;
        $resultCheck = $this->Acl->check($this->group_alias, 'SubjectsController');
        if($resultCheck){
            $SubjectClasslevel = ClassRegistry::init('SubjectClasslevel');
            if ($this->request->is('ajax')) {
                $id = $this->request->data('subject_classlevel_id');
                echo ($SubjectClasslevel->deleteSubjectClasslevel($id)) ? 1 : 0;
            }
        }else{
            $this->accessDenialError('You Are Not Authorize To Perform Such Task', 2);
        }
    }
    
    //Seacrh for all the students in a classroom or classlevel offering that subject for a current academic term
    public function search_students() {
        $this->autoRender = false;
        $resultCheck = $this->Acl->check($this->group_alias, 'SubjectsController');
        if($resultCheck){
            if ($this->request->is('ajax')) {
                $SubjectClasslevel = ClassRegistry::init('SubjectClasslevel');
                $results = $SubjectClasslevel->findStudentsBySubjectClasslevel($this->request->data('subject_classlevel_id'));
                $results2 = $SubjectClasslevel->findStudentsBySubjectsNot($this->request->data('subject_classlevel_id'));
                $response = array();            
                if($results) {
                    //All the students offering the subjects in a classroom or classlevel
                    foreach ($results as $result){
                        $res[] = array(						
                            "student_id"=>$result['a']['student_id'],
                            "student_name"=>$result['a']['student_name'],
                            "student_no"=>$result['a']['student_no']
                        );
                    }
                    $response['SubjectClasslevel'] = $res;
                    $response['Flag'] = 1;
                } else {
                    $response['SubjectClasslevel'] = null;
                    $response['Flag'] = 0;
                }
                if($results2) {
                    //All the students without classroom assigned to them
                    foreach ($results2 as $result){
                        $res2[] = array(						
                            "student_id"=>$result['a']['student_id'],
                            "student_name"=>$result['a']['student_name'],
                            "student_no"=>$result['a']['student_no']
                        );
                    }
                    $response['SubjectNoClasslevel'] = $res2;
                    $response['Flag2'] = 1;
                }  else {
                    $response['SubjectNoClasslevel'] = null;
                    $response['Flag2'] = 0;
                }
                echo json_encode($response);
            }
        }else{
            $this->accessDenialError('You Are Not Authorize To Perform Such Task', 2);
        }
    }
    
    //Update Subjects Students Registered Table with the list of students
    public function updateStudentsSubjects() {
        $this->autoRender = false;
        $SubjectClasslevel = ClassRegistry::init('SubjectClasslevel');
        if ($this->request->is('ajax')) {
            $subject_classlevel_id = $this->request->data('sub_cls_id');
            $stud_ids = $this->request->data('stud_ids');
            if($stud_ids !== ''){
                echo $SubjectClasslevel->updateStudentsSubjects($subject_classlevel_id, $stud_ids);
            } else {
                echo 0;
            }
        }
    }


    /////////////////////////////////////////////////////////////////////////// Subject View Analysis //////////////////////////////////////////
    //// View Student Subject
    public function index() {
        $result = $this->Acl->check($this->group_alias, 'SubjectsController');
        if($result){
            $this->loadModels('SubjectGroup');
            $this->loadModels('Classlevel');
            $this->loadModels('AcademicYear', 'academic_year', 'DESC');
        }else{
            $this->accessDenialError();
        }
    }


    //Search for students that offered a subject in a class for an academic term
    public function search_subject() {
        $this->autoRender = false;
        $resultCheck = $this->Acl->check($this->group_alias, 'SubjectsController');
        if($resultCheck){
            if ($this->request->is('ajax')) {
                $term_id = $this->request->data['SubjectStudentView']['academic_view_term_id'];
                $subject_id = $this->request->data['SubjectStudentView']['subject_view_id'];
                $class_id = $this->request->data['SubjectStudentView']['class_view_id'];

                $results = $this->Subject->findStudentsSubject($term_id, $subject_id, $class_id);
                $response = array();
                $wa1 = $wa2 = $waexam = $waTotal =0;
                if($results) {
                    //All the students offering the subjects in a classroom or classlevel
                    foreach ($results as $result){
                        $wa1 = $result['a']['weightageCA1'];
                        $wa2 = $result['a']['weightageCA2'];
                        $waexam = $result['a']['weightageExam'];
                        $waTotal = $wa1 + $wa2 + $waexam;
                        $res[] = array(
                            "std_sub_cla_term_id"=>$this->encryption->encode($result['a']['student_id'].'/'.$result['a']['subject_id'].'/'.$class_id.'/'.$term_id),
                            "student_fullname"=>$result['a']['student_fullname'],
                            "ca1"=>$result['a']['ca1'],
                            "ca2"=>$result['a']['ca2'],
                            "exam"=>$result['a']['exam'],
                            "sum_total"=>number_format($result[0]['sum_total'], 2)
                        );
                    }
                    $response['StudentScores'] = $res;
                    $response['Flag'] = 1;
                } else {
                    $response['StudentScores'] = null;
                    $response['Flag'] = 0;
                }
                $response['WA1'] = $wa1;
                $response['WA2'] = $wa2;
                $response['WAExam'] = $waexam;
                $response['WATotal'] = $waTotal;
                echo json_encode($response);
            }
        }else{
            $this->accessDenialError('You Are Not Authorize To Perform Such Task', 2);
        }
    }

    //Controller for displaying summary of students subject in a class
    public function view($encrypt_id, $position=0) {
        $this->set('title_for_layout','Subject Analysis Summary');
        $resultCheck = $this->Acl->check($this->group_alias, 'SubjectsController');
        if($resultCheck){
            //Decrypt the id sent
            $decrypt_id = $this->encryption->decode($encrypt_id);
            $encrypt = explode('/', $decrypt_id);
            $student_id = $encrypt[0];
            $subject_id = $encrypt[1];
            $class_id = $encrypt[2];
            $term_id = $encrypt[3];

            $results = $this->Subject->findStudentsSubjectSummary($student_id, $subject_id, $class_id, $term_id);
            $response = array();
            $response2 = array();
            if(!empty($results[0])) {
                $response = array_shift($results[0]);
            } else {
                $response['StudentScore'] = null;
            }
            if(!empty($results[1])) {
                $response2 = array_shift($results[1]);
                $response2['Position'] = $position;
            } else {
                $response2['AnalysisScore'] = null;
            }
            $this->set('StudentScore', $response);
            $this->set('AnalysisScore', $response2);
        }else{
            $this->accessDenialError('You Are Not Authorize To Perform Such Task', 2);
        }
    }
}