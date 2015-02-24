<?php
App::uses('AppController', 'Controller');
/**
 * AcademicTerms Controller
 *
 * @property AcademicTerm $AcademicTerm
 * @property PaginatorComponent $Paginator
 * @property SessionComponent $Session
 */
class ClassroomsController extends AppController {

    public function ajax_get_classes($model, $parentLB) {
        $parentLB = str_replace('#', '', $parentLB);
        $id = $this->request->data[$model][$parentLB];
        $classes = $this->Classroom->find('list', array(
            'conditions' => array('Classroom.classlevel_id' => $id),
            'recursive' => -1
        ));
        $this->set('classes', $classes);
        $this->layout = 'ajax';
    }

    public function index() {
        $this->set('title_for_layout','Assigning Students To Class Rooms');
        $result = $this->Acl->check($this->group_alias, 'ClassroomsController');
        if($result){
            $Employee = ClassRegistry::init('Employee');
            $this->loadModels('Classlevel');
            $this->loadModels('AcademicYear', 'academic_year', 'DESC');
            $result = $Employee->find('list',
                array('conditions' => array('Employee.status_id' => 1), 'fields'=>array('employee_id', 'full_name'), 'order'=>array('Employee.full_name'))
            );
            $this->set('Employees', $result);
        }else{
            $this->accessDenialError();
        }
    }
    
    //Displays all the classroom(s) assigned to a head tutor
     public function myclass() {
        $this->set('title_for_layout', 'My Class Rooms');
        $result = $this->Acl->check($this->group_alias, 'ClassroomsController/myclass');
        if($result){
            $results = $this->Classroom->findHeadTutorClassrooms();
            $response = array();            
            if($results) {   
                //All the subjects by classlevel or classroom
                foreach ($results as $result){
                    $res[] = array(						
                        "class_id"=>$result['a']['class_id'],
                        "class_name"=>$result['a']['class_name'],
                        "employee_id"=>$result['a']['employee_id'],
                        "employee_name"=>$result['a']['employee_name'],
                        "academic_year_id"=>$result['a']['academic_year_id'],
                        "academic_year"=>$result['a']['academic_year'],
                        "cls_yr_id"=>$this->encryption->encode($result['a']['class_id'].'/'.$result['a']['academic_year_id']),
                        "created_at"=>$result['a']['created_at']
                    );
                }
                $response['Classroom'] = $res;
                $response['Flag'] = 1;
            }  else {
                $response['Classroom'] = null;
                $response['Flag'] = 0;
            }
            $this->set('ClassRooms', $response);        
        }else{
            $this->accessDenialError();
        }
    }
    
    ////Find all the classrooms in a classlevel and the head tutor assigned
    public function search_classes() {
        $this->autoRender = false;
        $resultCheck = $this->Acl->check($this->group_alias, 'ClassroomsController');
        if($resultCheck){
            if ($this->request->is('ajax')) {
                $classlevel_id = $this->request->data['TeachersClass']['classlevel_id_search'];
                $year_id = $this->request->data['TeachersClass']['academic_year_id_search'];
                $results = $this->Classroom->findClassByClasslevel($classlevel_id, $year_id);
                $response = array();            
                if($results) {   
                    //All the subjects by classlevel or classroom
                    foreach ($results as $result){
                        $res[] = array(						
                            "class_id"=>$result['a']['class_id'],
                            "class_name"=>$result['a']['class_name'],
                            "student_count"=>$result['a']['student_count'],
                            "teacher_class_id"=>(empty($result['a']['teacher_class_id'])) ? '-1' : $result['a']['teacher_class_id'],
                            "employee_id"=>(empty($result['a']['employee_id'])) ? '-1' : $result['a']['employee_id'],
                            "employee_name"=>(empty($result['a']['employee_name'])) ? '<span class="label label-danger">Assign</span>' : $result['a']['employee_name'], 
                            "academic_year_id"=>$result['a']['academic_year_id']
                        );
                    }
                    $response['Classroom'] = $res;
                    $response['Flag'] = 1;
                }  else {
                    $response['Classroom'] = null;
                    $response['Flag'] = 0;
                }
                echo json_encode($response);
            }
        }else{
            $this->accessDenialError('You Are Not Authorize To Perform Such Task', 2);
        }
    }
    
    //Assign Class Master / Mistress to Class Room
     public function assign_head_tutor() {
        $this->autoRender = false;
        $resultCheck = $this->Acl->check($this->group_alias, 'ClassroomsController');
        if($resultCheck){
            $TeachersClass = ClassRegistry::init('TeachersClass');
            if ($this->request->is('ajax')) {
                //when teacher_s_subjects_class_id => -1 assign new else update existing
                if($this->request->data('teac_class_id') === '-1'){
                    $TeachersClass->create();
                    $TeachersClass->data['TeachersClass']['employee_id'] = $this->request->data('emp_id');
                    $TeachersClass->data['TeachersClass']['class_id'] = $this->request->data('class_id');
                    $TeachersClass->data['TeachersClass']['academic_year_id'] = $this->request->data('acad_year_id');
                    echo ($TeachersClass->save()) ? $TeachersClass->getLastInsertId() : 0;
                }else{
                    $TeachersClass->id = $this->request->data('teac_class_id');
                    $TeachersClass->data['TeachersClass']['teacher_class_id'] = $this->request->data('teac_class_id');
                    $TeachersClass->data['TeachersClass']['employee_id'] = $this->request->data('emp_id');
                    $TeachersClass->data['TeachersClass']['class_id'] = $this->request->data('class_id');
                    $TeachersClass->data['TeachersClass']['academic_year_id'] = $this->request->data('acad_year_id');
                    echo ($TeachersClass->save()) ? $TeachersClass->id : 0;
                }
            }
         }else{
            $this->accessDenialError('You Are Not Authorize To Perform Such Task', 2);
        }
    }
    
    //Seacrh for all the students in a classlevel or classroom for a specific academic year
    public function view($encrypt_id) {
        $this->set('title_for_layout','Students Class List');
        $result = $this->Acl->check($this->group_alias, 'ClassroomsController/view');
        if($result){
            $StudentsClass = ClassRegistry::init('StudentsClass');
             //Decrypt the id sent
            $decrypt_id = $this->encryption->decode($encrypt_id);
            $class_id = explode('/', $decrypt_id)[0];
            $year = explode('/', $decrypt_id)[1];
            $results = $StudentsClass->findStudentsByClasslevelOrClass($year, null, $class_id);
            $response = array();   
            
            if($results) {   
                //All the students by classlevel or classroom
                foreach ($results as $result){
                    $res[] = array(						
                        "hashed_id"=>$this->encryption->encode($result['b']['student_id']),
                        "first_name"=>$result['b']['first_name'],
                        "student_no"=>$result['b']['student_no'],
                        "surname"=>$result['b']['surname'],
                        "other_name"=>$result['b']['other_name'],
                        "birth_date"=>$result['b']['birth_date'],
                        "gender"=>$result['b']['gender'],
                        "class_name"=>$result['c']['class_name']
                    );
                }
                $response['StudentsClass'] = $res;
                $response['Flag'] = 1;
            }  else {
                $response['StudentsClass'] = null;
                $response['Flag'] = 0;
            }
           $this->set('Students', $response);        
        }else{
            $this->accessDenialError();
        }
    }

}
