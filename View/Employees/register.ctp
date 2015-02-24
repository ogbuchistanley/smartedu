<?php echo $this->Html->script("../app/js/jquery-ui.js", FALSE);?>
<?php echo $this->Html->script("../app/jquery/custom.employee.js", FALSE);?>

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
                   <i class="fa fa-pencil-square"></i> Create New Employee
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
                            echo $this->Form->create('EmployeeNew', array(
                                    'class' => 'form-horizontal cascde-forms',
                                    'novalidate' => 'novalidate',
                                    'id' => 'employee_form',
                                    'type' => 'file'
                                )
                            );     
                        ?>
                        <!--form class="form-horizontal cascde-forms" method="post" action="#" name="basic_validate" id="basic_validate" novalidate="novalidate"-->
                        <br>
                            <div class="form-group">
                                <label class="col-lg-2 col-md-3 control-label">Title</label>
                                <div class="col-lg-7 col-md-9">
                                    <?php 
                                        echo $this->Form->input('salutation_id', array(
                                                'div' => false,
                                                'label' => false,
                                                'class' => 'form-control',
                                                'id' => 'salutation_id',
                                                'options' => $Salutations,
                                                'empty' => '(Select Employee\'s Title)'
                                            )
                                        ); 
                                    ?>
                               </div>
                            </div>
                            <div class="form-group">
                                <label class="col-lg-2 col-md-3 control-label">First Name</label>
                                <div class="col-lg-7 col-md-9">
                                 <input type="text" class="form-control form-cascade-control input-small"
                                 name="data[EmployeeNew][first_name]" id="first_name" placeholder="Type Employee's first name" required>
                               </div>
                            </div>
                            <div class="form-group">
                                <label class="col-lg-2 col-md-3 control-label">Other Names</label>
                                <div class="col-lg-7 col-md-9">
                                    <input type="text" class="form-control form-cascade-control input-small" 
                                    name="data[EmployeeNew][other_name]" id="other_name" placeholder="Type Employee's other names" required>
                                </div>
                            </div>
                            <div class="form-group">
                                <label for="mobile_number1" class="col-lg-2 col-md-3 control-label">Mobile Number</label>
                                <div class="col-lg-7 col-md-9">
                                    <input type="text" class="form-control form-cascade-control input-small" name="data[EmployeeNew][mobile_number1]" 
                                    id="mobile_number1" placeholder="Employee's Mobile Number" required>
                                </div>
                            </div>
                            <div class="form-group">
                              <label class="col-lg-2 col-md-3 control-label">&nbsp;&nbsp;</label>
                              <div class="col-lg-7 col-md-9">
                                  <button type="submit" id="register_emp_btn" class="btn btn-info">Register Employee</button>
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
//    echo $this->Js->buffer('
//        $("#country_id").val("140");
//    ');
    //on click of Register New Employee Record link... activate the link
    echo $this->Js->buffer('
        setTabActive("[href=\"'.DOMAIN_NAME.'/employees/register\"]", 1);
    ');
?>
<?php
    // OnChange Of States Get Local Govt
//    $this->Utility->getDependentListBox('#state_id', '#local_govt_id', 'local_govts', 'ajax_get_local_govt', 'Employee');
?>
