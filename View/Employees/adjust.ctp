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
                                    <h2 class="StepTitle">Staff Bio-Data <small class="text-danger"> <i class="fa fa-warning"></i>Note All Fields With * Need To Be Filled</small></h2>
                                    <div class="panel">
                                        <div class="panel-body">
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
                                                <label for="birth_date" class="col-lg-2 col-md-3 control-label">Date of Birth <small class="text-danger"> * </small></label>
                                                <div class="col-lg-7 col-md-">
                                                    <input type="text" class="form-control form-cascade-control input-small" name="data[Employee][birth_date]" placeholder="Select Staff's date of birth"
                                                    value="<?php echo $this->Utility->formatDate($employee['Employee']['birth_date']);?>" id="birth_date" required="required"/>
                                                </div>
                                            </div>
                                            <div class="form-group">
                                                <label class="col-lg-2 col-md-3 control-label">Nationality <small class="text-danger"> * </small></label>
                                                <div class="col-lg-7 col-md-9">
                                                    <?php 
                                                        echo $this->Form->input('country_id', array(
                                                                'div' => false,
                                                                'label' => false,
                                                                'class' => 'form-control',
                                                                'id' => 'country_id',
                                                                'options' => $Countrys,
                                                                'empty' => '(Select Staff\'s Country)'
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
                                                                    'empty' => '(Select Staff\'s State)'
                                                                )
                                                            ); 
                                                        ?>
                                                    </div>
                                                 </div>
                                                 <div class="form-group">
                                                    <label for="local_govt_id" class="col-lg-2 col-md-3 control-label">Local Govt. <small class="text-danger"> * </small></label>
                                                    <div class="col-lg-7 col-md-9">
                                                        <select class="form-control" name="data[Employee][local_govt_id]" id="local_govt_id">
                                                            <?php 
                                                                if(!empty($employee['Employee']['local_govt_id'])) { 
                                                                    echo '<option value="'.$employee['Employee']['local_govt_id'].'">'.$employee['LocalGovt']['local_govt_name'].'</option>';
                                                                } else { ?>
                                                                    <option value="">  (Select Staff's L.G.A)  </option>
                                                            <?php } ?>
                                                        </select>
                                                    </div>
                                                 </div>
                                            </div>
                                            <div class="form-group">
                                                <label for="marital_status" class="col-lg-2 col-md-3 control-label">Marital Status <small class="text-danger"> * </small></label>
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
                                            <div id="marital_status_div" class="hide">
                                                <div class="panel">
                                                    <div class="panel-body">
                                                        <div class="panel-heading text-primary"><h3 class="panel-title">Spouse Information</h3></div>
                                                        <div class="form-group">
                                                            <label for="spouse_name" class="col-lg-2 col-md-3 control-label">Full Name</label>
                                                            <div class="col-lg-7 col-md-">
                                                                <input type="hidden" name="data[Employee][spouse_detail_id]" id="spouse_detail_id" 
                                                                value="<?php echo !empty($SpouseDetail['SpouseDetail']['spouse_detail_id']) ? $SpouseDetail['SpouseDetail']['spouse_detail_id'] : '';?>"/>
                                                                <input type="text" class="form-control form-cascade-control input-small" name="data[Employee][spouse_name]" placeholder="Type Staff's Spouse Names"
                                                                    id="spouse_name" value="<?php echo !empty($SpouseDetail['SpouseDetail']['spouse_name']) ? $SpouseDetail['SpouseDetail']['spouse_name'] : '';?>"/>
                                                            </div>
                                                        </div>
                                                        <div class="form-group">
                                                            <label for="spouse_employer" class="col-lg-2 col-md-3 control-label">Current Employer</label>
                                                            <div class="col-lg-7 col-md-">
                                                                <input type="text" class="form-control form-cascade-control input-small" name="data[Employee][spouse_employer]"  placeholder="Type Staff's Spouse Employer"
                                                                id="spouse_employer" value="<?php echo !empty($SpouseDetail['SpouseDetail']['spouse_employer']) ? $SpouseDetail['SpouseDetail']['spouse_employer'] : '';?>"/>
                                                            </div>
                                                        </div>
                                                        <div class="form-group">
                                                            <label for="spouse_number" class="col-lg-2 col-md-3 control-label">Phone Number</label>
                                                            <div class="col-lg-7 col-md-">
                                                                <input type="text" class="form-control form-cascade-control input-small" name="data[Employee][spouse_number]" placeholder="Type Staff's Spouse Phone Number"
                                                                id="spouse_number" value="<?php echo !empty($SpouseDetail['SpouseDetail']['spouse_number']) ? $SpouseDetail['SpouseDetail']['spouse_number'] : '';?>" />
                                                            </div>
                                                        </div>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                                <div id="step-2">	
                                    <h2 class="StepTitle">Contact Information <small class="text-danger"> <i class="fa fa-warning"></i>Note All Fields With * Need To Be Filled</small></h2>
                                    <div class="panel">
                                        <div class="panel-body">
                                            <div class="form-group">
                                                <label for="mobile_number1" class="col-lg-2 col-md-3 control-label">Mobile Number 1 <small class="text-danger"> * </small></label>
                                              <div class="col-lg-7 col-md-9">
                                                <input type="text" class="form-control form-cascade-control input-small" name="data[Employee][mobile_number1]" 
                                                value="<?php echo $employee['Employee']['mobile_number1']?>" id="mobile_number1" placeholder="Staff's Mobile number One" required>
                                              </div>
                                            </div>
                                            <div class="form-group">
                                                <label for="mobile_number2" class="col-lg-2 col-md-3 control-label">Mobile Number 2</label>
                                                <div class="col-lg-7 col-md-9">
                                                    <input type="text" class="form-control form-cascade-control input-small" name="data[Employee][mobile_number2]" 
                                                    value="<?php echo !empty($employee['Employee']['mobile_number2']) ? $employee['Employee']['mobile_number2'] : '';?>" id="mobile_number2" placeholder="Staff's Mobile number Two if any">
                                                </div>
                                            </div>
                                            <div class="form-group">
                                                <label for="email" class="col-lg-2 col-md-3 control-label">Email <small class="text-danger"> * </small></label>
                                                <div class="col-lg-7 col-md-9">
                                                    <input type="email" class="form-control form-cascade-control input-small" name="data[Employee][email]"
                                                           value="<?php echo (empty($employee['Employee']['email'])) ? '' : $employee['Employee']['email'];?>" id="email" placeholder="Staff's e-mail">
                                                </div>
                                            </div>
                                            <div class="form-group">
                                                <label class="col-lg-2 col-md-3 control-label">Contact Address <small class="text-danger"> * </small></label>
                                                <div class="col-lg-7 col-md-9">
                                                    <textarea class="form-control form-cascade-control input-small" name="data[Employee][contact_address]" 
                                                    id="contact_address" placeholder="Employee's Contact Address" required><?php echo $employee['Employee']['contact_address']?></textarea>
                                                </div>
                                            </div>
                                            <div class="form-group">
                                                <label for="form_of_identity" class="col-lg-2 col-md-3 control-label">Form of I.D</label>
                                                <div class="col-lg-7 col-md-9">
                                                    <?php
                                                    echo $this->Form->input('form_of_identity', array(
                                                            'div' => false,
                                                            'label' => false,
                                                            'class' => 'form-control form-cascade-control input-small',
                                                            'id' => 'form_of_identity',
                                                            'options' => array(
                                                                'National I.D Card' => 'National I.D Card',
                                                                'International Passport' => 'International Passport',
                                                                'Voters Card' => 'Voters Card',
                                                                'Drivers Licence' => 'Drivers Licence'
                                                            ),
                                                            'empty' => '(Select Staff\'s Form of Identification)'
                                                        )
                                                    );
                                                    ?>
                                                </div>
                                            </div>
                                            <div class="form-group">
                                                <label for="identity_no" class="col-lg-2 col-md-3 control-label">I.D No.</label>
                                                <div class="col-lg-7 col-md-">
                                                    <input type="text" class="form-control form-cascade-control input-small" name="data[Employee][identity_no]"  placeholder="Type Employee's I.D Number"
                                                           id="identity_no" value="<?php echo !empty($employee['Employee']['identity_no']) ? $employee['Employee']['identity_no'] : '';?>"/>
                                                </div>
                                            </div>
                                            <div class="form-group">
                                                <label for="identity_expiry_date" class="col-lg-2 col-md-3 control-label">Expiry Date</label>
                                                <div class="col-lg-7 col-md-">
                                                    <?php
                                                    $date = '';
                                                    if(!empty($employee['Employee']['identity_expiry_date'])) {
                                                        $date = $this->Utility->formatDate($employee['Employee']['identity_expiry_date']);
                                                    }
                                                    ?>
                                                    <input type="text" class="form-control form-cascade-control input-small" name="data[Employee][identity_expiry_date]"  placeholder="Type Staff's I.D Expiry Date"
                                                           id="identity_expiry_date" value="<?php echo $date; ?>"/>
                                                </div>
                                            </div>
                                            <div class="panel">
                                                <div class="panel-body">
                                                    <div class="panel-heading text-primary"><h3 class="panel-title">Next of Kin Information</h3></div>
                                                    <div class="form-group">
                                                        <label for="next_ofkin_name" class="col-lg-2 col-md-3 control-label">Full Name <small class="text-danger"> * </small></label>
                                                      <div class="col-lg-7 col-md-9">
                                                        <input type="next_ofkin_name" class="form-control form-cascade-control input-small" name="data[Employee][next_ofkin_name]"  placeholder="Staff's Next of Kin Name"
                                                        id="next_ofkin_name" value="<?php echo !empty($employee['Employee']['next_ofkin_name']) ? $employee['Employee']['next_ofkin_name'] : '';?>"/>
                                                      </div>
                                                    </div>
                                                    <div class="form-group">
                                                        <label for="next_ofkin_number" class="col-lg-2 col-md-3 control-label">Mobile Number <small class="text-danger"> * </small></label>
                                                      <div class="col-lg-7 col-md-9">
                                                            <input type="text" class="form-control form-cascade-control input-small" name="data[Employee][next_ofkin_number]"  placeholder="Staff's Next of Kin Mobile No."
                                                            id="next_ofkin_number" value="<?php echo !empty($employee['Employee']['next_ofkin_number']) ? $employee['Employee']['next_ofkin_number'] : '';?>"/>
                                                      </div>
                                                    </div>
                                                    <div class="form-group">
                                                        <label for="next_ofkin_relate" class="col-lg-2 col-md-3 control-label">Relationship <small class="text-danger"> * </small></label>
                                                        <div class="col-lg-7 col-md-9">
                                                            <input type="text" class="form-control form-cascade-control input-small" name="data[Employee][next_ofkin_relate]"  placeholder="Staff's Next of Kin Relationship"
                                                            id="next_ofkin_relate" value="<?php echo !empty($employee['Employee']['next_ofkin_relate']) ? $employee['Employee']['next_ofkin_relate'] : '';?>"/>
                                                        </div>
                                                    </div>
                                                </div>
                                            </div>
                                            <!--div class="form-group">
                                                <label class="col-lg-2 col-md-3 control-label">Staff Type</label>
                                                <div class="col-lg-7 col-md-9">
                                                    <?php 
                //                                        echo $this->Form->input('employee_type_id', array(
                //                                                'div' => false,
                //                                                'label' => false,
                //                                                'class' => 'form-control',
                //                                                'id' => 'employee_type_id',
                //                                                'options' => $EmployeeTypes,
                //                                                'empty' => '(Select Employee\'s Type)'
                //                                            )
                //                                        ); 
                                                    ?>
                                                </div>
                                            </div-->
                                        </div>
                                    </div>
                                </div>
                                <div id="step-3">	
                                    <h2 class="StepTitle">Institutions Attended and Qualifications <small class="text-danger"> <i class="fa fa-warning"></i>Note All Fields With * Need To Be Filled</small></h2>
                                    <div class="panel">
                                        <div class="panel-body">
                                            <table  class="table table-bordered table-hover table-striped display" id="qualification_table">
                                                <thead>
                                                    <tr>
                                                        <th></th>
                                                        <th colspan="3" class="text-center">Institutions</th>
                                                        <th colspan="2" class="text-center">Qualifications</th>
                                                        <th></th>
                                                   </tr>
                                                   <tr>
                                                     <th>#</th>
                                                     <th>Institution Name</th>
                                                     <th>Date From</th>
                                                     <th>Date To</th>
                                                     <th>Obtained</th>
                                                     <th>Date</th>
                                                     <th></th>
                                                   </tr>
                                                 </thead>
                                                 <tbody>
                                                     <?php if(!empty($EmpQuas)):?>
                                                        <?php $i=1; foreach ($EmpQuas as $EmpQua): ?>
                                                            <tr class="gradeA">
                                                               <td><?php echo $i++;?></td>
                                                               <td>
                                                                   <input type="hidden" name="data[Employee][employee_qualification_id][]" value="<?php echo h($EmpQua['EmployeeQualification']['employee_qualification_id']);?>">
                                                                   <textarea class="form-control form-cascade-control input-medium" name="data[Employee][institution][]" id="institution" 
                                                                   placeholder="Institution Attended" required><?php echo h($EmpQua['EmployeeQualification']['institution']);?></textarea>
                                                               </td>
                                                               <td>
                                                                   <input type="text" class="form-control form-cascade-control input-mini date_picker" name="data[Employee][date_from][]" 
                                                                    id="date_from" value="<?php echo $this->Utility->formatDate($EmpQua['EmployeeQualification']['date_from']);?>" placeholder="Date From">
                                                               </td>
                                                               <td>
                                                                   <input type="text" class="form-control form-cascade-control input-mini date_picker" name="data[Employee][date_to][]" 
                                                                    id="date_to" value="<?php echo $this->Utility->formatDate($EmpQua['EmployeeQualification']['date_to']);?>" placeholder="Date To">
                                                               </td>
                                                               <td>
                                                                   <textarea class="form-control form-cascade-control input-medium" name="data[Employee][qualification][]" placeholder="Qualification Obtained"
                                                                   id="qualification"  required><?php echo h($EmpQua['EmployeeQualification']['qualification']);?></textarea>
                                                               </td>
                                                               <td>
                                                                   <input type="text" class="form-control form-cascade-control input-mini date_picker" name="data[Employee][qualification_date][]" 
                                                                    id="qualification_date" value="<?php echo $this->Utility->formatDate($EmpQua['EmployeeQualification']['qualification_date']);?>" placeholder="Date Obtained">
                                                               </td>
                                                               <td></td>
                                                            </tr>
                                                        <?php endforeach; ?>
                                                    <?php else:?>
                                                        <tr>
                                                            <td>1</td>
                                                            <td>
                                                                <input type="hidden" name="data[Employee][employee_qualification_id][]" value="">
                                                                <textarea class="form-control form-cascade-control input-medium" name="data[Employee][institution][]" 
                                                                   id="institution" placeholder="Institution Attended" required></textarea>
                                                            </td>
                                                            <td>
                                                               <input type="text" class="form-control form-cascade-control input-mini date_picker" name="data[Employee][date_from][]" 
                                                              id="date_from" placeholder="Date From">
                                                            </td>
                                                            <td>
                                                               <input type="text" class="form-control form-cascade-control input-mini date_picker" name="data[Employee][date_to][]" 
                                                              id="date_to" placeholder="Date To">
                                                            </td>
                                                            <td>
                                                                <textarea class="form-control form-cascade-control input-medium" name="data[Employee][qualification][]" 
                                                                   id="qualification" placeholder="Qualification Obtained" required></textarea>
                                                            </td>
                                                            <td>
                                                               <input type="text" class="form-control form-cascade-control input-mini date_picker" name="data[Employee][qualification_date][]" 
                                                              id="qualification_date" placeholder="Date Obtained">
                                                            </td>
                                                            <td></td>
                                                        </tr>
                                                    <?php endif;?>
                                                 </tbody>
                                                 <tfoot>
                                                     <tr>
                                                         <td colspan="7">
                                                             <div class="col-sm-offset-5 col-sm-10">
                                                                <button type="button" class="add_new_row_btn btn btn-success">Add New Row</button>
                                                            </div>
                                                        </td>
                                                     </tr>
                                                 </tfoot>
                                            </table>
                                        </div>
                                    </div>
                                </div>
                                <div id="step-4">	
                                    <h2 class="StepTitle">Passport Upload</h2>	
                                    <div class="panel">
                                        <div class="panel-body">
                                            <center>
                                                <div class="form-group">
                                                    <label for="image_url" class="col-lg-2 col-md-3 control-label">&nbsp;&nbsp;</label>
                                                    <div class="col-lg-7 col-md-9">
                                                        <span class="btn btn-info fileinput-button" ng-class="{disabled: disabled}">
                                                            <i class="glyphicon glyphicon-plus"></i>
                                                            <span>Browse File...</span>
                                                            <input ng-disabled="disabled" value="<?php echo $employee['Employee']['image_url']?>" type="file" name="data[Employee][image_url]" id="image_url" onChange="readURL(this);" required="required" /><br>
                                                            <img data-src="holder.js/140x140" class="img-rounded" id="img_prev" src="<?php echo DOMAIN_NAME ?>/img/uploads/<?php echo ($employee['Employee']['image_url']) ? $employee['Employee']['image_url'] : 'avatar.jpg';?>" style="width: 140px; height: 140px;"/>
                                                        </span>
                                                        <div id="image_error"></div>
                                                    </div>
                                                </div><br><br>
                                                <div class="form-group">
                                                  <label class="col-lg-2 col-md-3 control-label">&nbsp;&nbsp;</label>
                                                  <div class="col-lg-7 col-md-9">
                                                      <button type="submit" id="register_emp_btn" class="btn btn-info">Update Record</button>
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
    //on click of Edit Staff Record link... activate the link
    echo $this->Js->buffer('
        setTabActive("[href=\"'.DOMAIN_NAME.'/employees/\"]", 0);
    ');
?>
<?php
    // OnChange Of States Get Local Govt
//    $this->Utility->getDependentListBox('#state_id', '#local_govt_id', 'local_govts', 'ajax_get_local_govt', 'Employee');
?>