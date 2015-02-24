<?php
App::uses('AppController', 'Controller');
/**
 * LocalGovts Controller
 *
 * @property LocalGovt $LocalGovt
 * @property PaginatorComponent $Paginator
 * @property SessionComponent $Session
 */
class LocalGovtsController extends AppController {

    public function ajax_get_local_govt($model, $parentLB) {
        $parentLB = str_replace('#', '', $parentLB);
        $id = $this->request->data[$model][$parentLB];
        $local_govt = $this->LocalGovt->find('list', array(
			'conditions' => array('LocalGovt.state_id' => $id),
			'recursive' => -1
			));
        $this->set('local_govt', $local_govt);
		$this->layout = 'ajax';
    }
}