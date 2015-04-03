<?php
App::uses('AppController', 'Controller');

class HomeController extends AppController
{

    public $components = array('Paginator');

    // only allow the login controllers only
    public function beforeFilter() {
        parent::beforeFilter();
        $this->masterRedirect();
        //$this->layout = 'default_web';
    }

    /////////////////////////////////////// Sponsors or Students actions ///////////////////////////////////////////////
    public function index() {
        $this->set('title_for_layout', 'Students');
        $student = ClassRegistry::init('Student');
        $sponsor_id = $this->Auth->user('type_id');
        $result = $this->Acl->check($this->group_alias, 'HomeController');
        if ($result) {
            $options = array('conditions' => array('Student.sponsor_id' => $sponsor_id));
            $this->set('students', $student->find('all', $options));
        } else {
            $this->accessDenialError();
        }

    }


    public function setup()
    {

    }


    public function students()
    {
        $this->set('title_for_layout', 'Students');
        $student = ClassRegistry::init('Student');
        $sponsor_id = $this->Auth->user('type_id');
        $result = $this->Acl->check($this->group_alias, 'HomeController');
        if ($result) {
            $options = array('conditions' => array('Student.sponsor_id' => $sponsor_id));
            $this->set('students', $student->find('all', $options));
        } else {
            $this->accessDenialError();
        }
    }

    public function exam()
    {
        $this->set('title_for_layout', 'Student Record');
        $result = $this->Acl->check($this->group_alias, 'HomeController');
        if ($result) {
            $this->loadModels('AcademicYear', 'academic_year', 'DESC');
        } else {
            $this->accessDenialError();
        }
    }

    //Search for Terminal Students Exam Details
    public function search_student()
    {
        $this->autoRender = false;
        $resultCheck = $this->Acl->check($this->group_alias, 'HomeController');
        if ($resultCheck) {
            $Exam = ClassRegistry::init('Exam');
            if ($this->request->is('ajax')) {
                $year_id = $this->request->data['SearchStudent']['academic_year_id'];
                $term_id = $this->request->data['SearchStudent']['academic_term_id'];
                $response = array();
                $results = $Exam->findSponsorStudents($year_id);

                if (!empty($results)) {
                    //All the students by classroom
                    foreach ($results as $result) {
                        $res[] = array(
                            "student_name" => $result['a']['student_name'],
                            "student_no" => $result['a']['student_no'],
                            "class_name" => $result['classrooms']['class_name'],
                            "class_id" => $this->encryption->encode($result['classrooms']['class_id']),
                            "classlevel" => $result['classlevels']['classlevel'],
                            "std_term_id" => $this->encryption->encode($result['a']['student_id'] . '/' . $term_id),
                            "std_cls_yr_id" => $this->encryption->encode($result['a']['student_id'] . '/' . $result['classrooms']['class_id'] . '/' . $year_id),
                            "std_cls_term_id" => $this->encryption->encode($result['a']['student_id'] . '/' . $result['classrooms']['class_id'] . '/' . $term_id),
                            "student_id" => $this->encryption->encode($result['a']['student_id'])
                        );
                    }
                    $response['SearchStudent'] = $res;
                    $response['Flag'] = 1;
                } else {
                    $response['SearchStudent'] = null;
                    $response['Flag'] = 0;
                }
                echo json_encode($response);
            }
        } else {
            $this->accessDenialError();
        }
    }

    //Displaying Student Terminal Exam Scores
    public function term_scorestd($encrypt_id){

        $this->set('title_for_layout', 'Terminal Student Position');
        $resultCheck = $this->Acl->check($this->group_alias, 'HomeController');
        if ($resultCheck) {
            $Exam = ClassRegistry::init('Exam');
            $AssessmentModel = ClassRegistry::init('Assessment');
            $SkillAssessmentModel = ClassRegistry::init('SkillAssessment');
            //Decrypt the id sent
            $decrypt_id = $this->encryption->decode($encrypt_id);
            $encrypt = explode('/', $decrypt_id);
            $student_id = $encrypt[0];
            $class_id = $encrypt[1];
            $term_id = $encrypt[2];
            $skill_assess = null;

            $option = array('conditions' => array('Assessment.student_id' => $student_id, 'Assessment.academic_term_id' => $term_id));
            $student_assess = $AssessmentModel->find('first', $option);
            if($student_assess)
                $skill_assess = $SkillAssessmentModel->find('all', array('conditions' => array('SkillAssessment.assessment_id' => $student_assess['Assessment']['assessment_id'])));

            $results = $Exam->findStudentExamTerminalDetails($student_id, $term_id, $class_id);
            $response = array();
            $response2 = array();
            if (!empty($results[0])) {
                //All the students by classroom
                foreach ($results[0] as $result) {
                    $res[] = array(
                        "subject_name" => $result['a']['subject_name'],
                        "ca1" => $result['a']['ca1'],
                        "ca2" => $result['a']['ca2'],
                        "exam" => $result['a']['exam'],
                        "studentSubjectTotal" => $result['a']['studentSubjectTotal'],
                        "studentPercentTotal" => $result['a']['studentPercentTotal'],
                        "grade" => $result['a']['grade'],
                        "weightageCA1" => $result['a']['weightageCA1'],
                        "weightageCA2" => $result['a']['weightageCA2'],
                        "weightageExam" => $result['a']['weightageExam'],
                        "weightageTotal" => $result['a']['weightageTotal'],
                    );
                }
                $response['Scores'] = $res;
                $response['Flag'] = 1;
            } else {
                $response['Scores'] = null;
                $response['Flag'] = 0;
            }
            if (!empty($results[1])) {
                //All the students by classroom
                foreach ($results[1] as $result) {
                    $res2 = array(
                        "full_name" => $result['a']['full_name'],
                        "class_name" => $result['a']['class_name'],
                        "academic_term" => $result['a']['academic_term'],
                        "student_sum_total" => $result['a']['student_sum_total'],
                        "exam_perfect_score" => $result['a']['exam_perfect_score'],
                        "class_position" => $result['a']['class_position'],
                        "clas_size" => $result['a']['clas_size'],
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
            $this->render('/Exams/term_scorestd');
        } else {
            $this->accessDenialError();
        }
    }

    //Displaying Student Annual Exam Scores
    public function annual_scorestd($encrypt_id)
    {
        $this->set('title_for_layout', 'Annual Student Subject Summary');
        $resultCheck = $this->Acl->check($this->group_alias, 'HomeController');
        if ($resultCheck) {
            $Exam = ClassRegistry::init('Exam');
            //Decrypt the id sent
            $decrypt_id = $this->encryption->decode($encrypt_id);
            $encrypt = explode('/', $decrypt_id);
            $student_id = $encrypt[0];
            $class_id = $encrypt[1];
            $year_id = $encrypt[2];

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
                $results = $Exam->findStudentExamAnnualDetails($student_id, $AcademicTerm['AcademicTerm']['academic_term_id'], $class_id);
                if (!empty($results)) {
                    $re[$counts] = $AcademicTerm['AcademicTerm']['academic_term'];
                    $res = array();
                    foreach ($results as $result) {
                        $res[] = array(
                            "subject_name" => $result['a']['subject_name'],
                            "ca1" => $result['a']['ca1'],
                            "ca2" => $result['a']['ca2'],
                            "exam" => $result['a']['exam'],
                            "studentSubjectTotal" => $result['a']['studentSubjectTotal'],
                            "studentPercentTotal" => $result['a']['studentPercentTotal'],
                            "grade" => $result['a']['grade'],
                            "weightageCA1" => $result['a']['weightageCA1'],
                            "weightageCA2" => $result['a']['weightageCA2'],
                            "weightageExam" => $result['a']['weightageExam'],
                            "weightageTotal" => $result['a']['weightageTotal'],
                        );
                    }
                    $response[$counts] = $res;
                } else {
                    $response[$counts] = null;
                }
                $counts++;
            }
            //Annual List of Students Subjects in Summary
            $resultsSub = $Exam->findStudentAnnualSubjectsDetails($student_id, $year_id);
            if (!empty($resultsSub)) {
                foreach ($resultsSub as $result) {
                    $resSub[] = array(
                        "subject_id" => $result['a']['subject_id'],
                        "subject_name" => $result['a']['subject_name'],
                        "first_term" => $result['a']['first_term'],
                        "second_term" => $result['a']['second_term'],
                        "third_term" => $result['a']['third_term'],
                        "annual_average" => $result['a']['annual_average'],
                        "annual_grade" => $result['a']['annual_grade']
                    );
                }
                $responseSub['ScoresSub'] = $resSub;
            } else {
                $responseSub['ScoresSub'] = null;
            }

            //Student Annual Class Position Details
            $resultsPos = $Exam->findStudentAnnualClassPositions($student_id, $class_id, $year_id);
            if (!empty($resultsPos)) {
                foreach ($resultsPos as $result) {
                    $resPos[] = array(
                        "full_name" => $result['a']['full_name'],
                        "class_annual_position" => $result['a']['class_annual_position'],
                        "clas_size" => $result['a']['clas_size'],
                        "class_name" => $result['a']['class_name'],
                        "student_annual_total_score" => $result['a']['student_annual_total_score'],
                        "exam_annual_perfect_score" => $result['a']['exam_annual_perfect_score'],
                        "academic_year" => $result['a']['academic_year']
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
            $this->render('/Exams/annual_scorestd');
        } else {
            $this->accessDenialError();
        }
    }

    //Displays Students Fees Charges for an academic term
    public function view_stdfees($encrypt_id)
    {
        //Decrypt the id sent
        $resultCheck = $this->Acl->check($this->group_alias, 'HomeController');
        if ($resultCheck) {
            $Item = ClassRegistry::init('Item');
            $decrypt_id = $this->encryption->decode($encrypt_id);
            $encrypt = explode('/', $decrypt_id);
            $student_id = $encrypt[0];
            $term_id = $encrypt[1];

            $this->set('title_for_layout', 'Terminal Fees Charges');
            $results = $Item->findStudentTerminalFees($student_id, $term_id);
            $response = array();

            if (!empty($results)) {
                //All the items charges
                foreach ($results as $result) {
                    $res[] = array(
                        "student_id" => $result['a']['student_id'],
                        "student_name" => $result['a']['student_name'],
                        "student_status_id" => $result['a']['student_status_id'],
                        "student_status" => $result['a']['student_status'],
                        "sponsor_name" => $result['a']['sponsor_name'],
                        "salutation_name" => $result['a']['salutation_name'],
                        "class_name" => $result['a']['class_name'],
                        "image_url" => $result['a']['image_url'],
                        "academic_term" => $result['a']['academic_term'],
                        "item_name" => $result['a']['item_name'],
                        "order_status_id" => $result['a']['order_status_id'],
                        "price" => $result['a']['price'],
                        "subtotal" => $result['a']['subtotal']
                    );
                }
                $response['ItemBill'] = $res;
                $response['Flag'] = 1;
            } else {
                $response['ItemBill'] = null;
                $response['Flag'] = 0;
            }
            $this->set('ItemBills', $response);
        } else {
            $this->accessDenialError();
        }
    }

    //Password Change
//    public function change()
//    {
//        $this->render('/Users/change');
//        $this->set('title_for_layout', 'Password Change');
//        $User = ClassRegistry::init('User');
//        if ($this->request->is('post')) {
//            $id = $this->Auth->user('user_id');
//            $old_pass = $this->request->data['User']['old_pass'];
//            $new_pass = $this->request->data['User']['new_pass'];
//            $new_pass2 = $this->request->data['User']['new_pass2'];
//            $user = $User->find('first', array('conditions' => array('User.' . $User->primaryKey => $id)));
//            $storedHash = $user['User']['password'];
//            $newHash = Security::hash($old_pass, 'blowfish', $storedHash);
//            if ($storedHash === $newHash) {
//                if ($new_pass === $new_pass2) {
//                    $User->id = $id;
//                    if ($User->saveField('password', $new_pass2)) {
//                        $this->setFlashMessage('Password Successfully Changed', 1);
//                    }
//                } else {
//                    $this->setFlashMessage('New And Confrim Password Mismatch', 2);
//                }
//            } else {
//                $this->setFlashMessage('Old Password Mismatch', 2);
//            }
//            return $this->redirect(array('action' => 'change'));
//        }
//    }
    /////////////////////////////////////// \\\ Sponsors or Students actions ///////////////////////////////////////////////
}

?>