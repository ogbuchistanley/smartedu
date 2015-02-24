<?php
App::uses('AppModel', 'Model');

class MessageRecipient extends AppModel {

    public $primaryKey = 'message_recipient_id';
    
    
    public $validate = array(
        'recipient_name' => array(
            'notEmpty' => array(
                'rule' => array('notEmpty'),
                'message' => 'A Recipient Name is required',                
            )
        ),
        'mobile_number' => array(
            'notEmpty' => array(
                'rule' => array('notEmpty'),
                'message' => 'A Mobile Number is required',                
            ),
            'numeric' => array(
                'rule' => array('numeric'),
                'message' => 'A Valid Mobile Number is required',                
            )
        )
    );

    
}
