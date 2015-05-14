<?php echo $this->Html->script("../app/js/jquery-ui.js", FALSE);?>
<?php echo $this->Html->script("../app/jquery/custom.student.js", FALSE);?>
<?php
    App::uses('Encryption', 'Utility');
    $Encryption = new Encryption();
?>
    <div class="row">
        <?php
            $errors = $this->validationErrors['Student'];
            $flatErrors = Set::flatten($errors);
            $flatErrors2 = $flatErrors;
            $test = array();
            foreach($flatErrors as $key => $value){
                $test[] = $value;
            }
            if(!empty($test[count($test) - 1])) {
                echo '<div class="alert alert-danger">';
                echo '<ul>';
                foreach($flatErrors2 as $key => $value) {
                    echo (!empty($value)) ? '<li>'.$value.'</li>' : false;
                }
                echo '</ul>';
                echo '</div>';
            }
        ?>
    </div>

    <div class="col-md-12">
        <div class="panel">
            <!-- Info Boxes -->
            <!--div class="row">
                <div class="col-md-12">
                    <div class="info-box  bg-info  text-white">
                        <div class="info-icon bg-info-dark">
                            <i class="fa fa-edit fa-4x"></i>
                        </div>
                        <div class="info-details">
                            <h4>Please fill the form properly and modify accurately...</h4>
                        </div>
                    </div>
                </div>
            </div>
            <!-- / Info Boxes -->
            <div class="panel-heading text-primary">
                <h3 class="panel-title">
                    <i class="fa fa-pencil-square"></i> Adjust Students' Information <small class="text-danger"> <i class="fa fa-warning"></i>Note All Fields With * Need To Be Filled</small>
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
                        <?php 
                            $encrypted_student_id = $Encryption->encode($student['Student']['student_id']);
                            //Creates The Form
                            echo $this->Form->create('Student', array(
                                    'url' => '/students/adjust/'.$encrypted_student_id,
                                    'class' => 'form-horizontal cascde-forms',
                                    'novalidate' => 'novalidate',
                                    'id' => 'student_form',
                                    'type' => 'file'
                                )
                            );     
                        ?>
                        <div class="form-group">
                            <?php echo $this->Form->input('student_id'); ?>
                        </div>

                        <!--form action="<?php //echo DOMAIN_NAME ?>/students/adjust/<?php //echo base64_encode($student['Student']['student_id']);?>" class="form-horizontal cascde-forms" novalidate="novalidate" id="student_form" enctype="multipart/form-data" method="post" accept-charset="utf-8"-->
                        
                            <!-- Smart Wizard -->
                            <div id="wizard" class="swMain">
                             <ul>
                              <li><a href="#step-1">
                                <label class="stepNumber">1</label>
                                <span class="stepDesc">
                                 <i>st</i>&nbsp;Step
                               </span>
                                         </a></li>
                                         <li><a href="#step-2">
                                          <label class="stepNumber">2</label>
                                          <span class="stepDesc">
                                           <i>nd</i>&nbsp;Step
                                         </span>
                                       </a></li>
                                       <li><a href="#step-3">
                                        <label class="stepNumber">3</label>
                                        <span class="stepDesc">
                                         <i>rd</i>&nbsp;Step
                                       </span>                   
                                     </a></li>
                                     <li><a href="#step-4">
                                      <label class="stepNumber">4</label>
                                      <span class="stepDesc">
                                       <i>th</i>&nbsp;Step
                                     </span>                   
                                   </a></li>
                                 </ul>
                                 <div id="step-1">	
                                     <h2 class="StepTitle">Staff Details <small class="text-danger"> <i class="fa fa-warning"></i>Note All Fields With * Need To Be Filled</small></h2>
                                    <div class="panel">
                                        <div class="panel-body">
                                            <div class="form-group">
                                                <label for="sponsor_name" class="col-lg-2 col-md-3 control-label">Staff <small class="text-danger"> * </small></label>
                                                <div class="col-lg-7 col-md-9">
                                                    <input type="text" class="form-control form-cascade-control input-small" name="sponsor_name" 
                                                    value="<?php echo strtoupper($student['Sponsor']['first_name']), ' ', ucwords($student['Sponsor']['other_name']);?>" id="sponsor_name" placeholder="Student's Staff" required="required">
                                                    <input type="hidden" class="form-control form-cascade-control input-small" name="data[Student][sponsor_id]" 
                                                    value="<?php echo $student['Student']['sponsor_id']?>" id="sponsor_id" required="required">
                                                </div>
                                            </div>
                                            <div class="form-group">
                                              <label for="relationtype_id" class="col-lg-2 col-md-3 control-label">Relationship Type <small class="text-danger"> * </small></label>
                                              <div class="col-lg-7 col-md-9">
                                                  <?php 
                                                        echo $this->Form->input('relationtype_id', array(
                                                                'div' => false,
                                                                'label' => false,
                                                                'class' => 'form-control',
                                                                'id' => 'relationtype_id',
                                                                'options' => $RelationshipTypes,
                                                                'empty' => '(Select Relationship Type)'
                                                            )
                                                        ); 
                                                    ?>
                                              </div>
                                            </div> 
                                        </div>
                                    </div>  		
                                </div>             
                                <div id="step-2">
                                    <h2 class="StepTitle">Personal Details <small class="text-danger"> <i class="fa fa-warning"></i>Note All Fields With * Need To Be Filled</small></h2>
                                  <div class="panel">
                                    <div class="panel-body">
                                          <div class="form-group">
                                              <label for="first_name" class="col-lg-2 col-md-3 control-label">First Name <small class="text-danger"> * </small></label>
                                            <div class="col-lg-7 col-md-9">
                                             <input type="text" class="form-control form-cascade-control input-small" value="<?php echo $student['Student']['first_name']?>"
                                             name="data[Student][first_name]" id="first_name" placeholder="Type Student's first name" required="required"/>
                                           </div>
                                         </div>
                                         <div class="form-group">
                                          <label for="surname" class="col-lg-2 col-md-3 control-label">Surname <small class="text-danger"> * </small></label>
                                          <div class="col-lg-7 col-md-9">
                                           <input type="text" class="form-control form-cascade-control input-small" name="data[Student][surname]" 
                                           value="<?php echo $student['Student']['surname']?>" id="surname" placeholder="Type Student's Surname" required="required"/>
                                         </div>
                                       </div>
                                       <div class="form-group">
                                        <label for="other_name" class="col-lg-2 col-md-3 control-label">Other Name</label>
                                        <div class="col-lg-7 col-md-9">
                                         <input type="text" class="form-control form-cascade-control input-small" name="data[Student][other_name]"
                                                value="<?php echo isset($student['Student']['other_name']) ? $student['Student']['other_name'] : '';?>" id="other_name" placeholder="Type Student's Other Names if there's any">
                                       </div>
                                      </div>
                                      <div class="form-group">
                                        <label for="gender" class="col-lg-2 col-md-3 control-label">Gender <small class="text-danger"> * </small></label>
                                        <div class="col-lg-7 col-md-9">
                                            <?php 
                                                echo $this->Form->input('gender', array(
                                                            'div' => false,
                                                            'label' => false,
                                                            'class' => 'form-control form-cascade-control input-small',
                                                            'id' => 'gender',
                                                            'options' => array('Male' => 'Male', 'Female' => 'Female'),
                                                            'empty' => '(Select Student\'s gender)'
                                                        )
                                                    );  
                                            ?>
                                        </div>
                                     </div>
                                     <div class="form-group">
                                        <label for="birth_date" class="col-lg-2 col-md-3 control-label">Date of Birth</label>
                                        <div class="col-lg-7 col-md-9">
                                            <?php
                                                $dob = '';
                                                if(!empty($student['Student']['birth_date'])) {
                                                    $a = explode('-', $student['Student']['birth_date']);
                                                    $dob = $a[2].'/'.$a[1].'/'.$a[0];
                                                }
                                            ?>
                                            <input type="text" class="form-control form-cascade-control input-small" name="data[Student][birth_date]" 
                                            value="<?php echo $dob; ?>" id="birth_date" placeholder="Select Student's date of birth"/>
                                        </div>
                                     </div>
                                     <div class="form-group">
                                        <label for="country_id" class="col-lg-2 col-md-3 control-label">Nationality</label>
                                        <div class="col-lg-7 col-md-9">
                                            <?php 
                                                echo $this->Form->input('country_id', array(
                                                        'div' => false,
                                                        'label' => false,
                                                        'class' => 'form-control',
                                                        'id' => 'country_id',
                                                        'required' => 'required',
                                                        'options' => $Countrys,
                                                        'empty' => '(Select Student\'s Country)'
                                                    )
                                                ); 
                                            ?>
                                        </div>
                                     </div>
                                    <div id="state_lga_div">
                                     <div class="form-group">
                                        <label for="state_id" class="col-lg-2 col-md-3 control-label">State of origin <small class="text-danger"> * </small></label>
                                        <div class="col-lg-7 col-md-9">
                                            <?php 
                                                echo $this->Form->input('state_id', array(
                                                        'div' => false,
                                                        'label' => false,
                                                        'class' => 'form-control',
                                                        'id' => 'state_id',
                                                        'options' => $States,
                                                        'empty' => '(Select Student\'s State)'
                                                    )
                                                ); 
                                            ?>
                                        </div>
                                     </div>
                                     <div class="form-group">
                                        <label for="local_govt_id" class="col-lg-2 col-md-3 control-label">Local Govt. <small class="text-danger"> * </small></label>
                                        <div class="col-lg-7 col-md-9">
                                            <select class="form-control" name="data[Student][local_govt_id]" id="local_govt_id">
                                                <?php 
                                                    if(!empty($student['Student']['local_govt_id'])) { 
                                                        echo '<option value="'.$student['Student']['local_govt_id'].'">'.$student['LocalGovt']['local_govt_name'].'</option>';
                                                    } else { ?>
                                                        <option value="">  (Select Student's L.G.A)  </option>
                                                <?php } ?>
                                             </select>
                                        </div>
                                     </div>
                                    </div>
                                     <!--div class="form-group">
                                        <label for="religion" class="col-lg-2 col-md-3 control-label">Religion</label>
                                        <div class="col-lg-7 col-md-9">
                                            <?php 
//                                                echo $this->Form->input('religion', array(
//                                                            'div' => false,
//                                                            'label' => false,
//                                                            'class' => 'form-control form-cascade-control input-small',
//                                                            'id' => 'religion',
//                                                            'options' => array('Christian' => 'Christian', 'Muslim' => 'Muslim', 'Traditional' => 'Traditional'),
//                                                            'empty' => '(Select Student\'s religion)'
//                                                        )
//                                                    );  
                                            ?>
                                        </div>
                                     </div-->
                                    </div>
                                  </div>                 
                                </div>
                                <div id="step-3">
                                  <h2 class="StepTitle">Educational Details</h2><br>
                                  <div class="form-group">
                                        <label for="classlevel_id" class="col-lg-2 col-md-3 control-label">Class Level</label>
                                        <div class="col-lg-7 col-md-9">
                                            <?php 
                                                echo $this->Form->input('classlevel_id', array(
                                                        'div' => false,
                                                        'label' => false,
                                                        'class' => 'form-control',
                                                        'id' => 'classlevel_id',
                                                         'required' => "required",
                                                        'options' => $Classlevels,
                                                        'empty' => '(Select Classlevel)'
                                                    )
                                                ); 
                                            ?>
                                        </div>
                                    </div>
                                    <div class="form-group">
                                        <label for="class_id" class="col-lg-2 col-md-3 control-label">Current Class</label>
                                        <div class="col-lg-7 col-md-9"">
                                            <select class="form-control" name="data[Student][class_id]" id="class_id" required="required">
                                                <?php 
                                                    if(!empty($student['Student']['class_id'])) { 
                                                        echo '<option value="'.$student['Student']['class_id'].'">'.$student['Classroom']['class_name'].'</option>';
                                                    } else { ?>
                                                        <option value="">  (Student's Current class)  </option>
                                                <?php } ?>

                                            </select>
                                        </div>
                                    </div>
                                    <!--div class="form-group">
                                      <label for="admission_term_id" class="col-lg-2 col-md-3 control-label">Term Admitted</label>
                                      <div class="col-lg-7 col-md-9">
                                          <input type="text" class="form-control form-cascade-control input-small" name="data[Student][term_admitted]" 
                                         value="<?php //echo isset($student['Student']['term_admitted']) ? $student['Student']['term_admitted'] : '';?>" id="term_admitted" placeholder="Student's Admission Term">
                                            
                                      </div>
                                    </div-->
                                    <!--div class="form-group">
                                      <label class="col-lg-2 col-md-3 control-label">Previous School</label>
                                      <div class="col-lg-7 col-md-9">
                                        <input type="text" class="form-control form-cascade-control input-small" name="data[Student][previous_school]" 
                                        value="<?php //echo isset($student['Student']['previous_school']) ? $student['Student']['previous_school'] : '';?>" id="previous_school" placeholder="Student's previous school">
                                      </div>
                                    </div-->
                                </div>
                                <div id="step-4">
                                    <h2 class="StepTitle">Upload Passport</h2>
                                    <div class="panel">	
                                        <div class="panel-body">
                                            <center>
                                                <div class="form-group">
                                                    <label for="image_url" class="col-lg-2 col-md-3 control-label">&nbsp;&nbsp;</label>
                                                    <div class="col-lg-7 col-md-9">
                                                        <span class="btn btn-info fileinput-button" ng-class="{disabled: disabled}">
                                                            <i class="glyphicon glyphicon-plus"></i>
                                                            <span>Browse File...</span>
                                                            <input value="<?php echo $student['Student']['image_url']?>" type="file" name="data[Student][image_url]" id="image_url" onChange="readURL(this);" required="required" /><br>
                                                            <img data-src="holder.js/140x140" class="img-rounded" id="img_prev" src="<?php echo DOMAIN_NAME ?>/img/uploads/<?php echo ($student['Student']['image_url']) ? $student['Student']['image_url'] : 'avatar.jpg';?>" style="width: 140px; height: 140px;"/>
                                                        </span>
                                                        <div id="image_error"></div>
                                                    </div>
                                                </div><br><br>
                                                <div class="form-group">
                                                    <label for="image_url" class="col-lg-2 col-md-3 control-label">&nbsp;&nbsp;</label>
                                                    <div class="col-lg-7 col-md-9">
                                                        <button type="submit" id="register_stud_btn" class="btn btn-info">Update Student</button>
                                                    </div>
                                                </div> 
                                            </center>		
                                        </div>
                                    </div>           			
                                </div> 
                            </div>                                    
                            <!-- End SmartWizard Content --> 
                        </form>
                    </div>
                </div>
            </div>
        </div>	
    </div>
<?php
    //on click of Edit Student Record link... activate the link
    echo $this->Js->buffer('
        setTabActive("[href=\"'.DOMAIN_NAME.'/students/\"]", 0);
    ');
?>      
<?php
    // OnChange Of States Get Local Govt
//    $this->Utility->getDependentListBox('#state_id', '#local_govt_id', 'local_govts', 'ajax_get_local_govt', 'Student');
//    
//    // OnChange of Academic Year Get Academic Term
//    $this->Utility->getDependentListBox('#academic_year_id', '#admission_term_id', 'academic_terms', 'ajax_get_terms', 'Student');
//  
//    // OnChange Of Classlevel Get Class Room
//    $this->Utility->getDependentListBox('#classlevel_id', '#class_id', 'classrooms', 'ajax_get_classes', 'Student');
?>