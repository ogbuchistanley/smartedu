<?php

App::uses('AppHelper', 'Helper');

class UtilityHelper extends AppHelper {
    
    public $helpers = array('Js');
    
    public function getDependentListBox($parent, $child, $control, $action, $model) {
        $this->Js->get($parent)->event('change', 
            $this->Js->request(array(
                'controller'=>$control,
                'action'=>$action, $model, $parent,
                ), array(
                'update'=>$child,
                'async' => true,
                'method' => 'post',
                'dataExpression'=>true,
                'data'=> $this->Js->serializeForm(array(
                    'isForm' => true,
                    'inline' => true
                ))
            ))
        );
     }
     
     public function formatDate($date) {
         if($date === null){
             return '';
         }else {
            $a = explode('-', $date); 
            return $a[1].'/'.$a[2].'/'.$a[0];
         }
     }
     
     //Format The SQL Databse Date To e.g Wenesday, 5th Novermber, 2014 
    public function SQLDateToPHP($dateString = null) {
        $date = DateTime::createFromFormat('Y-m-d', $dateString);
        return ($dateString !== null) ? $date->format('D, jS M, Y') : date('D, jS M, Y');
    }

    //Format Class Position
    public function formatPosition($position=0){
        $lastDigit = substr($position, -1, 1);
        if($lastDigit == 1) {
            $fomatedPosition = $position . 'st';
        }elseif($lastDigit == 2) {
            $fomatedPosition = $position . 'nd';
        }elseif($lastDigit == 3) {
            $fomatedPosition = $position . 'rd';
        }else{
            $fomatedPosition = $position . 'th';
        }
        return $fomatedPosition;
    }
}
