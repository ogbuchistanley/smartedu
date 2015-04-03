<?php
App::uses('AppController', 'Controller');
/**
 * AcademicTerms Controller
 *
 * @property AcademicTerm $AcademicTerm
 * @property PaginatorComponent $Paginator
 * @property SessionComponent $Session
 */
class AssessmentsController extends AppController {

    // only allow the login controllers only
    public function beforeFilter() {
        parent::beforeFilter();
        $this->masterRedirect();
    }
    
    ////////////////////////////////////// Skills Assessment Begins /////////////////////////////////////////////////////////////////////////////////////////

    //List My Class Rooms
    public function index() {
        //$this->set('title_for_layout', 'Skills Assessment');
        $this->set('title_for_layout', 'My Class Rooms');
        $result = $this->Acl->check($this->group_alias, 'ExamsController');
        if($result){
            $Classroom = ClassRegistry::init('Classroom');
            $results = $Classroom->findHeadTutorClassrooms();
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

    //Seacrh for all the students in a classlevel or classroom for a specific academic year
    public function view($encrypt_id) {
        $this->set('title_for_layout','Students Class List');
        CakeSession::write('View_redirect', $encrypt_id);
        $result = $this->Acl->check($this->group_alias, 'ExamsController');
        if($result){
            $StudentsClass = ClassRegistry::init('StudentsClass');
            //Decrypt the id sent
            $decrypt_id = $this->encryption->decode($encrypt_id);
            $encrypt = explode('/', $decrypt_id);
            $class_id = $encrypt[0];
            $year = $encrypt[1];
            $results = $StudentsClass->findStudentsByClasslevelOrClass($year, null, $class_id);
            $response = array();

            if($results) {
                //All the students by classlevel or classroom
                foreach ($results as $result){
                    $res[] = array(
                        "hashed_id"=>$this->encryption->encode($result['b']['student_id']),
                        "student_id"=>$result['b']['student_id'],
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


    /////////////////////////////////////////////////////Remark ///////////////////////////////////////////////////////////////////////////
    //Remark for all the students in a classlevel or classroom for a specific academic term
    public function remark($encrypt_id) {
        $this->set('title_for_layout','Students Class Remark');
        $result_check = $this->Acl->check($this->group_alias, 'ExamsController');
        if($result_check){
            $StudentsClass = ClassRegistry::init('StudentsClass');
            $AcademicTerm = ClassRegistry::init('AcademicTerm');
            $RemarkModel = ClassRegistry::init('Remark');
            $count = 0;
            //Decrypt the id sent
            $decrypt_id = $this->encryption->decode($encrypt_id);
            $encrypt = explode('/', $decrypt_id);
            $class_id = $encrypt[0];
            $year = $encrypt[1];
            $results = $StudentsClass->findStudentsByClasslevelOrClass($year, null, $class_id);
            $response = array();

            if($results) {
                //Save The Record
                if ($this->request->is('post')) {
                    $data_array = $this->request->data['Remark'];
                    for ($i = 0; $i < count($data_array['remark_id']); $i++) {
                        $data = $this->request->data['Remark'];
                        //Save Record if its New Else // Update Existing Record
                        $data['remark_id'] = ($data_array['remark_id'][$i] === '') ? null : $data_array['remark_id'][$i];

                        $data['student_id'] = $data_array['student_id'][$i];
                        $data['principal_remark'] = ($data_array['principal_remark'][$i] == '') ? 'None' : $data_array['principal_remark'][$i];
                        $data['class_teacher_remark'] = ($data_array['class_teacher_remark'][$i] == '') ? 'None' : $data_array['class_teacher_remarks'][$i];
                        $data['house_master_remark'] = ($data_array['house_master_remark'][$i] == '') ? 'None' : $data_array['house_master_remark'][$i];
                        if ($RemarkModel->save($data)) {
                            $count++;
                        }
                    }

                    //Save The Master Record State Then Redirect To the next level (Class Group)
                    if ($count > 0) {
                        $this->setFlashMessage('The Students Remark Has Been Saved', 1);
                    }
                    $this->redirect(array('action' => 'index'));
                }else{
                    //All the students by classlevel or classroom
                    foreach ($results as $result){
                        $options = array('conditions' => array(
                                'Remark.student_id' => $result['b']['student_id'],
                                'Remark.academic_term_id' => $AcademicTerm->getCurrentTermID()
                            )
                        );
                        $remark = $RemarkModel->find('first', $options);
                        $res[] = array(
                            "student_id"=>$result['b']['student_id'],
                            "first_name"=>$result['b']['first_name'],
                            "student_no"=>$result['b']['student_no'],
                            "surname"=>$result['b']['surname'],
                            "other_name"=>$result['b']['other_name'],
                            "class_name"=>$result['c']['class_name'],
                            "gender"=>$result['b']['gender'],
                            "remark_id"=> (!empty($remark)) ? $remark['Remark']['remark_id'] : '',
                            "principal_remark"=> (!empty($remark)) ? $remark['Remark']['principal_remark'] : '',
                            "class_teacher_remark"=> (!empty($remark)) ? $remark['Remark']['class_teacher_remark'] : '',
                            "house_master_remark"=> (!empty($remark)) ? $remark['Remark']['house_master_remark'] : ''
                        );
                    }
                    $response['StudentsClass'] = $res;
                }
            }  else {
                $response['StudentsClass'] = null;
            }
            $this->set('Students', $response);
        }else{
            $this->accessDenialError();
        }
    }

    //Remark for all the students in a classlevel or classroom for a specific academic term
    public function saveRemark() {
        //$this->autoRender = false;
        $result = $this->Acl->check($this->group_alias, 'ExamsController');
        if($result){
            $RemarkModel = ClassRegistry::init('Remark');
            $count = 0;

            if ($this->request->is('post')) {
                $data_array = $this->request->data['Remark'];
                for ($i = 0; $i < count($data_array['remark_id']); $i++) {
                    $data = $this->request->data['Remark'];
                    //Save Record if its New Else // Update Existing Record
                    $data['remark_id'] = ($data_array['remark_id'][$i] === '') ? null : $data_array['remark_id'][$i];

                    $data['student_id'] = $data_array['student_id'][$i];
                    $data['remark'] = $data_array['remark'][$i];
                    if ($RemarkModel->save($data)) {
                        $count++;
                    }
                }

                //Save The Master Record State Then Redirect To the next level (Class Group)
                if ($count > 0) {
                    $this->setFlashMessage('The Students Remark Has Been Saved', 1);
                }
            }
            $this->redirect(array('action' => 'index'));
        }else{
            $this->accessDenialError();
        }
    }



    ///////Skills Assessment ////////////////////////
    public function assess($encrypt_id) {
        $this->set('title_for_layout', 'Skill Assessment');
        $resultCheck = $this->Acl->check($this->group_alias, 'ExamsController');
        if($resultCheck){
            //Decrypt the id sent
            $student_id = $this->encryption->decode($encrypt_id);
            $SkillModel = ClassRegistry::init('Skill');
            $SkillAssessmentModel = ClassRegistry::init('SkillAssessment');
            $studentModel = ClassRegistry::init('Student');
            $skills = $SkillModel->find('all', array('order' => array('Skill.skill')));
            $student = $studentModel->find('first', array('conditions' => array('Student.student_id' => $student_id)));

            if ($this->request->is('post')) {
                //Create New Record
                $this->Assessment->create();
                $assess['Assessment']['student_id'] = $student_id;
                if ($this->Assessment->save($assess)) {
                    $assessment_id = $this->Assessment->getLastInsertId();

                    foreach ($skills as $skill) {
                        $data = $this->request->data['Assessment'];
                        //Create New Record
                        $SkillAssessmentModel->create();
                        $data['assessment_id'] = $assessment_id;
                        $data['option'] = !empty($data[$skill['Skill']['skill_id']]) ? $data[$skill['Skill']['skill_id']] : 0;
                        $data['skill_id'] = $skill['Skill']['skill_id'];

                        $SkillAssessmentModel->save($data);
                    }
                    $this->setFlashMessage($student['Student']['first_name'] . ' ' . $student['Student']['surname'] . ' Assessment Have Been Saved.', 1);
                    return $this->redirect(array('action' => 'view/' . CakeSession::read('View_redirect')));
                }
            }
            $this->set('Skills', $skills);
            $this->set('student', $student);
        }else{
            $this->accessDenialError();
        }
    }


    public function edit($encrypt_id) {
        $this->set('title_for_layout', 'Skill Assessment');
        $resultCheck = $this->Acl->check($this->group_alias, 'ExamsController');
        if($resultCheck){
            //Decrypt the id sent
            $student_id = $this->encryption->decode($encrypt_id);
            $SkillAssessmentModel = ClassRegistry::init('SkillAssessment');
            $studentModel = ClassRegistry::init('Student');
            $TermModel = ClassRegistry::init('AcademicTerm');
            $option = array('conditions' => array('Assessment.student_id' => $student_id, 'Assessment.academic_term_id' => $TermModel->getCurrentTermID()));

            $student_assessment = $this->Assessment->find('first', $option);
            $assessment_id = $student_assessment['Assessment']['assessment_id'];
            $student = $studentModel->find('first', array('conditions' => array('Student.student_id' => $student_id)));
            $skill_assess = $SkillAssessmentModel->find('all', array('conditions' => array('SkillAssessment.assessment_id' => $assessment_id)));

            if ($this->request->is('post')) {
                $i = 0;
                foreach ($skill_assess as $skill) {
                    $data = $this->request->data['Assessment'];
                    //Update Existing Record
                    $data['skill_assessment_id'] = $data['skill_assessment_id'][$i];
                    $data['assessment_id'] = $assessment_id;
                    $data['option'] = !empty($data[$skill['SkillAssessment']['skill_assessment_id']]) ? $data[$skill['SkillAssessment']['skill_assessment_id']] : 0;
                    $data['skill_id'] = $skill['Skill']['skill_id'];

                    ($SkillAssessmentModel->save($data)) ? $i++ : null;
                }
                $this->setFlashMessage($student['Student']['first_name'] . ' ' . $student['Student']['surname'] . ' Assessment Have Been Updated.', 1);
                return $this->redirect(array('action' => 'view/' . CakeSession::read('View_redirect')));
            }
            $this->set('skill_assess', $skill_assess);
            $this->set('student', $student);
        }else{
            $this->accessDenialError();
        }
    }
    ////////////////////////////////////// Skills Assessment Ends /////////////////////////////////////////////////////////////////////////////////////////
}