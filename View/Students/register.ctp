<?php echo $this->Html->script("../app/js/jquery-ui.js", FALSE);?>
<?php echo $this->Html->script("../app/jquery/custom.student.js", FALSE);?>

    <div class="row">
        <?php
            $errors = $this->validationErrors['StudentNew'];
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
                   <i class="fa fa-pencil-square"></i> Create New Student  <small class="text-danger"> <i class="fa fa-warning"></i>Note All Fields With * Need To Be Filled</small>
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
                            echo $this->Form->create('StudentNew', array(
                                    'class' => 'form-horizontal cascde-forms',
                                    'novalidate' => 'novalidate',
                                    'id' => 'student_form'
                                )
                            );
                        ?>

                            <div class="panel-body">
                                <div class="form-group">
                                    <label for="sponsor_name" class="col-lg-2 col-md-3 control-label">Parent <small class="text-danger"> * </small></label>
                                    <div class="col-lg-7 col-md-9">
                                        <input type="text" class="form-control form-cascade-control input-small" name="sponsor_name"
                                        id="sponsor_name" placeholder="Student's Parent" required="required">
                                        <input type="hidden" class="form-control form-cascade-control input-small" name="data[StudentNew][sponsor_id]"
                                        id="sponsor_id" required="required">
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
                            <div class="panel-body">
                                    <div class="form-group">
                                        <label for="first_name" class="col-lg-2 col-md-3 control-label">First Name <small class="text-danger"> * </small></label>
                                        <div class="col-lg-7 col-md-9">
                                            <input type="text" class="form-control form-cascade-control input-small"
                                            name="data[StudentNew][first_name]" id="first_name" placeholder="Type Student's first name" required="required"/>
                                       </div>
                                     </div>
                                     <div class="form-group">
                                      <label for="surname" class="col-lg-2 col-md-3 control-label">Surname <small class="text-danger"> * </small></label>
                                      <div class="col-lg-7 col-md-9">
                                       <input type="text" class="form-control form-cascade-control input-small" name="data[StudentNew][surname]"
                                       id="surname" placeholder="Type Student's Surname" required="required"/>
                                     </div>
                                   </div>
                                   <div class="form-group">
                                    <label for="other_name" class="col-lg-2 col-md-3 control-label">Other Names</label>
                                    <div class="col-lg-7 col-md-9">
                                     <input type="text" class="form-control form-cascade-control input-small" name="data[StudentNew][other_name]"
                                     id="other_name" placeholder="Type Student's Other name if there's any">
                                   </div>
                                  </div>
                                  <div class="form-group">
                                    <label for="gender" class="col-lg-2 col-md-3 control-label">Gender <small class="text-danger"> * </small></label>
                                    <div class="col-lg-7 col-md-9">
                                        <select class="form-control" id="gender" name="data[StudentNew][gender]" required="required"/>
                                            <option value="">  (Select Student's gender)  </option>
                                            <option value="Male">Male</option>
                                            <option value="Female">Female</option>
                                         </select>
                                    </div>
                                 </div>
                                </div>
                                <div class="panel-body">
                                     <div class="form-group">
                                        <label for="classlevel_id" class="col-lg-2 col-md-3 control-label">Class Level</label>
                                        <div class="col-lg-7 col-md-9">
                                            <?php
                                                echo $this->Form->input('classlevel_id_new', array(
                                                    'div' => false,
                                                    'label' => false,
                                                    'class' => 'form-control',
                                                    'id' => 'classlevel_id_new',
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
                                            <select class="form-control" name="data[StudentNew][class_id]" id="class_id_new" required="required">
                                                <option value="">  (Student's Current class)  </option>

                                            </select>
                                        </div>
                                    </div>
                                </div><br><br>
                                <div class="form-group">
                                    <label for="image_url" class="col-lg-2 col-md-3 control-label">&nbsp;&nbsp;</label>
                                    <div class="col-lg-7 col-md-9">
                                        <button type="submit" id="register_stud_btn" class="btn btn-info">Register Student</button>
                                    </div>
                                </div>
                            </div>
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