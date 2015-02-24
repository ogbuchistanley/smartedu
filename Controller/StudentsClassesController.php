<?php
App::uses('AppController', 'Controller');
/**
 * StudentsClasses Controller
 *
 * @property StudentsClass $StudentsClass
 * @property PaginatorComponent $Paginator
 * @property SessionComponent $Session
 */
class StudentsClassesController extends AppController {

     public function beforeFilter() {
        parent::beforeFilter();
    }
    
    //Assign students to a classroom or remove them from a classroom
    public function assign() {
        $result = $this->Acl->check($this->group_alias, 'StudentsClassesController');
        $this->autoRender = false;
        if($result){
            $term_id = ClassRegistry::init('AcademicTerm');
            $student = ClassRegistry::init('Student');
            if ($this->request->is('ajax')) {
                $student_class_id = $this->request->data('student_class_id');
                //assign
                if($student_class_id === '-1') {
                    $this->StudentsClass->create();
                    $this->StudentsClass->data['StudentsClass']['student_id'] = $this->request->data('student_id');
                    $this->StudentsClass->data['StudentsClass']['class_id'] = $this->request->data('class_id');
                    $this->StudentsClass->data['StudentsClass']['academic_year_id'] = $term_id->getCurrentYearID();
                    if($this->StudentsClass->save()) {
                        //update the class_id in the students table
                        $student->id = $this->request->data('student_id');
                        $student->saveField('class_id', $this->request->data('class_id'));
                        echo $this->StudentsClass->getLastInsertId();
                    } else echo 0;
                //remove        
                }else{
                    $this->StudentsClass->id = $this->request->data('student_class_id');
                    if($this->StudentsClass->delete()){
                        $student->id = $this->request->data('student_id');
                        $student->saveField('class_id', '');
                        echo $student_class_id;
                    }else echo 0;
                }
            }
        }else{
            $this->accessDenialError('You Are Not Allow To Perform Such Operation...', 2);
        }
    }
    //Seacrh for all the students in a classroom for a current academic year
    public function search() {
        $result = $this->Acl->check($this->group_alias, 'StudentsClassesController');
        $this->autoRender = false;
        if($result){
            if ($this->request->is('ajax')) {
                $results = $this->StudentsClass->findStudentsByClass($this->request->data['StudentsClass']['class_id']);
                $results2 = $this->StudentsClass->findStudentsWithOutClass();
                $response = array();            
                if($results) {
                    //All the students present in a class
                    foreach ($results as $result){
                        $res[] = array(						
                            "class_id"=>$result['a']['class_id'],
                            "student_id"=>$result['a']['student_id'],
                            "student_class_id"=>$result['a']['student_class_id'],
                            "academic_year_id"=>$result['a']['academic_year_id'],
                            "first_name"=>$result['b']['first_name'],
                            "student_no"=>$result['b']['student_no'],
                            "surname"=>$result['b']['surname'],
                            "other_name"=>$result['b']['other_name']
                        );
                    }
                    $response['StudentsClass'] = $res;
                    $response['Flag'] = 1;
                }  else {
                    $response['StudentsClass'] = null;
                    $response['Flag'] = 0;
                }
                if($results2) {
                    //All the students without classroom assigned to them
                    foreach ($results2 as $result){
                        $res2[] = array(						
                            "student_id"=>$result['b']['student_id'],
                            "first_name"=>$result['b']['first_name'],
                            "student_no"=>$result['b']['student_no'],
                            "surname"=>$result['b']['surname'],
                            "other_name"=>$result['b']['other_name']
                        );
                    }
                    $response['StudentsNoClass'] = $res2;
                    $response['Flag2'] = 1;
                }  else {
                    $response['StudentsNoClass'] = null;
                    $response['Flag2'] = 0;
                }
                echo json_encode($response);
            }
        }else{
            $this->accessDenialError('You Are Not Allow To Perform Such Operation...', 2);
        }
    }
    
    //Seacrh for all the students in a classlevel or classroom for a specific academic year
    public function search_all() {
        $result = $this->Acl->check($this->group_alias, 'StudentsClassesController');
        $this->autoRender = false;
        if($result){
            if ($this->request->is('ajax')) {
                $class = ($this->request->data['StudentsClassAll']['class_id_all'] !== '') ? $this->request->data['StudentsClassAll']['class_id_all'] : null;
                $classlevel = $this->request->data['StudentsClassAll']['classlevel_id_all'];
                $year = $this->request->data['StudentsClassAll']['academic_year_id'];
                $results = $this->StudentsClass->findStudentsByClasslevelOrClass($year, $classlevel, $class);
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
                echo json_encode($response);
            }
        }else{
            $this->accessDenialError();
        }
    }
}
