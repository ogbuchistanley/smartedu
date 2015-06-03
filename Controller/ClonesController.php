<?php
App::uses('AppController', 'Controller');
/**
 * Clones Controller
 *
 * @property LocalGovt $LocalGovt
 * @property PaginatorComponent $Paginator
 * @property SessionComponent $Session
 */
class ClonesController extends AppController {

    public function index() {
        $this->set('title_for_layout', 'Cloning');
        $resultCheck = $this->Acl->check($this->group_alias, 'ClonesController');
        if($resultCheck){
            $this->loadModels('Classlevel');
            $this->loadModels('AcademicYear', 'academic_year', 'DESC');
            $ExamDetail = ClassRegistry::init('ExamDetail');
            $all = $ExamDetail->find('all');
            $this->set('ExamDetails', $all);
        }else{
            $this->accessDenialError();
        }
    }

    // Validate if the academic term can clone subjects assigned to class room
    public function validateClone(){
        $this->autoRender = false;
        $resultCheck = $this->Acl->check($this->group_alias, 'ClonesController');
        if ($resultCheck) {
            $SubjectClasslevel = ClassRegistry::init('SubjectClasslevel');
            if ($this->request->is('ajax')) {
                $data = $this->request->data['CloneClass'];
                $From = $SubjectClasslevel->query('SELECT * FROM subject_classlevels WHERE academic_term_id="'. $data['academic_term_from_id'].'" LIMIT 1');
                $To = $SubjectClasslevel->query('SELECT * FROM subject_classlevels WHERE academic_term_id="'. $data['academic_term_to_id'].'" LIMIT 1');

                if(($From && !$To)){
                    echo 1;
                }else if($From && $To){
                    echo 2;
                }else{
                    echo 3;
                }
            }
        }else {
            $this->accessDenialError();
        }
    }

    public function cloning(){
        $this->layout = null;
        $resultCheck = $this->Acl->check($this->group_alias, 'ClonesController');
        if ($resultCheck) {
            $SubjectClasslevel = ClassRegistry::init('SubjectClasslevel');
            if ($this->request->is('post')) {
                $data = $this->request->data['Clones'];
                $SubjectClasslevel->proc_cloneSubjectsAssigned($data['from_term_id'], $data['to_term_id']);

                $this->setFlashMessage('Records Cloned Successfully...', 1);
                return $this->redirect(array('action' => 'index'));
            }
        }else {
            $this->accessDenialError();
        }
    }
}