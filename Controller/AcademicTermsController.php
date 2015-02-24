<?php
App::uses('AppController', 'Controller');
/**
 * AcademicTerms Controller
 *
 * @property AcademicTerm $AcademicTerm
 * @property PaginatorComponent $Paginator
 * @property SessionComponent $Session
 */
class AcademicTermsController extends AppController {

    public function ajax_get_terms($model, $parentLB) {
        $parentLB = str_replace('#', '', $parentLB);
        $id = $this->request->data[$model][$parentLB];
        $academic_terms = $this->AcademicTerm->find('list', array(
			'conditions' => array('AcademicTerm.academic_year_id' => $id),
			'recursive' => -1
			));
        $this->set('academic_terms', $academic_terms);
		$this->layout = 'ajax';
    }
}

