<?php echo $this->Html->script("../app/js/jquery-ui.js", FALSE);?>
<?php echo $this->Html->script("../app/jquery/custom.employee.js", FALSE);?>
<?php 
    App::uses('Encryption', 'Utility'); 
    $Encryption = new Encryption();
?>
    <div class="row">
        <?php
        $errors = $this->validationErrors['Employee'];
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

    <div class="col-md-10">
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
                   <i class="fa fa-edit"></i> Adjust Staffs Information <small class="text-danger"> <i class="fa fa-warning"></i>Note All Fields With * Need To Be Filled</small>
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
                            $encrypted_employee_id = $Encryption->encode($employee['Employee']['employee_id']);
                            //Creates The Form
                            echo $this->Form->create('Employee', array(
                                    'url' => '/employees/adjust/'.$encrypted_employee_id,
                                    'class' => 'form-horizontal cascde-forms',
                                    'novalidate' => 'novalidate',
                                    'id' => 'employee_form',
                                    'type' => 'file'
                                )
                            );     
                        ?>
                            <div class="form-group">
                                <?php echo $this->Form->input('employee_id'); ?>
                            </div>
                            <div class="form-group">
                                <label class="col-lg-2 col-md-3 control-label">Title <small class="text-danger"> * </small></label>
                                <div class="col-lg-7 col-md-9">
                                    <?php
                                        echo $this->Form->input('salutation_id', array(
                                                'div' => false,
                                                'label' => false,
                                                'class' => 'form-control',
                                                'id' => 'salutation_id',
                                                'options' => $Salutations,
                                                'empty' => '(Select Staff\'s Title)'
                                            )
                                        );
                                    ?>
                               </div>
                            </div>
                            <div class="form-group">
                                <label class="col-lg-2 col-md-3 control-label" for="first_name">Surname <small class="text-danger"> * </small></label>
                                <div class="col-lg-7 col-md-9">
                                 <input type="text" class="form-control form-cascade-control input-small" value="<?php echo $employee['Employee']['first_name']?>"
                                    name="data[Employee][first_name]" id="first_name" placeholder="Type Staff's Surname" required>
                               </div>
                            </div>
                            <div class="form-group">
                              <label class="col-lg-2 col-md-3 control-label" for="other_name">First Name <small class="text-danger"> * </small></label>
                              <div class="col-lg-7 col-md-9">
                               <input type="text" class="form-control form-cascade-control input-small" value="<?php echo $employee['Employee']['other_name']?>"
                                name="data[Employee][other_name]" id="other_name" placeholder="Type Staff's First Name" required>
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
                                                'empty' => '(Select Staff\'s Gender)'
                                            )
                                        );
                                    ?>
                                </div>
                            </div>

                            <div class="form-group">
                                <label for="mobile_number1" class="col-lg-2 col-md-3 control-label">Mobile Number 1 <small class="text-danger"> * </small></label>
                              <div class="col-lg-7 col-md-9">
                                <input type="tel" class="form-control form-cascade-control input-small" name="data[Employee][mobile_number1]"
                                value="<?php echo $employee['Employee']['mobile_number1']?>" id="mobile_number1" required>
                                  <!--span id="valid-msg" class="hide alert-success">✓ Valid</span>
                                    <span id="error-msg" class="hide alert-danger">Invalid number</span-->
                              </div>
                            </div>
                            <div class="form-group">
                                <label for="mobile_number2" class="col-lg-2 col-md-3 control-label">Mobile Number 2</label>
                                <div class="col-lg-7 col-md-9">
                                    <input type="tel" class="form-control form-cascade-control input-small" name="data[Employee][mobile_number2]"
                                    value="<?php echo !empty($employee['Employee']['mobile_number2']) ? $employee['Employee']['mobile_number2'] : '';?>" id="mobile_number2" placeholder="Staff's Mobile number Two if any">
                                </div>
                            </div>
                            <div class="form-group">
                                <label for="email" class="col-lg-2 col-md-3 control-label">Email</label>
                                <div class="col-lg-7 col-md-9">
                                    <input type="email" class="form-control form-cascade-control input-small" name="data[Employee][email]"
                                           value="<?php echo (empty($employee['Employee']['email'])) ? '' : $employee['Employee']['email'];?>" id="email" placeholder="Staff's e-mail">
                                </div>
                            </div>
                            <div class="form-group">
                                <label for="marital_status" class="col-lg-2 col-md-3 control-label">Marital Status</label>
                                <div class="col-lg-7 col-md-9">
                                    <?php
                                    echo $this->Form->input('marital_status', array(
                                            'div' => false,
                                            'label' => false,
                                            'class' => 'form-control form-cascade-control input-small',
                                            'id' => 'marital_status',
                                            'options' => array('Single' => 'Single', 'Married' => 'Married'),
                                            'empty' => '(Select Staff\'s Marital Status)'
                                        )
                                    );
                                    ?>
                                </div>
                            </div>
                            <div class="form-group">
                              <label class="col-lg-2 col-md-3 control-label">&nbsp;&nbsp;</label>
                              <div class="col-lg-7 col-md-9">
                                  <button type="submit" id="register_emp_btn" class="btn btn-info">Update Record</button>
                              </div>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
        </div>	
    </div>
<?php
    //on click of Edit Staff Record link... activate the link
    echo $this->Js->buffer('
        setTabActive("[href=\"'.DOMAIN_NAME.'/employees/adjust\"]", 0);
    ');
?>
<?php
    // OnChange Of States Get Local Govt
//    $this->Utility->getDependentListBox('#state_id', '#local_govt_id', 'local_govts', 'ajax_get_local_govt', 'Employee');
?>