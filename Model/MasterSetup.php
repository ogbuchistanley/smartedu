<?php
App::uses('AppModel', 'Model');
/**
 * AcademicYear Model
 *
 */
class MasterSetup extends AppModel {

    public $primaryKey = 'master_setup_id';

    public $displayField = 'master_setup';

    public function getSchoolInfo(){
        //$EmployeeModel = ClassRegistry::init('Employee');
        $result = $this->find('first');

        return $result['MasterSetup'];
    }

}
