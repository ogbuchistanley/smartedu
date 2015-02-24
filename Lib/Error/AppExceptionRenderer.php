<?php

App::uses('ExceptionRenderer', 'Error');

class AppExceptionRenderer extends ExceptionRenderer {

    public function beforeFilter() {
        parent::beforeFilter();
    }
    
    public function notFound($error) {
        $this->controller->beforeFilter();
        $this->controller->set('title_for_layout', 'Not Found');
        $this->controller->render('/Errors/error404');
        $this->controller->response->send();
    }
    
    public function badRequest($error) {
        $this->controller->beforeFilter();
        $this->controller->set('title_for_layout', 'Bad Request');
        $this->controller->render('/Errors/error400');
        $this->controller->response->send();
    }
    
    public function forbidden($error) {
        $this->controller->beforeFilter();
        $this->controller->set('title_for_layout', 'Forbidden Access');
        $this->controller->render('/Errors/error403');
        $this->controller->response->send();
        }
    
    public function methodNotAllowed($error) {
        $this->controller->beforeFilter();
        $this->controller->set('title_for_layout', 'Not Allowed');
        $this->controller->render('/Errors/error405');
        $this->controller->response->send();
    }
    
    public function internalError($error) {
        $this->controller->beforeFilter();
        $this->controller->set('title_for_layout', 'Internal Server Error');
        $this->controller->render('/Errors/error500');
        $this->controller->response->send();
    }
    
    public function notImplemented($error) {
        $this->controller->beforeFilter();
        $this->controller->set('title_for_layout', 'Method not implemented');
        $this->controller->render('/Errors/error501');
        $this->controller->response->send();
    }

    public function missingController($error) { $this->notFound($error); }
    
    public function missingAction($error) { $this->notFound($error); }
    
    public function missingView($error) { $this->notFound($error); }
    
    public function missingLayout($error) { $this->notFound($error); }
    
    public function missingHelper($error) { $this->notFound($error); }
    
    public function missingBehavior($error) { $this->notFound($error); }
    
    public function missingComponent($error) { $this->notFound($error); }
    
    public function missingTask($error) { $this->notFound($error); }
    
    public function missingShell($error) { $this->notFound($error); }
    
    public function missingShellMethod($error) { $this->notFound($error); }
    
    public function missingDatabase($error) { $this->notFound($error); }
    
    public function missingConnection($error) { $this->notFound($error); }
    
    public function missingTable($error) { $this->notFound($error); }
    
    public function privateAction($error) { $this->notFound($error); }
}
?>