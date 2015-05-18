<?php
App::uses('AppController', 'Controller');

class RecordsController extends AppController {

    private $MasterSetupModel;

    // only allow the login controllers only
    public function beforeFilter() {
        parent::beforeFilter();
        $this->MasterSetupModel = ClassRegistry::init('MasterSetup');
    }

    //Delete ID's that are checked
    function deleteIDs($delete_terms_id, $Classgroup) {
        if($delete_terms_id !== null) {
            for ($j=0; $j<count($delete_terms_id); $j++){
                $Classgroup->id = $delete_terms_id[$j];
                $Classgroup->delete();
            }
        }
    }
    
    /////////Academic Years Master Record  //////////////////////  1st Step //////////////////////////////////////////////////////////////
    public function academic_year() {
        $this->set('title_for_layout', 'Academic Year Records');
        $resultCheck = $this->Acl->check($this->group_alias, 'RecordsController');
        if($resultCheck){
            $AcademicYear = ClassRegistry::init('AcademicYear');        
            $count = 0;

            if ($this->request->is('post') and isset($this->request->data['SearchAcademicYear'])) {
                $data = $this->request->data['SearchAcademicYear'];
                $options = array('conditions' => array('AcademicYear.year_status_id' => $data['year_status_id']));
                $this->set('AcademicYears', $AcademicYear->find('all', $options));

            }else if ($this->request->is('post') and isset($this->request->data['AcademicYear'])) {
                $data_array = $this->request->data['AcademicYear'];
                $delete_terms = $this->request->data['AcademicYear']['deleted_term'];
                $delete_terms_id = (!empty($delete_terms)) ? explode(',', $delete_terms) : null;
                for ($i=0; $i<count($data_array['academic_year_id']); $i++){
                    $data = $this->request->data['AcademicYear'];
                    //Save Record if its New Else // Update Existing Record
                    $data['academic_year_id'] = ($data_array['academic_year_id'][$i] === '') ? null : $data_array['academic_year_id'][$i];

                    $data['academic_year'] = $data_array['academic_year'][$i];
                    $data['year_status_id'] = $data_array['year_status_id'][$i];
                    if($AcademicYear->save($data)){   $count++;  }
                }

                //Delete The ID's Checked
                $this->deleteIDs($delete_terms_id, $AcademicYear);

                //Save The Master Record State Then Redirect To the next level (Academic Term)
                if($count > 0) {
                    $this->setFlashMessage('Academic Years Has Been Saved', 1);
                    if($this->master_record_id < $this->master_record_count) {
                        $this->MasterSetupModel->id = 1;
                        $this->MasterSetupModel->saveField('master_record_id', 1);
                        $this->redirect(array('controller' => 'records', 'action' => 'index'));
                    }else{
                        $this->set('AcademicYears', $AcademicYear->find('all'));
                    }
                }
            }else{
                $this->set('AcademicYears', $AcademicYear->find('all'));
            }
        }else{
            $this->accessDenialError();
        }
    }

    ////////Academic Terms Master Record ///////////// 2nd Step ////////////////////////////////////////////////////////
    public function index() {
        $this->set('title_for_layout', 'Academic Term Records');
        $resultCheck = $this->Acl->check($this->group_alias, 'RecordsController');
        if($resultCheck){
            $this->loadModels('AcademicYear', 'academic_year', 'DESC');
            $AcademicTerm = ClassRegistry::init('AcademicTerm');
            $count = 0;

            if ($this->request->is('post') and isset($this->request->data['SearchAcademicTerm'])) {
                $data = $this->request->data['SearchAcademicTerm'];
                $options = array('conditions' => array('AcademicTerm.academic_year_id' => $data['academic_year_search_id']));
                $this->set('AcademicTerms', $AcademicTerm->find('all', $options));

            }else if ($this->request->is('post') and isset($this->request->data['AcademicTerm'])) {
                $data_array = $this->request->data['AcademicTerm'];
                $delete_terms = $this->request->data['AcademicTerm']['deleted_term'];
                $delete_terms_id = (!empty($delete_terms)) ? explode(',', $delete_terms) : null;
                for ($i=0; $i<count($data_array['academic_term_id']); $i++){
                    $data = $this->request->data['AcademicTerm'];
                    //Save Record if its New Else // Update Existing Record
                    $data['academic_term_id'] = ($data_array['academic_term_id'][$i] === '') ? null : $data_array['academic_term_id'][$i];

                    $data['academic_term'] = $data_array['academic_term'][$i];
                    $data['academic_year_id'] = $data_array['academic_year_id'][$i];
                    $data['term_status_id'] = $data_array['term_status_id'][$i];
                    $data['term_type_id'] = $data_array['term_type_id'][$i];
                    $data['term_begins'] = $data_array['term_begins'][$i];
                    $data['term_ends'] = $data_array['term_ends'][$i];
                    if($AcademicTerm->save($data)){ $count++; }
                }

                //Delete The ID's Checked
                $this->deleteIDs($delete_terms_id, $AcademicTerm);

                //Save The Master Record State Then Redirect To the next level (Class Group)
                if($count > 0) {
                    $this->setFlashMessage('Academic Terms Has Been Saved', 1);
                    if($this->master_record_id < $this->master_record_count) {
                        $this->MasterSetupModel->id = 1;
                        $this->MasterSetupModel->saveField('master_record_id', 2);
                        $this->redirect(array('controller' => 'records', 'action' => 'class_group'));
                    }else{
                        $this->set('AcademicTerms', $AcademicTerm->find('all'));
                    }
                }

            }else{
                $this->set('AcademicTerms', $AcademicTerm->find('all'));
            }
        }else{
            $this->accessDenialError();
        }
    }
    
    ////////// Class Groups Master Record  ////////////////////// 3rd Step //////////////////////////////////////////////////////////////
    public function class_group() {
        $this->set('title_for_layout', 'Class Group Records');
        $resultCheck = $this->Acl->check($this->group_alias, 'RecordsController');
        if($resultCheck){
            $Classgroup = ClassRegistry::init('Classgroup');        
            $count = 0;

            if ($this->request->is('post')) {
                $data_array = $this->request->data['Classgroup'];
                $delete_terms = $this->request->data['Classgroup']['deleted_term'];
                $delete_terms_id = (!empty($delete_terms)) ? explode(',', $delete_terms) : null;
                for ($i=0; $i<count($data_array['classgroup_id']); $i++){
                    $data = $this->request->data['Classgroup'];
                    //Save Record if its New Else // Update Existing Record
                    $data['classgroup_id'] = ($data_array['classgroup_id'][$i] === '') ? null : $data_array['classgroup_id'][$i];

                    $data['classgroup'] = $data_array['classgroup'][$i];
                    $data['weightageCA1'] = $data_array['weightageCA1'][$i];
                    $data['weightageCA2'] = $data_array['weightageCA2'][$i];
                    $data['weightageExam'] = $data_array['weightageExam'][$i];
                    if($Classgroup->save($data)){   $count++;  }
                }
                //Delete The ID's Checked
                $this->deleteIDs($delete_terms_id, $Classgroup);

                //Save The Master Record State Then Redirect To the next level (Class Level)
                if($count > 0) {
                    $this->setFlashMessage('Class Group Has Been Saved', 1);
                    if($this->master_record_id < $this->master_record_count) {
                        $this->MasterSetupModel->id = 1;
                        $this->MasterSetupModel->saveField('master_record_id', 3);
                        $this->redirect(array('controller' => 'records', 'action' => 'class_level'));
                    }else{
                        $this->set('Classgroups', $Classgroup->find('all'));
                    }
                }
            }else{
                $this->set('Classgroups', $Classgroup->find('all'));
            }
        }else{
            $this->accessDenialError();
        }
    }
    
    /////// Class Levels Master Record  ////////////////////// 4th Step //////////////////////////////////////////////////////////////
    public function class_level() {
        $this->set('title_for_layout', 'Class Level Records');
        $resultCheck = $this->Acl->check($this->group_alias, 'RecordsController');
        if($resultCheck){
            $this->loadModels('Classgroup', 'classgroup');
            $Classlevel = ClassRegistry::init('Classlevel');        
            $count = 0;

            if ($this->request->is('post') and isset($this->request->data['SearchClasslevel'])) {
                $data = $this->request->data['SearchClasslevel'];
                $options = array('conditions' => array('Classlevel.classgroup_id' => $data['class_level_search_id']));
                $this->set('Classlevels', $Classlevel->find('all', $options));

            }else if ($this->request->is('post') and isset($this->request->data['Classlevel'])) {
                $data_array = $this->request->data['Classlevel'];
                $delete_terms = $this->request->data['Classlevel']['deleted_term'];
                $delete_terms_id = (!empty($delete_terms)) ? explode(',', $delete_terms) : null;
                for ($i=0; $i<count($data_array['classgroup_id']); $i++){
                    $data = $this->request->data['Classlevel'];
                    //Save Record if its New Else // Update Existing Record
                    $data['classlevel_id'] = ($data_array['classlevel_id'][$i] === '') ? null : $data_array['classlevel_id'][$i];

                    $data['classlevel'] = $data_array['classlevel'][$i];
                    $data['classgroup_id'] = $data_array['classgroup_id'][$i];
                    if($Classlevel->save($data)){   $count++;  }
                }
                //Delete The ID's Checked
                $this->deleteIDs($delete_terms_id, $Classlevel);

                //Save The Master Record State Then Redirect To the next level (Class Room)
                if($count > 0) {
                    $this->setFlashMessage('Class Level Has Been Saved', 1);
                    if($this->master_record_id < $this->master_record_count) {
                        $this->MasterSetupModel->id = 1;
                        $this->MasterSetupModel->saveField('master_record_id', 4);
                        $this->redirect(array('controller' => 'records', 'action' => 'class_room'));
                    }else{
                        $this->set('Classlevels', $Classlevel->find('all'));
                    }
                }
            }else{
                $this->set('Classlevels', $Classlevel->find('all'));
            }
        }else{
            $this->accessDenialError();
        }
    }
    
    /////// Class Rooms Master Record  //////////////////// 5th Step ////////////////////////////////////////////////////////////////
    public function class_room() {
        $this->set('title_for_layout', 'Class Room Records');
        $resultCheck = $this->Acl->check($this->group_alias, 'RecordsController');
        if($resultCheck){
            $this->loadModels('Classlevel', 'classlevel');
            $Classroom = ClassRegistry::init('Classroom');        
            $count = 0;

            if ($this->request->is('post') and isset($this->request->data['SearchClassroom'])) {
                $data = $this->request->data['SearchClassroom'];
                $options = array('conditions' => array('Classroom.classlevel_id' => $data['class_room_search_id']));
                $this->set('Classrooms', $Classroom->find('all', $options));

            }else if ($this->request->is('post') and isset($this->request->data['Classroom'])) {
                $data_array = $this->request->data['Classroom'];
                $delete_terms = $this->request->data['Classroom']['deleted_term'];
                $delete_terms_id = (!empty($delete_terms)) ? explode(',', $delete_terms) : null;
                for ($i=0; $i<count($data_array['class_id']); $i++){
                    $data = $this->request->data['Classroom'];
                    //Save Record if its New Else // Update Existing Record
                    $data['class_id'] = ($data_array['class_id'][$i] === '') ? null : $data_array['class_id'][$i];

                    $data['class_name'] = $data_array['class_name'][$i];
                    $data['classlevel_id'] = $data_array['classlevel_id'][$i];
                    $data['class_size'] = $data_array['class_size'][$i];
                    if($Classroom->save($data)){   $count++;  }
                }
                //Delete The ID's Checked
                $this->deleteIDs($delete_terms_id, $Classroom);

                //Save The Master Record State Then Redirect To the next level (Weekly Reports)
                if($count > 0) {
                    $this->setFlashMessage('Class Room Has Been Saved', 1);
                    if($this->master_record_id < $this->master_record_count) {
                        $this->MasterSetupModel->id = 1;
                        $this->MasterSetupModel->saveField('master_record_id', 5);
                        $this->redirect(array('controller' => 'records', 'action' => 'weekly_report'));
                    }else{
                        $this->set('Classrooms', $Classroom->find('all'));
                    }
                }
            }else{
                $this->set('Classrooms', $Classroom->find('all'));
            }
        }else{
            $this->accessDenialError();
        }
    }

    /////// Weekly Reports  Master Record  ////////////////////// 6th Step //////////////////////////////////////////////////////////////
    public function weekly_report() {
        $this->set('title_for_layout', 'Weekly Reports Records');
        $resultCheck = $this->Acl->check($this->group_alias, 'RecordsController');
        if($resultCheck){
            $this->loadModels('AcademicYear', 'academic_year', 'DESC');
            $this->loadModels('Classgroup', 'classgroup');
            $WeeklyReportSetup = ClassRegistry::init('WeeklyReportSetup');
            $AcademicTerm = ClassRegistry::init('AcademicTerm');
            $this->set('Terms', $AcademicTerm->find('list', array('conditions' => array('AcademicTerm.academic_year_id' => $AcademicTerm->getCurrentYearID()))));
            $count = 0;

            if ($this->request->is('post') and isset($this->request->data['SearchWeeklyReportSetup'])) {
                $data = $this->request->data['SearchWeeklyReportSetup'];
                $options = array('conditions' => array('WeeklyReportSetup.academic_term_id' => $data['academic_term_search_id']));
                $this->set('WeeklyReports', $WeeklyReportSetup->find('all', $options));

            }else if ($this->request->is('post') and isset($this->request->data['WeeklyReportSetup'])) {
                $data_array = $this->request->data['WeeklyReportSetup'];
                $delete = $this->request->data['WeeklyReportSetup']['deleted_term'];
                $delete_id = (!empty($delete)) ? explode(',', $delete) : null;
                for ($i=0; $i<count($data_array['weekly_report_setup_id']); $i++){
                    $data = $this->request->data['WeeklyReportSetup'];
                    //Save Record if its New Else // Update Existing Record
                    $data['weekly_report_setup_id'] = ($data_array['weekly_report_setup_id'][$i] === '') ? null : $data_array['weekly_report_setup_id'][$i];

                    $data['weekly_report'] = $data_array['weekly_report'][$i];
                    $data['classgroup_id'] = $data_array['classgroup_id'][$i];
                    $data['academic_term_id'] = $data_array['academic_term_id'][$i];
                    if($WeeklyReportSetup->save($data)){   $count++;  }
                }
                //Delete The ID's Checked
                $this->deleteIDs($delete_id, $WeeklyReportSetup);

                //Save The Master Record State Then Redirect To the next level (Weekly Report Details )
                if($count > 0) {
                    $this->setFlashMessage('Weekly Report Has Been Saved', 1);
                    if($this->master_record_id < $this->master_record_count) {
                        $this->MasterSetupModel->id = 1;
                        $this->MasterSetupModel->saveField('master_record_id', 6);
                        $this->redirect(array('controller' => 'records', 'action' => 'weekly_detail'));
                    }else{
                        $this->set('WeeklyReports', $WeeklyReportSetup->find('all'));
                    }
                }
            }else{
                $this->set('WeeklyReports', $WeeklyReportSetup->find('all'));
            }
        }else{
            $this->accessDenialError();
        }
    }


    /////// Weekly Report Details  Master Record  ////////////////////// 7th Step //////////////////////////////////////////////////////////////
    public function weekly_detail() {
        $this->set('title_for_layout', 'Weekly Report Details Records');
        $resultCheck = $this->Acl->check($this->group_alias, 'RecordsController');
        if($resultCheck){
            $WeeklyDetailSetup = ClassRegistry::init('WeeklyDetailSetup');
            $Classgroup = ClassRegistry::init('Classgroup');
            $count = 0;

            if ($this->request->is('post') and isset($this->request->data['WeeklyDetailSetup'])) {
                $data_array = $this->request->data['WeeklyDetailSetup'];
                $delete = $this->request->data['WeeklyDetailSetup']['deleted_term'];
                $delete_id = (!empty($delete)) ? explode(',', $delete) : null;

                for ($i=0; $i<count($data_array['weekly_detail_setup_id']); $i++){
                    $data = $this->request->data['WeeklyDetailSetup'];
                    //Save Record if its New Else // Update Existing Record
                    $data['weekly_detail_setup_id'] = ($data_array['weekly_detail_setup_id'][$i] === '') ? null : $data_array['weekly_detail_setup_id'][$i];
                    $data['weekly_report_setup_id'] = $data_array['weekly_report_setup_id'][$i];
                    $data['weekly_report_no'] = $data_array['weekly_report_no'][$i];
                    $data['weekly_weight_point'] = $data_array['weekly_weight_point'][$i];
                    $data['weekly_weight_percent'] = $data_array['weekly_weight_percent'][$i];
                    $data['submission_date'] = $data_array['submission_date'][$i];
                    $data['report_description'] = $data_array['report_description'][$i];
                    if($WeeklyDetailSetup->save($data)){   $count++;  }
                }

                //Delete The ID's Checked
                $this->deleteIDs($delete_id, $WeeklyDetailSetup);

                //Save The Master Record State Then Redirect To the next level (Subject Group)
                if($count > 0) {
                    $this->setFlashMessage('Weekly Details Report Setup Has Been Saved', 1);
                    if($this->master_record_id < $this->master_record_count) {
                        $this->MasterSetupModel->id = 1;
                        $this->MasterSetupModel->saveField('master_record_id', 7);
                        $this->redirect(array('controller' => 'records', 'action' => 'subject_group'));
                    }else{
                        $this->set('Classgroups', $Classgroup->find('all'));
                    }
                }
            }else{
                $this->set('Classgroups', $Classgroup->find('all'));
            }
        }else{
            $this->accessDenialError();
        }
    }
    
    //// Subject Groups Master Record  //////////////////////// 8th Step ////////////////////////////////////////////////////////////
    public function subject_group() {
        $this->set('title_for_layout', 'Subject Group Records');
        $resultCheck = $this->Acl->check($this->group_alias, 'RecordsController');
        if($resultCheck){
            $SubjectGroup = ClassRegistry::init('SubjectGroup');        
            $count = 0;

            if ($this->request->is('post')) {
                $data_array = $this->request->data['SubjectGroup'];
                $delete_terms = $this->request->data['SubjectGroup']['deleted_term'];
                $delete_terms_id = (!empty($delete_terms)) ? explode(',', $delete_terms) : null;
                for ($i=0; $i<count($data_array['subject_group_id']); $i++){
                    $data = $this->request->data['SubjectGroup'];
                    //Save Record if its New Else // Update Existing Record
                    $data['subject_group_id'] = ($data_array['subject_group_id'][$i] === '') ? null : $data_array['subject_group_id'][$i];

                    $data['subject_group'] = $data_array['subject_group'][$i];
                    if($SubjectGroup->save($data)){   $count++;  }
                }
                //Delete The ID's Checked
                $this->deleteIDs($delete_terms_id, $SubjectGroup);

                //Save The Master Record State Then Redirect To the next level (Subject)
                if($count > 0) {
                    $this->setFlashMessage('Subject Group Has Been Saved', 1);
                    if($this->master_record_id < $this->master_record_count) {
                        $this->MasterSetupModel->id = 1;
                        $this->MasterSetupModel->saveField('master_record_id', 8);
                        $this->redirect(array('controller' => 'records', 'action' => 'subject'));
                    }else{
                        $this->set('SubjectGroups', $SubjectGroup->find('all'));
                    }
                }
            }else{
                $this->set('SubjectGroups', $SubjectGroup->find('all'));
            }
        }else{
            $this->accessDenialError();
        }
    }
    
    //////  Subject Master Record  //////////////////////// 9th Step ////////////////////////////////////////////////////////////
    public function subject() {
        $this->set('title_for_layout', 'Subject Records');
        $resultCheck = $this->Acl->check($this->group_alias, 'RecordsController');
        if($resultCheck){
            $this->loadModels('SubjectGroup', 'subject_group');
            $Subject = ClassRegistry::init('Subject');        
            $count = 0;

            if ($this->request->is('post') and isset($this->request->data['SearchSubject'])) {
                $data = $this->request->data['SearchSubject'];
                $options = array('conditions' => array('Subject.subject_group_id' => $data['subject_group_search_id']));
                $this->set('Subjects', $Subject->find('all', $options));

            }else if ($this->request->is('post') and isset($this->request->data['Subject'])) {
                $data_array = $this->request->data['Subject'];
                $delete_terms = $this->request->data['Subject']['deleted_term'];
                $delete_terms_id = (!empty($delete_terms)) ? explode(',', $delete_terms) : null;
                for ($i=0; $i<count($data_array['subject_id']); $i++){
                    $data = $this->request->data['Subject'];
                    //Save Record if its New Else // Update Existing Record
                    $data['subject_id'] = ($data_array['subject_id'][$i] === '') ? null : $data_array['subject_id'][$i];

                    $data['subject_name'] = $data_array['subject_name'][$i];
                    $data['subject_abbr'] = $data_array['subject_abbr'][$i];
                    $data['subject_group_id'] = $data_array['subject_group_id'][$i];
                    if($Subject->save($data)){   $count++;  }
                }
                //Delete The ID's Checked
                $this->deleteIDs($delete_terms_id, $Subject);

                //Save The Master Record State Then Redirect To the next level (Grade)
                if($count > 0) {
                    $this->setFlashMessage('Subject Has Been Saved', 1);
                    if($this->master_record_id < $this->master_record_count) {
                        $this->MasterSetupModel->id = 1;
                        $this->MasterSetupModel->saveField('master_record_id', 9);
                        $this->redirect(array('controller' => 'records', 'action' => 'grade'));
                    }else{
                        $this->set('Subjects', $Subject->find('all', array('order' => 'subject_name')));
                    }
                }
            }else{
                $this->set('Subjects', $Subject->find('all', array('order' => 'subject_name')));
            }
        }else{
            $this->accessDenialError();
        }
    }

    //// Grade Groupings Master Record  //////////////////////////// 10th Step ////////////////////////////////////////////////////////
    public function grade() {
        $this->set('title_for_layout', 'Grade Records');
        $resultCheck = $this->Acl->check($this->group_alias, 'RecordsController');
        if($resultCheck){
            $this->loadModels('Classgroup', 'classgroup');
            $Grade = ClassRegistry::init('Grade');
            $count = 0;

            if ($this->request->is('post') and isset($this->request->data['SearchGrade'])) {
                $data = $this->request->data['SearchGrade'];
                $options = array('conditions' => array('Grade.classgroup_id' => $data['class_group_search_id']));
                $this->set('Grades', $Grade->find('all', $options));

            }else if ($this->request->is('post') and isset($this->request->data['Grade'])) {
                $data_array = $this->request->data['Grade'];
                $delete_terms = $this->request->data['Grade']['deleted_term'];
                $delete_terms_id = (!empty($delete_terms)) ? explode(',', $delete_terms) : null;
                for ($i=0; $i<count($data_array['grades_id']); $i++){
                    $data = $this->request->data['Grade'];
                    //Save Record if its New Else // Update Existing Record
                    $data['grades_id'] = ($data_array['grades_id'][$i] === '') ? null : $data_array['grades_id'][$i];

                    $data['grade'] = $data_array['grade'][$i];
                    $data['classgroup_id'] = $data_array['classgroup_id'][$i];
                    $data['grade_abbr'] = $data_array['grade_abbr'][$i];
                    $data['lower_bound'] = $data_array['lower_bound'][$i];
                    $data['upper_bound'] = $data_array['upper_bound'][$i];
                    if($Grade->save($data)){   $count++;  }
                }
                //Delete The ID's Checked
                $this->deleteIDs($delete_terms_id, $Grade);

                //Save The Master Record State Then Redirect To the next level (Item)
                if($count > 0) {
                    $this->setFlashMessage('Grade Has Been Saved', 1);
                    if($this->master_record_id < $this->master_record_count) {
                        $this->MasterSetupModel->id = 1;
                        $this->MasterSetupModel->saveField('master_record_id', 10);
                        //Change Your Password
                        $this->redirect(array('controller' => 'users', 'action' => 'change'));
                    }else{
                        $this->set('Grades', $Grade->find('all'));
                    }
                }
            }else{
                $this->set('Grades', $Grade->find('all'));
            }
        }else{
            $this->accessDenialError();
        }
    }
    
    ///// Items Master Record  //////////////////////// 11th Step ////////////////////////////////////////////////////////////
    public function item() {
        $this->set('title_for_layout', 'Item Records');
        $resultCheck = $this->Acl->check($this->group_alias, 'RecordsController');
        if($resultCheck){
            $this->loadModels('ItemType');
            $Item = ClassRegistry::init('Item');        
            $count = 0;

            if ($this->request->is('post')) {
                $data_array = $this->request->data['Item'];
                $delete_terms = $this->request->data['Item']['deleted_term'];
                $delete_terms_id = (!empty($delete_terms)) ? explode(',', $delete_terms) : null;
                for ($i=0; $i<count($data_array['item_id']); $i++){
                    $data = $this->request->data['Item'];
                    //Save Record if its New Else // Update Existing Record
                    $data['item_id'] = ($data_array['item_id'][$i] === '') ? null : $data_array['item_id'][$i];

                    $data['item_name'] = $data_array['item_name'][$i];
                    $data['item_type_id'] = $data_array['item_type_id'][$i];
                    $data['item_status_id'] = $data_array['item_status_id'][$i];
                    $data['item_description'] = $data_array['item_description'][$i];
                    if($Item->save($data)){   $count++;  }
                }
                //Delete The ID's Checked
                $this->deleteIDs($delete_terms_id, $Item);

                //Save The Master Record State Then Redirect To the next level (Item Bills)
                if($count > 0) {
                    $this->setFlashMessage('Items Has Been Saved', 1);
                    if($this->master_record_id < $this->master_record_count) {
                        $this->MasterSetupModel->id = 1;
                        $this->MasterSetupModel->saveField('master_record_id', 11);
                        $this->redirect(array('controller' => 'records', 'action' => 'item_bill'));
                    }else{
                        $this->set('Items', $Item->find('all'));
                    }
                }
            }else{
                $this->set('Items', $Item->find('all'));
            }
        }else{
            $this->accessDenialError();
        }
    }
    
    //// Item Bills Master Record  ///////////////////// 12th Step ///////////////////////////////////////////////////////////////
    public function item_bill() {
        $this->set('title_for_layout', 'Item Bills Records');
        $resultCheck = $this->Acl->check($this->group_alias, 'RecordsController');
        if($resultCheck){
            $this->loadModels('Item');
            $this->loadModels('Classlevel');
            $ItemBill = ClassRegistry::init('ItemBill');        
            $count = 0;

            if ($this->request->is('post') and isset($this->request->data['SearchItemBill'])) {
                $data = $this->request->data['SearchItemBill'];
                //Search Parameters
                if($data['item_search_id'] !== '' and $data['classlevel_search_id'] === ''){
                    $options = array('conditions' => array('ItemBill.item_id' => $data['item_search_id']));
                }elseif($data['classlevel_search_id'] !== '' and $data['item_search_id'] === '') {
                    $options = array('conditions' => array('ItemBill.classlevel_id' => $data['classlevel_search_id']));
                }elseif($data['classlevel_search_id'] !== '' and $data['item_search_id'] !== '') {
                    $options = array('conditions' => array(
                        'ItemBill.item_id' => $data['item_search_id'], 
                        'ItemBill.classlevel_id' => $data['classlevel_search_id'])
                    );
                }
                $this->set('ItemBills', $ItemBill->find('all', $options));

            }else if ($this->request->is('post') and isset($this->request->data['ItemBill'])) {
                $data_array = $this->request->data['ItemBill'];
                $delete_terms = $this->request->data['ItemBill']['deleted_term'];
                $delete_terms_id = (!empty($delete_terms)) ? explode(',', $delete_terms) : null;

                for ($i=0; $i<count($data_array['item_bill_id']); $i++){
                    $data = $this->request->data['ItemBill'];
                    //Save Record if its New Else // Update Existing Record
                    $data['item_bill_id'] = ($data_array['item_bill_id'][$i] === '') ? null : $data_array['item_bill_id'][$i];

                    $data['item_id'] = $data_array['item_id'][$i];
                    $data['classlevel_id'] = $data_array['classlevel_id'][$i];
                    $data['price'] = $data_array['price'][$i];
                    if($ItemBill->save($data)){   $count++;  }
                }
                //Delete The ID's Checked
                $this->deleteIDs($delete_terms_id, $ItemBill);

                //Save The Master Record State
                if($count > 0) {
                    $this->setFlashMessage('Item Bills Has Been Saved', 1);
                    if($this->master_record_id < $this->master_record_count) {
                        $this->MasterSetupModel->id = 1;
                        $this->MasterSetupModel->saveField('master_record_id', 12);
                        //$this->redirect(array('controller' => 'dashboard', 'action' => 'index'));
                    }else{
                        $this->set('ItemBills', $ItemBill->find('all'));
                    }
                }
            }else{
                $this->set('ItemBills', $ItemBill->find('all'));
            }
        }else{
            $this->accessDenialError();
        }
    }
}
?>