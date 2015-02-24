<?php
App::uses('AppModel', 'Model');

class ItemBill extends AppModel {

    public $primaryKey = 'item_bill_id';

    public $belongsTo = array(
        'Item' => array(
            'className' => 'Item',
            'foreignKey' => 'item_id',
            'conditions' => '',
            'fields' => '',
            'order' => ''
        ),
        'Classlevel' => array(
            'className' => 'Classlevel',
            'foreignKey' => 'classlevel_id',
            'conditions' => '',
            'fields' => '',
            'order' => ''
        )
    );
}
