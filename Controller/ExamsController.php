<?php
App::uses('AppController', 'Controller');
/**
 * AcademicTerms Controller
 *
 * @property AcademicTerm $AcademicTerm
 * @property PaginatorComponent $Paginator
 * @property SessionComponent $Session
 */
class ExamsController extends AppController {

    // only allow the login controllers only
    public function beforeFilter() {
        parent::beforeFilter();
        $this->masterRedirect();
    }
    
    public function index() {
        $this->set('title_for_layout', 'Exams');
        $resultCheck = $this->Acl->check($this->group_alias, 'ExamsController/index');
        if($resultCheck){
            $this->loadModels('Classlevel');
            $this->loadModels('AcademicYear', 'academic_year', 'DESC');
        }else{
            $this->accessDenialError();
        }
    }
    
    //Setup Exams assigned To Subjects
    public function setup_exam() {
        $this->set('title_for_layout','Exam Setup');
        $this->autoRender = false;
        $resultCheck = $this->Acl->check($this->group_alias, 'ExamsController');
        if($resultCheck){
            $subjectClasslevel = ClassRegistry::init('SubjectClasslevel');
            if ($this->request->is('ajax')) {
                $data = $this->request->data['Exam'];    
                if($data['edit_exam_id'] > 0){
                    $this->Exam->id = $data['edit_exam_id'];
                }else{
                    $this->Exam->create();
                }
                if ($this->Exam->save($data)) {
                    $ExamID = $this->Exam->id;
                    $subjectClasslevel->id = $data['subject_classlevel_id'];
                    $subjectClasslevel->saveField('examstatus_id', 1);
                    //proc_insertExams_details
                    $this->Exam->proc_insertExamDetails($ExamID);
                    echo $ExamID;
                }else {
                    echo 0;
                }
            }
        }else{
            $this->accessDenialError();
        }
    }


    //Returns all the exams that has been setup
    public function get_exam_setup() {
        $this->set('title_for_layout', 'Exams');
        $resultCheck = $this->Acl->check($this->group_alias, 'ExamsController');
        if($resultCheck){
            if ($this->request->is('ajax')) {
                $options = array('conditions' => array('Exam.' . $this->Exam->primaryKey => $this->request->data('exam_id')));
                $result = $this->Exam->find('first', $options);
                $res = array(						
                            "exam_id"=>$result['Exam']['exam_id'],
                            "class_id"=>$result['Exam']['class_id'],
                            "exam_desc"=>$result['Exam']['exam_desc'],
                            "weightageCA1"=>$result['Exam']['weightageCA1'],
                            "weightageCA2"=>$result['Exam']['weightageCA2'],
                            "weightageExam"=>$result['Exam']['weightageExam'],
                            "subject_classlevel_id"=>$result['Exam']['subject_classlevel_id']
                        );
                echo json_encode($res);
            }
        }else{
            $this->accessDenialError();
        }
    }


    //Seacrh for all the subjects assigned to a classlevel or classroom for a specific academic year
    public function search_subjects_assigned() {
        $this->autoRender = false;
        $resultCheck = $this->Acl->check($this->group_alias, 'ExamsController');
        if($resultCheck){
            if ($this->request->is('ajax')) {
                $class = ($this->request->data['SubjectClasslevel']['class_id_all'] !== '') ? $this->request->data['SubjectClasslevel']['class_id_all'] : null;
                $classlevel = $this->request->data['SubjectClasslevel']['classlevel_id_all'];
                $term_id = $this->request->data['SubjectClasslevel']['academic_term_id_all'];
                $results = $this->Exam->findSubjectsByClasslevelOrClass($term_id, $classlevel, $class);
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
                            "exam_status"=>(empty($result['c']['exam_id'])) ? '<span class="label label-danger">Exam Not Setup</span>' : '<span class="label label-success">Exam Already Setup</span>',
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
    
    //Search for subjects exams has been setup to a classlevel or classroom for modifications
    public function search_subjects_examSetup() {
        $this->autoRender = false;
        $resultCheck = $this->Acl->check($this->group_alias, 'ExamsController');
        if($resultCheck){
            if ($this->request->is('ajax')) {
                $classlevel = $this->request->data['SearchExamSetup']['classlevel_examSetup_id'];
                $term_id = $this->request->data['SearchExamSetup']['academic_term_examSetup_id'];
                $results = $this->Exam->findExamSetupSubjects($term_id, $classlevel);
                $response = array();            
                if($results) {   
                    //All the subjects by classlevel or classroom
                    foreach ($results as $result){
                        $res[] = array(						
                            "subject_name"=>$result['a']['subject_name'],
                            "class_name"=>(empty($result['a']['class_name'])) ? '<span class="label label-danger">nill</span>' : $result['a']['class_name'],
                            "class_id"=>(empty($result['a']['class_id'])) ? -1 : $result['a']['class_id'],
                            "classlevel"=>$result['a']['classlevel'],
                            "subject_classlevel_id"=>$result['a']['subject_classlevel_id'],
                            "weightageCA1"=>$result['a']['weightageCA1'],
                            "weightageCA2"=>$result['a']['weightageCA2'],
                            "weightageExam"=>$result['a']['weightageExam'],
                            "exammarked_status_id"=>$result['a']['exammarked_status_id'],
                            "exammarked_status"=>($result['a']['exammarked_status_id'] === '2') ? '<span class="label label-danger">Subject Not Marked</span>' : '<span class="label label-success">Subject Marked</span>',
                            "exam_id"=>$this->encryption->encode($result['a']['exam_id'])
                        );
                    }
                    $response['SearchExamSetup'] = $res;
                    $response['Flag'] = 1;
                } else {
                    $response['SearchExamSetup'] = null;
                    $response['Flag'] = 0;
                }
                echo json_encode($response);
            }
        }else{
            $this->accessDenialError();
        }
    }
    
    //Inputing Exam Scores in ExamDetail
    public function enter_scores($encrypt_id=NULL) {
        $this->set('title_for_layout','Exam Scores');
        $resultCheck = $this->Acl->check($this->group_alias, 'ExamsController');
        if($resultCheck){
            $ExamDetail = ClassRegistry::init('ExamDetail');
            $decrypt_id = $this->encryption->decode($encrypt_id);

            if (!$ExamDetail->exists($decrypt_id)) {
                $this->accessDenialError('Invalid Exam Record Requested for Inputing Scores', 2);
            }
            if ($this->request->is(array('post', 'put'))) {
                $data_array = $this->request->data['ExamDetail'];
                $j = 0; $val = null;
                for ($i=0; $i<count($data_array['exam_detail_id']); $i++){
                    $ExamDetail->id = explode('-', $data_array['exam_detail_id'][$i])[0];
                    $val = explode('-', $data_array['exam_detail_id'][$i])[1];
                    $data = $this->request->data['ExamDetail'];
                    $data['exam_detail_id'] = $data_array['exam_detail_id'][$i];
                    $data['ca1'] = $data_array['ca1'][$i];
                    $data['ca2'] = $data_array['ca2'][$i];
                    $data['exam'] = $data_array['exam'][$i];
                    if($ExamDetail->save($data)){   $j++;  }
                }
                if ($j > 0) {
                    $this->Exam->id = $val;
                    $this->Exam->saveField('exammarked_status_id', 1);
                    $this->setFlashMessage($j.' Student Subject Scores Has Been Saved.', 1);   
                    return $this->redirect(array('controller' => 'exams', 'action' => 'index'));
                } else {
                    $this->setFlashMessage('The Student Subject Scores could not be saved. Please, try again.', 2);
                    return $this->redirect(array('controller' => 'exams', 'action' => 'index'));
                }
            } else {
                $options = array('conditions' => array('ExamDetail.exam_id' => $decrypt_id));
                $this->set('ExamDetails', $ExamDetail->find('all', $options));
                $this->set('ExamSubject', $this->Exam->findExamSubjectView($decrypt_id));
            }  
        }else{
            $this->accessDenialError();
        }
    }
    
    //Displaying Exam Scores from ExamDetail
    public function view_scores($encrypt_id=NULL) {
        $this->set('title_for_layout','Exam Scores');
        $resultCheck = $this->Acl->check($this->group_alias, 'ExamsController');
        if($resultCheck){
            $ExamDetail = ClassRegistry::init('ExamDetail');
            $ExamModel = ClassRegistry::init('Exam');
            $decrypt_id = $this->encryption->decode($encrypt_id);

            if (!$ExamDetail->exists($decrypt_id)) {
                $this->accessDenialError('Invalid Exam Record Requested for Inputing Scores', 2);
            }
            $options = array('conditions' => array('ExamDetail.exam_id' => $decrypt_id));
            $this->set('ExamDetails', $ExamDetail->find('all', $options));    
            $this->set('ExamSubject', $ExamModel->findExamSubjectView($decrypt_id));
        }else{
            $this->accessDenialError();
        }
    }
    
    //Search for Terminal Students Exam Details
    public function search_student_classlevel() {
        $this->autoRender = false;
        $resultCheck = $this->Acl->check($this->group_alias, 'ExamsController');
        if($resultCheck){
            if ($this->request->is('ajax')) {
                $year_id = $this->request->data['SearchExamTAScores']['academic_year_examTAScores_id'];
                $term_id = $this->request->data['SearchExamTAScores']['academic_term_examTAScores_id'];
                $classlevel_id = $this->request->data['SearchExamTAScores']['classlevel_examTAScores_id'];
                $class_id = $this->request->data['SearchExamTAScores']['class_examTAScores_id'];
                $response = array();            
                if($class_id !== '') {
                    $results = $this->Exam->findStudentClasslevel($year_id, $classlevel_id, $class_id);                
                }else if ($class_id === '') {
                    $results2 = $this->Exam->findStudentClasslevel($year_id, $classlevel_id);
                }
                if(!empty($results)) {   
                    //All the students by classroom
                    foreach ($results as $result){
                        $res[] = array(						
                            "student_name"=>$result['a']['student_name'],
                            "student_no"=>$result['a']['student_no'],
                            "class_name"=>$result['a']['class_name'],
                            "class_id"=>$this->encryption->encode($result['a']['class_id']),
                            "classlevel"=>$result['a']['classlevel'],
                            "std_term_id"=>$this->encryption->encode($result['a']['student_id'].'/'.$term_id),
                            "std_cls_yr_id"=>$this->encryption->encode($result['a']['student_id'].'/'.$result['a']['class_id'].'/'.$year_id),
                            "std_cls_term_id"=>$this->encryption->encode($result['a']['student_id'].'/'.$result['a']['class_id'].'/'.$term_id),
                            "student_id"=>$this->encryption->encode($result['a']['student_id'])
                        );
                    }
                    $response['SearchExamTAScores'] = $res;
                    $response['Flag'] = 1;
                } elseif(!empty($results2)) {   
                    //All the students by classroom
                    foreach ($results2 as $result){
                        $res[] = array(						
                            "class_name"=>$result['a']['class_name'],
                            "class_size"=>$result['a']['class_size'],
                            "classlevel"=>$result['b']['classlevel'],
                            "cls_yr_id"=>$this->encryption->encode($result['a']['class_id'].'/'.$year_id),
                            "cls_term_id"=>$this->encryption->encode($result['a']['class_id'].'/'.$term_id),
                            "class_id"=>$this->encryption->encode($result['a']['class_id'])
                        );
                    }
                    $response['SearchExamTAScores'] = $res;
                    $response['Flag'] = 2;
                } else {
                    $response['SearchExamTAScores'] = null;
                    $response['Flag'] = 0;
                }
                echo json_encode($response);
            }
        }else{
            $this->accessDenialError();
        }
    }
    
    //Displaying Student Terminal Exam Scores
     public function term_scorestd($encrypt_id) {
        $this->set('title_for_layout','Terminal Student Position');
        $AssessmentModel = ClassRegistry::init('Assessment');
        $SkillAssessmentModel = ClassRegistry::init('SkillAssessment');
        $resultCheck = $this->Acl->check($this->group_alias, 'ExamsController');
        if($resultCheck){
            //Decrypt the id sent
            $decrypt_id = $this->encryption->decode($encrypt_id);
            $student_id = explode('/', $decrypt_id)[0];
            $class_id = explode('/', $decrypt_id)[1];
            $term_id = explode('/', $decrypt_id)[2];
            $skill_assess = null;

            $option = array('conditions' => array('Assessment.student_id' => $student_id, 'Assessment.academic_term_id' => $term_id));
            $student_assess = $AssessmentModel->find('first', $option);
            if($student_assess)
                $skill_assess = $SkillAssessmentModel->find('all', array('conditions' => array('SkillAssessment.assessment_id' => $student_assess['Assessment']['assessment_id'])));

            $results = $this->Exam->findStudentExamTerminalDetails($student_id, $term_id, $class_id);
            $response = array();
            $response2 = array();
           if(!empty($results[0])) {   
               //All the students by classroom
               foreach ($results[0] as $result){
                   $res[] = array(						
                       "subject_name"=>$result['a']['subject_name'],
                       "ca1"=>$result['a']['ca1'],
                       "ca2"=>$result['a']['ca2'],
                       "exam"=>$result['a']['exam'],
                       "studentSubjectTotal"=>$result['a']['studentSubjectTotal'],
                       "studentPercentTotal"=>$result['a']['studentPercentTotal'],
                       "grade"=>$result['a']['grade'],
                       "weightageCA1"=>$result['a']['weightageCA1'],
                       "weightageCA2"=>$result['a']['weightageCA2'],
                       "weightageExam"=>$result['a']['weightageExam'],
                       "weightageTotal"=>$result['a']['weightageTotal'],
                   );
               }
               $response['Scores'] = $res;
               $response['Flag'] = 1;
           } else {
               $response['Scores'] = null;
               $response['Flag'] = 0;
           }
           if(!empty($results[1])) {   
               //All the students by classroom
               foreach ($results[1] as $result){
                   $res2 = array(						
                       "full_name"=>$result['a']['full_name'],
                       "class_name"=>$result['a']['class_name'],
                       "academic_term"=>$result['a']['academic_term'],
                       "student_sum_total"=>$result['a']['student_sum_total'],
                       "exam_perfect_score"=>$result['a']['exam_perfect_score'],
                       "class_position"=>$result['a']['class_position'],
                       "clas_size"=>$result['a']['clas_size'],
                   );
               }
               $response2['ClassPositions'] = $res2;
               $response2['Flag'] = 1;
           } else {
               $response2['ClassPositions'] = null;
               $response2['Flag'] = 0;
           }
           $this->set('TermScores', $response);              
           $this->set('ClassPosition', $response2);              
           $this->set('SkillsAssess', $skill_assess);
           $this->set('encrypt_id', $encrypt_id);
        }else{
         $this->accessDenialError();
        }
    }

    //Displaying Terminal Classroom Positions
     public function term_scorecls($encrypt_id) {
         $this->set('title_for_layout','Terminal Class Position');
         $resultCheck = $this->Acl->check($this->group_alias, 'ExamsController');
        if($resultCheck){
            $decrypt_id = $this->encryption->decode($encrypt_id);
           $class_id = explode('/', $decrypt_id)[0];
           $term_id = explode('/', $decrypt_id)[1];
           $results = $this->Exam->findClassTerminalPositions($class_id, $term_id);  
           $response = array();           

           if(!empty($results)) {   
               //All the students by classroom
               foreach ($results as $result){
                   $res[] = array(						
                       "full_name"=>$result['a']['full_name'],
                       "class_name"=>$result['a']['class_name'],
                       "academic_term"=>$result['a']['academic_term'],
                       "student_sum_total"=>$result['a']['student_sum_total'],
                       "exam_perfect_score"=>$result['a']['exam_perfect_score'],
                       "class_position"=>$result['a']['class_position'],
                       "clas_size"=>$result['a']['clas_size']
                   );
               }
               $response['ScoresCLS'] = $res;
               $response['Flag'] = 1;
           } else {
               $response['ScoresCLS'] = null;
               $response['Flag'] = 0;
           }
           $this->set('TermScoresCLS', $response);              
        }else{
         $this->accessDenialError();
        }
    }
    
    //Displaying Student Annual Exam Scores
     public function annual_scorestd($encrypt_id) {
         $this->set('title_for_layout','Annual Student Subject Summary');
        $resultCheck = $this->Acl->check($this->group_alias, 'ExamsController');
        if($resultCheck){
            //Decrypt the id sent
            $decrypt_id = $this->encryption->decode($encrypt_id);
            $student_id = explode('/', $decrypt_id)[0];
            $class_id = explode('/', $decrypt_id)[1];
            $year_id = explode('/', $decrypt_id)[2];

            $AcademicTermModel = ClassRegistry::init('AcademicTerm');
            $options = array('conditions' => array('AcademicTerm.academic_year_id' => $year_id));
            $AcademicTerms = $AcademicTermModel->find('all', $options);

            $response = array();    
            $responseSub = array();    
            $responsePos = array();    
            $counts = 0;
            $re = null;
            //Terminal List of Student Subjects and their exam Scores in Details
            foreach ($AcademicTerms as $AcademicTerm) {
                $results = $this->Exam->findStudentExamAnnualDetails($student_id, $AcademicTerm['AcademicTerm']['academic_term_id'], $class_id);  
                if(!empty($results)) {   
                    $re[$counts] = $AcademicTerm['AcademicTerm']['academic_term'];
                    $res = array();
                    foreach ($results as $result){
                        $res[] = array(						
                            "subject_name"=>$result['a']['subject_name'],
                            "ca1"=>$result['a']['ca1'],
                            "ca2"=>$result['a']['ca2'],
                            "exam"=>$result['a']['exam'],
                            "studentSubjectTotal"=>$result['a']['studentSubjectTotal'],
                            "studentPercentTotal"=>$result['a']['studentPercentTotal'],
                            "grade"=>$result['a']['grade'],
                            "weightageCA1"=>$result['a']['weightageCA1'],
                            "weightageCA2"=>$result['a']['weightageCA2'],
                            "weightageExam"=>$result['a']['weightageExam'],
                            "weightageTotal"=>$result['a']['weightageTotal'],
                        );
                    }
                    $response[$counts] = $res;                
                } else {
                    $response[$counts] = null;
                }
                $counts++;
            }
            //Annual List of Students Subjects in Summary
            $resultsSub = $this->Exam->findStudentAnnualSubjectsDetails($student_id, $year_id);  
            if(!empty($resultsSub)) {   
                foreach ($resultsSub as $result){
                    $resSub[] = array(						
                        "subject_id"=>$result['a']['subject_id'],
                        "subject_name"=>$result['a']['subject_name'],
                        "first_term"=>$result['a']['first_term'],
                        "second_term"=>$result['a']['second_term'],
                        "third_term"=>$result['a']['third_term'],
                        "annual_average"=>$result['a']['annual_average'],
                        "annual_grade"=>$result['a']['annual_grade']                        
                    );
                }
                $responseSub['ScoresSub'] = $resSub;                
            } else {
                $responseSub['ScoresSub'] = null;
            }

            //Student Annual Class Position Details
            $resultsPos = $this->Exam->findStudentAnnualClassPositions($student_id, $class_id, $year_id);
            if(!empty($resultsPos)) {   
                foreach ($resultsPos as $result){
                    $resPos[] = array(						
                        "full_name"=>$result['a']['full_name'],
                        "class_annual_position"=>$result['a']['class_annual_position'],
                        "clas_size"=>$result['a']['clas_size'],
                        "class_name"=>$result['a']['class_name'],
                        "student_annual_total_score"=>$result['a']['student_annual_total_score'],
                        "exam_annual_perfect_score"=>$result['a']['exam_annual_perfect_score'],
                        "academic_year"=>$result['a']['academic_year']                        
                    );
                }
                $responsePos['ClassPos'] = $resPos;                
            } else {
                $responsePos['ClassPos'] = null;
            }
            $response['AcademicTermName'] = $re;
            $this->set('AnnualScoresArray', $response);              
            $this->set('AnnualSubArray', $responseSub);              
            $this->set('AnnualPositionArray', $responsePos);              
        }else{
         $this->accessDenialError();
        }
    }
    
    //Displaying Annual Classroom Positions
     public function annual_scorecls($encrypt_id) {
        $this->set('title_for_layout','Annual Class Position');
        $resultCheck = $this->Acl->check($this->group_alias, 'ExamsController');
        if($resultCheck){
            $decrypt_id = $this->encryption->decode($encrypt_id);
            $class_id = explode('/', $decrypt_id)[0];
            $year_id = explode('/', $decrypt_id)[1];
            $results = $this->Exam->findClassAnnuallPositions($class_id, $year_id);  
            $response = array();  

            if(!empty($results)) {   
                //All the students by classroom
                foreach ($results as $result){
                    $res[] = array(						
                        "full_name"=>$result['a']['full_name'],
                        "class_annual_position"=>$result['a']['class_annual_position'],
                        "clas_size"=>$result['a']['clas_size'],
                        "class_name"=>$result['a']['class_name'],
                        "student_annual_total_score"=>$result['a']['student_annual_total_score'],
                        "exam_annual_perfect_score"=>$result['a']['exam_annual_perfect_score'],
                        "academic_year"=>$result['a']['academic_year']          
                    );
                }
                $response['ScoresPos'] = $res;
                $response['Flag'] = 1;
            } else {
                $response['ScoresPos'] = null;
                $response['Flag'] = 0;
            }
            $this->set('AnnualCLSPos', $response);              
        }else{
         $this->accessDenialError();
        }
    }

    //Printing of Student Terminal Result Sheet
    public function print_result($encrypt_id) {
        $this->set('title_for_layout','Terminal Student Result');
        $this->layout = null;
        $AssessmentModel = ClassRegistry::init('Assessment');
        $SkillAssessmentModel = ClassRegistry::init('SkillAssessment');
//        $resultCheck = $this->Acl->check($this->group_alias, 'ExamsController');
//        if($resultCheck){
            //Decrypt the id sent
            $decrypt_id = $this->encryption->decode($encrypt_id);
            $student_id = explode('/', $decrypt_id)[0];
            $class_id = explode('/', $decrypt_id)[1];
            $term_id = explode('/', $decrypt_id)[2];

            $option = array('conditions' => array('Assessment.student_id' => $student_id, 'Assessment.academic_term_id' => $term_id));
            $student_assess = $AssessmentModel->find('first', $option);
            $skill_assess = $SkillAssessmentModel->find('all', array('conditions' => array('SkillAssessment.assessment_id' => $student_assess['Assessment']['assessment_id'])));

            $results = $this->Exam->findStudentExamTerminalDetails($student_id, $term_id, $class_id);
            $response = array();
            $response2 = array();
            if(!empty($results[0])) {
                $average = 0; $count = 0;
                //All the students by classroom
                foreach ($results[0] as $result){
                    $res[] = array(
                        "subject_name"=>$result['a']['subject_name'],
                        "ca1"=>$result['a']['ca1'],
                        "ca2"=>$result['a']['ca2'],
                        "exam"=>$result['a']['exam'],
                        "studentSubjectTotal"=>$result['a']['studentSubjectTotal'],
                        "studentPercentTotal"=>$result['a']['studentPercentTotal'],
                        "grade"=>$result['a']['grade'],
                        "grade_abbr"=>$result['a']['grade_abbr'],
                        "weightageCA1"=>$result['a']['weightageCA1'],
                        "weightageCA2"=>$result['a']['weightageCA2'],
                        "weightageExam"=>$result['a']['weightageExam'],
                        "weightageTotal"=>$result['a']['weightageTotal'],
                    );
                    $count++;
                    $average += $result['a']['studentSubjectTotal'];
                }
                $response['Average'] = $average / $count;
                $response['Scores'] = $res;
                $response['Flag'] = 1;
            } else {
                $response['Average'] = 0;
                $response['Scores'] = null;
                $response['Flag'] = 0;
            }
            if(!empty($results[1])) {
                //All the students by classroom
                foreach ($results[1] as $result){
                    $res2 = array(
                        "full_name"=>$result['a']['full_name'],
                        "class_name"=>$result['a']['class_name'],
                        "academic_term"=>$result['a']['academic_term'],
                        "student_sum_total"=>$result['a']['student_sum_total'],
                        "exam_perfect_score"=>$result['a']['exam_perfect_score'],
                        "class_position"=>$result['a']['class_position'],
                        "clas_size"=>$result['a']['clas_size'],
                    );
                }
                $response2['ClassPositions'] = $res2;
                $response2['Flag'] = 1;
            } else {
                $response2['ClassPositions'] = null;
                $response2['Flag'] = 0;
            }

            $this->set('TermScores', $response);
            $this->set('ClassPosition', $response2);
            $this->set('SkillsAssess', $skill_assess);
            $this->set('encrypt_id', $encrypt_id);
//        }else{
//            $this->accessDenialError();
//        }
    }
}