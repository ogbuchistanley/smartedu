<?php echo $this->Html->script("../app/js/jquery-ui.js", FALSE);?>
<?php echo $this->Html->script("../app/jquery/custom.student.js", FALSE);?>

    <div class="col-md-12">
        <div class="panel">
            <!-- Info Boxes -->
            <div class="row">
                <div class="col-md-12">
                    <div class="info-box  bg-info  text-white">
                        <div class="info-icon bg-info-dark">
                            <i class="fa fa-pencil fa-4x"></i>
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
                   <i class="fa fa-pencil-square"></i> Create New Student
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
                            //Creates The Form
                            echo $this->Form->create('Student', array(
                                    'action' => 'register',
                                    'class' => 'form-horizontal cascde-forms',
                                    'novalidate' => 'novalidate',
                                    'id' => 'student_form',
                                    'type' => 'file'
                                )
                            );     
                        ?>
                        <!-- Smart Wizard -->
                        <div id="wizard" class="swMain">
                            <ul>
                                <li>
                                    <a href="#step-1">
                                        <label class="stepNumber">1</label>
                                        <span class="stepDesc">
                                            <i>st</i>&nbsp;Step
                                       </span>
                                    </a>
                                </li>
                                <li>
                                    <a href="#step-2">
                                        <label class="stepNumber">2</label>
                                        <span class="stepDesc">
                                            <i>nd</i>&nbsp;Step
                                        </span>
                                    </a>
                                </li>
                                <li>
                                    <a href="#step-3">
                                        <label class="stepNumber">3</label>
                                        <span class="stepDesc">
                                            <i>rd</i>&nbsp;Step
                                        </span>                   
                                    </a>
                                </li>
                                <li>
                                    <a href="#step-4">
                                        <label class="stepNumber">4</label>
                                        <span class="stepDesc">
                                            <i>th</i>&nbsp;Step
                                        </span>                   
                                    </a>
                                </li>
                            </ul>
                                <div id="step-1">	
                                    <h2 class="StepTitle">Sponsor Details</h2>	
                                    <div class="panel">
                                        <div class="panel-body">
                                            <div class="form-group">
                                                <label for="sponsor_name" class="col-lg-2 col-md-3 control-label">Sponsor</label>
                                                <div class="col-lg-7 col-md-9">
                                                    <input type="text" class="form-control form-cascade-control input-small" name="sponsor_name" 
                                                    id="sponsor_name" placeholder="Student's Sponsor" required="required">
                                                    <input type="hidden" class="form-control form-cascade-control input-small" name="data[Student][sponsor_id]" 
                                                    id="sponsor_id" required="required">
                                                </div>
                                            </div>
                                            <div class="form-group">
                                              <label for="relationtype_id" class="col-lg-2 col-md-3 control-label">Relationship Type</label>
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
                                    <h2 class="StepTitle">Personal Details</h2>
                                  <div class="panel">
                                    <div class="panel-body">
                                          <div class="form-group">
                                              <label for="first_name" class="col-lg-2 col-md-3 control-label">First Name</label>
                                            <div class="col-lg-7 col-md-9">
                                             <input type="text" class="form-control form-cascade-control input-small"
                                             name="data[Student][first_name]" id="first_name" placeholder="Type Student's first name" required="required"/>
                                           </div>
                                         </div>
                                         <div class="form-group">
                                          <label for="surname" class="col-lg-2 col-md-3 control-label">Surname</label>
                                          <div class="col-lg-7 col-md-9">
                                           <input type="text" class="form-control form-cascade-control input-small" name="data[Student][surname]" 
                                           id="surname" placeholder="Type Student's surname" required="required"/>
                                         </div>
                                       </div>
                                       <div class="form-group">
                                        <label for="other_name" class="col-lg-2 col-md-3 control-label">Other Names</label>
                                        <div class="col-lg-7 col-md-9">
                                         <input type="text" class="form-control form-cascade-control input-small" name="data[Student][other_name]"
                                         id="other_name" placeholder="Type Student's other name if there's any">
                                       </div>
                                      </div>
                                      <div class="form-group">
                                        <label for="gender" class="col-lg-2 col-md-3 control-label">Gender</label>
                                        <div class="col-lg-7 col-md-9">
                                            <select class="form-control" id="gender" name="data[Student][gender]" required="required"/>
                                                <option value="">  (Select Student's gender)  </option>
                                                <option value="Male">Male</option>
                                                <option value="Female">Female</option>
                                             </select>
                                        </div>
                                     </div>
                                     <div class="form-group">
                                        <label for="birth_date" class="col-lg-2 col-md-3 control-label">Date of Birth</label>
                                        <div class="col-lg-7 col-md-9">
                                            <input type="text" class="form-control form-cascade-control input-small" name="data[Student][birth_date]" 
                                            id="birth_date" placeholder="Select Student's date of birth" required="required"/>
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
                                        <label for="state_id" class="col-lg-2 col-md-3 control-label">State of origin</label>
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
                                        <label for="local_govt_id" class="col-lg-2 col-md-3 control-label">Local Govt.</label>
                                        <div class="col-lg-7 col-md-9">
                                            <select class="form-control" name="data[Student][local_govt_id]" id="local_govt_id">
                                                <option value="">  (Select Student's L.G.A)  </option>

                                             </select>
                                        </div>
                                     </div>
                                    </div>
                                     <!--div class="form-group">
                                        <label for="religion" class="col-lg-2 col-md-3 control-label">Religion</label>
                                        <div class="col-lg-7 col-md-9">
                                            <select class="form-control" name="data[Student][religion]" id="religion" required="required">
                                                <option value="">  (Select Student's religion)  </option>
                                                <option value="Christian">  Christian  </option>
                                                <option value="Muslim">  Muslim  </option>
                                                <option value="Traditional">  Traditional  </option>
                                             </select>
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
                                                <option value="">  (Student's Current class)  </option>

                                            </select>
                                        </div>
                                    </div>
                                    <div class="form-group">
                                      <label for="admission_term_id" class="col-lg-2 col-md-3 control-label">Term Admitted</label>
                                      <div class="col-lg-7 col-md-9">
                                            <input type="text" class="form-control form-cascade-control input-small" name="data[Student][term_admitted]" 
                                            id="term_admitted" placeholder="Student's Admission Term">
                                      </div>
                                    </div>
                                    <!--div class="form-group">
                                      <label class="col-lg-2 col-md-3 control-label">Previous School</label>
                                      <div class="col-lg-7 col-md-9">
                                        <input type="text" class="form-control form-cascade-control input-small" name="data[Student][previous_school]" 
                                        id="previous_school" placeholder="Student's previous school">
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
                                                            <input ng-disabled="disabled" type="file" name="data[Student][image_url]" id="image_url" onChange="readURL(this);" required="required" /><br>
                                                            <img data-src="holder.js/140x140" class="img-rounded" id="img_prev" src="javascript:void(0);" style="width: 140px; height: 140px;"/>
                                                        </span>
                                                        <div id="image_error"></div>
                                                    </div>
                                                </div><br><br>
                                                <div class="form-group">
                                                    <label for="image_url" class="col-lg-2 col-md-3 control-label">&nbsp;&nbsp;</label>
                                                    <div class="col-lg-7 col-md-9">
                                                        <button type="submit" id="register_stud_btn" class="btn btn-info">Register Student</button>
                                                    </div>
                                                </div> 
                                            </center>	
                                        </div>
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
    //Set Nigeria as the defualt country //
    echo $this->Js->buffer('
        $("#country_id").val("140");
    ');
    //on click of Register New Students link... activate the link
    echo $this->Js->buffer('
        setTabActive("[href=\"'.DOMAIN_NAME.'/students/register\"]", 1);
    ');
?>                                        
<?php
//    // OnChange Of States Get Local Govt
//    $this->Utility->getDependentListBox('#state_id', '#local_govt_id', 'local_govts', 'ajax_get_local_govt', 'Student');
//    
//    // OnChange of Academic Year Get Academic Term
//    $this->Utility->getDependentListBox('#academic_year_id', '#admission_term_id', 'academic_terms', 'ajax_get_terms', 'Student');
//    
//    // OnChange Of Classlevel Get Class Room
//    $this->Utility->getDependentListBox('#classlevel_id', '#class_id', 'classrooms', 'ajax_get_classes', 'Student');
?>