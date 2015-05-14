<link href="<?php echo APP_DIR_ROOT; ?>Intl-Tel-Input/build/css/intlTelInput.css" rel="stylesheet">
<?php echo $this->Html->script("../app/Intl-Tel-Input/build/js/intlTelInput.js", FALSE);?>
<?php echo $this->Html->script("../app/js/jquery-ui.js", FALSE);?>
<?php echo $this->Html->script("../app/jquery/custom.employee.js", FALSE);?>

<div class="row">
    <?php
    //    $errors = $this->validationErrors['EmployeeNew'];
    //    $flatErrors = Set::flatten($errors);
    //    $flatErrors2 = $flatErrors;
    //    $test = array();
    //    foreach($flatErrors as $key => $value){
    //        $test[] = $value;
    //    }
    //    if(!empty($test[count($test) - 1])) {
    //        echo '<div class="alert alert-danger">';
    //        echo '<ul>';
    //        foreach($flatErrors2 as $key => $value) {
    //            echo (!empty($value)) ? '<li>'.$value.'</li>' : false;
    //        }
    //        echo '</ul>';
    //        echo '</div>';
    //    }
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
                <i class="fa fa-pencil-square"></i> Create New Staff <small class="text-danger"> <i class="fa fa-warning"></i>Note All Fields With * Need To Be Filled</small>
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
                            'class' => 'form-horizontal cascade-forms',
                            'novalidate' => 'novalidate',
                            'id' => 'employee_form'
                            //'type' => 'file'
                        )
                    );
                    ?>
                    <!--form class="form-horizontal cascde-forms" method="post" action="#" name="basic_validate" id="basic_validate" novalidate="novalidate"-->
                    <br>
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
                            <input type="text" class="form-control form-cascade-control input-small"
                                   name="data[EmployeeNew][first_name]" id="first_name" placeholder="Type Staff's Surname" required>
                        </div>
                    </div>
                    <div class="form-group">
                        <label class="col-lg-2 col-md-3 control-label" for="other_name">First Name <small class="text-danger"> * </small></label>
                        <div class="col-lg-7 col-md-9">
                            <input type="text" class="form-control form-cascade-control input-small"
                                   name="data[EmployeeNew][other_name]" id="other_name" placeholder="Type Staff's First Name" required>
                        </div>
                    </div>
                    <div class="form-group">
                        <label for="mobile_number1" class="col-lg-2 col-md-3 control-label">Mobile Number <small class="text-danger"> * </small></label>
                        <div class="col-lg-7 col-md-9">
                            <input type="tel" class="form-control form-cascade-control input-small" name="data[EmployeeNew][mobile_number1]" id="mobile_number1" required>
                            <span id="valid-msg" class="hide alert-success">✓ Valid</span>
                            <span id="error-msg" class="hide alert-danger">Invalid number</span>
                        </div>
                    </div>
                    <div class="form-group">
                        <label class="col-lg-2 col-md-3 control-label">Email</label>
                        <div class="col-lg-7 col-md-9">
                            <input type="email" class="form-control form-cascade-control input-small" name="data[EmployeeNew][email]"
                                   id="email" placeholder="Staff's e-mail">
                        </div>
                    </div>
                    <div class="form-group">
                        <label class="col-lg-2 col-md-3 control-label">&nbsp;&nbsp;</label>
                        <div class="col-lg-7 col-md-9">
                            <button type="submit" id="register_emp_btn" class="btn btn-info">Register Staff</button>
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
//on click of Register New Staff Record link... activate the link
echo $this->Js->buffer('
        setTabActive("[href=\"'.DOMAIN_NAME.'/employees/register\"]", 1);
    ');
?>
<?php
// OnChange Of States Get Local Govt
//    $this->Utility->getDependentListBox('#state_id', '#local_govt_id', 'local_govts', 'ajax_get_local_govt', 'Employee');
?>
