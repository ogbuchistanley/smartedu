<!--icheck-->
<?php echo $this->Html->script("../app/js/icheck/icheck.js", FALSE);?>
<?php echo $this->Html->script("../app/jquery/custom.assessment.js", FALSE);?>
<?php $term_id = ClassRegistry::init('AcademicTerm'); ?>
<?php
    App::uses('Encryption', 'Utility');
    $Encryption = new Encryption();
?>

<div class="col-md-12">
    <div class="panel">
        <!-- Info Boxes -->
        <div class="row">
            <div class="col-md-12">
                <div class="info-box  bg-info  text-white">
                    <div class="info-icon bg-info-dark">
                        <i class="fa fa-4x fa-magic"></i>
                    </div>
                    <div class="info-details">
                        <h4>Skills Assessment</h4>
                    </div>
                </div>
            </div>
        </div>
        <!-- / Info Boxes -->
        <div class="panel-heading text-primary">
            <h3 class="panel-title">
               <i class="fa fa-gear"></i> Skills Assessment
                <span class="pull-right">
                    <a href="javascript:void(0)"  title="Refresh"><i class="fa fa-refresh"></i></a>
                    <a href="#" class="panel-minimize"><i class="fa fa-chevron-up"></i></a>
                    <a href="#" class="panel-close"><i class="fa fa-times"></i></a>
                </span>
            </h3>
        </div>
        <div class="panel-body">
            <div class="panel panel-default">
                <div class="panel-body">
                    <div class="row">
                        <div class="col-md-9">
                           <div class="panel">
                                <div class="panel-body">
                                    <div class="panel panel-info">
                                        <div class="panel-heading panel-title  text-white">Skills Assessment Form</div>
                                            <h4>
                                                <div class="col-lg-4 col-md-8 text-info pull-right"><label><?php echo $term_id->getCurrentTermName() ?></label></div>
                                                <div class="col-lg-4 col-md-8 text-primary"><label><?php echo $student['Student']['first_name'], ' '
                                                        , $student['Student']['surname'], ' ', $student['Student']['other_name'];?></label></div>
                                            </h4>
                                            <?php
                                                $encrypted_student_id = $Encryption->encode($student['Student']['student_id']);
                                                //Creates The Form
                                                echo $this->Form->create('Assessment', array(
                                                        'action' => 'edit/' . $encrypted_student_id,
                                                        'class' => 'form-horizontal'
                                                    )
                                                );
                                            ?>
                                                <?php if($skill_assess) :?>
                                                    <?php foreach($skill_assess as $skill) : ?>
                                                        <!--icheck icons-->
                                                        <div class="form-group">
                                                            <label for="skills1" class="col-lg-6 col-md-9 control-label"><?php echo $skill['Skill']['skill']?>: </label>
                                                            <input type="hidden"  name="data[Assessment][skill_assessment_id][]" value="<?php echo $skill['SkillAssessment']['skill_assessment_id'];?>">
                                                            <div class="col-lg-6 col-md-3">
                                                                <label class="radio-inline">
                                                                    <?php $check = ($skill['SkillAssessment']['option'] == 5) ? 'checked' : ''; ?>
                                                                    <input type="radio" class="flat-input" <?php echo $check; ?> required name="data[Assessment][<?php echo $skill['SkillAssessment']['skill_assessment_id']?>]" value="5"> 5
                                                                </label>
                                                                <label class="radio-inline">
                                                                    <?php $check = ($skill['SkillAssessment']['option'] == 4) ? 'checked' : ''; ?>
                                                                    <input type="radio" class="flat-input" <?php echo $check; ?> required name="data[Assessment][<?php echo $skill['SkillAssessment']['skill_assessment_id']?>]" value="4"> 4
                                                                </label>
                                                                <label class="radio-inline">
                                                                    <?php $check = ($skill['SkillAssessment']['option'] == 3) ? 'checked' : ''; ?>
                                                                    <input type="radio" class="flat-input" <?php echo $check; ?> required name="data[Assessment][<?php echo $skill['SkillAssessment']['skill_assessment_id']?>]" value="3"> 3
                                                                </label>
                                                                <label class="checkbox-inline">
                                                                    <?php $check = ($skill['SkillAssessment']['option'] == 2) ? 'checked' : ''; ?>
                                                                    <input type="radio" class="flat-input" <?php echo $check; ?> required name="data[Assessment][<?php echo $skill['SkillAssessment']['skill_assessment_id']?>]" value="2"> 2
                                                                </label>
                                                                <label class="checkbox-inline">
                                                                    <?php $check = ($skill['SkillAssessment']['option'] == 1) ? 'checked' : ''; ?>
                                                                    <input type="radio" class="flat-input" <?php echo $check; ?> required name="data[Assessment][<?php echo $skill['SkillAssessment']['skill_assessment_id']?>]" value="1"> 1
                                                                </label>
                                                            </div>
                                                        </div>
                                                    <?php endforeach; ?><br>
                                                    <div class="form-group">
                                                        <div class="col-sm-offset-2 col-sm-10">
                                                            <button type="submit" class="btn btn-info">Update Records</button><span></span>
                                                        </div>
                                                    </div>
                                                <?php endif; ?>
                                            </form>
                                        </div>
                                    </div>
                                </div> <!-- /panel body --> 
                           </div> <!-- /panel -->
                        </div>
                    </div>                      
                        
                </div>
            </div>
        </div>
    </div>
    
 </div> <!-- /col-md-12 -->
<?php
    //on click of Manage Sponsors Record link... activate the link
    echo $this->Js->buffer('
        setTabActive("[href=\"'.DOMAIN_NAME.'/records/class_group\"]", 1);
    ');