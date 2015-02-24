<?php

App::uses('AppHelper', 'Helper');

class PermissionsHelper extends AppHelper {

    public $helpers = array('Session');

    function check($path){
        // assuming that allow('controllers') grands access to all actions
        if($this->Session->check('Auth.Permissions.controllers') 
        && $this->Session->read('Auth.Permissions.controllers') === true){
            return true;
        }
        if($this->Session->check('Auth.Permissions'.$path)
        && $this->Session->read('Auth.Permissions'.$path) === true){
            return true;
        }
        return false;
    }
}

?>