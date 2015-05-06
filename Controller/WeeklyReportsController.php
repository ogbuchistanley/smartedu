<?php
App::uses('AppController', 'Controller');
/**
 * WeeklyReports Controller
 *
 * @property WeeklyReports $WeeklyReports
 */
class WeeklyReportsController extends AppController {

    // only allow the login controllers only
    public function beforeFilter() {
        parent::beforeFilter();
        $this->masterRedirect();
    }
    
    public function index() {
        $this->set('title_for_layout', 'Weekly Reports');
        $resultCheck = $this->Acl->check($this->group_alias, 'ExamsController');
        if($resultCheck){
            $this->loadModels('Classlevel');
            $this->loadModels('AcademicYear', 'academic_year', 'DESC');
        }else{
            $this->accessDenialError();
        }
    }

    //Displays Weekly Details Report Setup for Subjects
    public function report($encrypt_id) {
        $this->set('title_for_layout','Weekly Reports');
        $resultCheck = $this->Acl->check($this->group_alias, 'ExamsController');
        if($resultCheck){
            $SubjectClasslevel = ClassRegistry::init('SubjectClasslevel');
            $Classroom = ClassRegistry::init('Classroom');
            $subject_classlevel_id = $this->encryption->decode($encrypt_id);

            $result = $SubjectClasslevel->find('first', array('conditions' => array('SubjectClasslevel.subject_classlevel_id' => $subject_classlevel_id)));
            $class_id = $result['SubjectClasslevel']['class_id'];
            $term_id = $result['SubjectClasslevel']['academic_term_id'];
            $classgroup_id = $Classroom->getClassgroupID($class_id);

            $results = $this->WeeklyReport->getWeeklyDetailReportSetup($subject_classlevel_id, $classgroup_id, $term_id);
            $this->set('results', $results);
            $this->set('subject_classlevel', $result);
        }else{
            $this->accessDenialError();
        }
    }

    //Displays Weekly Report for inputting Subjects scores
    public function scores($encrypt_id) {
        $this->set('title_for_layout','Weekly Report Scores');
        $resultCheck = $this->Acl->check($this->group_alias, 'ExamsController');
        if($resultCheck){
            $SubjectClasslevel = ClassRegistry::init('SubjectClasslevel');
            $WeeklyDetailSetup = ClassRegistry::init('WeeklyDetailSetup');
            $WeeklyReportDetail = ClassRegistry::init('WeeklyReportDetail');
            //Decrypt the id sent
            $decrypt_id = $this->encryption->decode($encrypt_id);
            $encrypt = explode('/', $decrypt_id);
            $weekly_detail_setup_id = $encrypt[0];
            $subject_classlevel_id = $encrypt[1];
            $option = array('conditions' => array('WeeklyReport.subject_classlevel_id' => $subject_classlevel_id, 'WeeklyReport.weekly_detail_setup_id' => $weekly_detail_setup_id, ));

            $detail_setup = $WeeklyDetailSetup->find('first', array('conditions' => array('WeeklyDetailSetup.weekly_detail_setup_id' => $weekly_detail_setup_id, )));
            $WR = $this->WeeklyReport->find('first', $option);

            if(empty($WR)){
                //Insert
                $this->WeeklyReport->create();
                $data['subject_classlevel_id'] = $subject_classlevel_id;
                $data['weekly_detail_setup_id'] = $weekly_detail_setup_id;
                if($this->WeeklyReport->save($data)){
                    $WR_id = $this->WeeklyReport->getLastInsertId();
                    $this->WeeklyReport->proc_insertWeeklyReportDetail($WR_id);
                }
            }else{
                //Update
                $WR_id = $WR['WeeklyReport']['weekly_report_id'];
                $this->WeeklyReport->proc_insertWeeklyReportDetail($WR_id);
            }

            $report_detail = $WeeklyReportDetail->find('all', array('conditions' => array('WeeklyReportDetail.weekly_report_id' => $WR_id), 'order' => 'Student.first_name'));
            $result = $SubjectClasslevel->find('first', array('conditions' => array('SubjectClasslevel.subject_classlevel_id' => $subject_classlevel_id)));

            $this->set('WeeklyDS', $detail_setup);
            $this->set('WeeklyRDs', $report_detail);
            $this->set('subject_classlevel', $result);
        }else{
            $this->accessDenialError();
        }
    }

    //Save The Weekly Report Subjects scores
    public function save_scores($encrypt_id) {
        $resultCheck = $this->Acl->check($this->group_alias, 'ExamsController');
        if($resultCheck){
            $WeeklyReportDetail = ClassRegistry::init('WeeklyReportDetail');
            //Decrypt the id sent
            $decrypt_id = $this->encryption->decode($encrypt_id);
            $encrypt = explode('/', $decrypt_id);
            $subject_classlevel_id = $encrypt[0];
            $weekly_report_id = $encrypt[1];
            $count = 0;

            if ($this->request->is('post') and isset($this->request->data['WeeklyReport'])) {
                $data_array = $this->request->data['WeeklyReport'];

                for ($i=0; $i<count($data_array['weekly_report_detail_id']); $i++){
                    $data = $this->request->data['WeeklyReport'];
                    // Update Existing Record
                    $data['weekly_report_detail_id'] = $data_array['weekly_report_detail_id'][$i];
                    $data['weekly_ca'] = $data_array['weekly_ca'][$i];
                    if($WeeklyReportDetail->save($data)){   $count++;  }
                }

                //Save the report status to marked Then Redirect
                if($count > 0) {
                    $this->WeeklyReport->id = $weekly_report_id;
                    $this->WeeklyReport->saveField('marked_status', 1);
                    $this->setFlashMessage('Weekly Report Subjects scores Has Been Saved', 1);
                    $this->redirect(array('action' => 'report/'.$this->encryption->encode($subject_classlevel_id)));
                }
            }
        }else{
            $this->accessDenialError();
        }
    }

    //Displays Weekly Report Subjects scores
    public function view($encrypt_id) {
        $this->set('title_for_layout','Weekly Report Scores');
        $resultCheck = $this->Acl->check($this->group_alias, 'ExamsController');
        if($resultCheck){
            $SubjectClasslevel = ClassRegistry::init('SubjectClasslevel');
            $WeeklyDetailSetup = ClassRegistry::init('WeeklyDetailSetup');
            $WeeklyReportDetail = ClassRegistry::init('WeeklyReportDetail');
            //Decrypt the id sent
            $decrypt_id = $this->encryption->decode($encrypt_id);
            $encrypt = explode('/', $decrypt_id);
            $weekly_detail_setup_id = $encrypt[0];
            $subject_classlevel_id = $encrypt[1];
            $option = array('conditions' => array('WeeklyReport.subject_classlevel_id' => $subject_classlevel_id, 'WeeklyReport.weekly_detail_setup_id' => $weekly_detail_setup_id, ));

            $WR = $this->WeeklyReport->find('first', $option);
            $WR_id = $WR['WeeklyReport']['weekly_report_id'];

            $detail_setup = $WeeklyDetailSetup->find('first', array('conditions' => array('WeeklyDetailSetup.weekly_detail_setup_id' => $weekly_detail_setup_id, )));
            $report_detail = $WeeklyReportDetail->find('all', array('conditions' => array('WeeklyReportDetail.weekly_report_id' => $WR_id), 'order' => 'Student.first_name'));
            $result = $SubjectClasslevel->find('first', array('conditions' => array('SubjectClasslevel.subject_classlevel_id' => $subject_classlevel_id)));

            $this->set('WeeklyDS', $detail_setup);
            $this->set('WeeklyRDs', $report_detail);
            $this->set('subject_classlevel', $result);
        }else{
            $this->accessDenialError();
        }
    }

    //Send Subject Reports scores to Parents
    public function send() {
        $WeeklyReports = $this->WeeklyReport->getWeeklyReportDetails();
        foreach($WeeklyReports as $WeeklyRD) {
            $students = $this->WeeklyReport->query('SELECT a.* FROM weeklyreport_studentdetailsviews a WHERE submission_date=CURDATE() - INTERVAL 1 DAY AND
            a.student_id="' . $WeeklyRD['a']['student_id'] . '" AND a.marked_status=1 ORDER BY a.student_id');
            $email = $WeeklyRD['a']['email'];
            $mobile_no = $WeeklyRD['a']['mobile_number1'];
            $sms = $msg = $mail = $body ='';

            foreach ($students as $student) {
                $msg = $student['a']['student_name'] . ', ' . $student['a']['class_name'] . ', ' . $this->WeeklyReport->formatPosition($student['a']['weekly_report_no'])
                    . ' C.A for ' . $student['a']['academic_term'];
                $sms .= $student['a']['subject_name'] . '= ' . $student['a']['weekly_ca'] . '/' . $student['a']['weekly_weight_point'] . ', ';
                $mail .= $student['a']['subject_name'] . '= ' . $student['a']['weekly_ca'] . '/' . $student['a']['weekly_weight_point'] . '<br>';
            }
            if (!empty($mobile_no)) {
                $body = $msg . ':: ' . $sms;
                //Send SMS
                //$this->WeeklyReport->SendSMS($mobile_no, $body, 'SmartEdu');
            }
            if (!empty($email)) {
                //Send Email
                $body = $msg . '<br><br>' . $mail;
                //$this->WeeklyReport->sendMail($body, $msg, $email, $WeeklyRD['a']['sponsor_name']);
            }

            // Update Notification Status
            $this->WeeklyReport->id = $WeeklyRD['a']['weekly_report_id'];
            $this->WeeklyReport->saveField('notification_status', 1);
        }
        $this->set('WeeklyReports', $WeeklyReports);
    }
}