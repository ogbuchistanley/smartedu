<?php
App::uses('AppModel', 'Model');
/**
 * SkillAssessment Model
 *
 */
class SkillAssessment extends AppModel {
    
    public $primaryKey = 'skill_assessment_id';
    
    public $belongsTo = array(
		'Skill' => array(
			'className' => 'Skill',
			'foreignKey' => 'skill_id',
			'conditions' => '',
			'fields' => '',
			'order' => ''
		),
        'Assessment' => array(
            'className' => 'Assessment',
            'foreignKey' => 'assessment_id',
            'conditions' => '',
            'fields' => '',
            'order' => ''
        )
	);
    

}