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
                            echo $this->Form->create('Employee', array(
                                    'action' => 'register',
                                    'class' => 'form-horizontal cascde-forms',
                                    'novalidate' => 'novalidate',
                                    'id' => 'employee_form',
                                    'type' => 'file'
                                )
                            );     
                        ?>
                        <!--form class="form-horizontal cascde-forms" method="post" action="#" name="basic_validate" id="basic_validate" novalidate="novalidate"-->
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
                                    <h2 class="StepTitle">Employee Bio-Data</h2>	
                                    <div class="panel">
                                        <div class="panel-body">
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
                                                 name="data[Employee][first_name]" id="first_name" placeholder="Type Employee's first name" required>
                                               </div>
                                            </div>
                                            <div class="form-group">
                                              <label class="col-lg-2 col-md-3 control-label">Other Names</label>
                                              <div class="col-lg-7 col-md-9">
                                               <input type="text" class="form-control form-cascade-control input-small" 
                                               name="data[Employee][other_name]" id="other_name" placeholder="Type Employee's other names" required>
                                             </div>
                                            </div>
                                            <div class="form-group">
                                                <label for="gender" class="col-lg-2 col-md-3 control-label">Gender</label>
                                                <div class="col-lg-7 col-md-9">
                                                    <select class="form-control" id="gender" name="data[Employee][gender]" required="required">
                                                        <option value="">  (Select Employee's gender)  </option>
                                                        <option value="male">Male</option>
                                                        <option value="female">Female</option>
                                                     </select>
                                                </div>
                                            </div>
                                            <div class="form-group">
                                                <label for="birth_date" class="col-lg-2 col-md-3 control-label">Date of Birth</label>
                                                <div class="col-lg-7 col-md-">
                                                    <input type="text" class="form-control form-cascade-control input-small" name="data[Employee][birth_date]" 
                                                    id="birth_date" placeholder="Select Employee's date of birth" required="required"/>
                                                </div>
                                            </div>
                                            <div class="form-group">
                                                <label class="col-lg-2 col-md-3 control-label">Nationality</label>
                                                <div class="col-lg-7 col-md-9">
                                                    <?php 
                                                        echo $this->Form->input('country_id', array(
                                                                'div' => false,
                                                                'label' => false,
                                                                'class' => 'form-control',
                                                                'id' => 'country_id',
                                                                'required' => 'required',
                                                                'options' => $Countrys,
                                                                'empty' => '(Select Employee\'s Country)'
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
                                                                    'empty' => '(Select Employee\'s State)'
                                                                )
                                                            ); 
                                                        ?>
                                                    </div>
                                                 </div>
                                                 <div class="form-group">
                                                    <label for="local_govt_id" class="col-lg-2 col-md-3 control-label">Local Govt.</label>
                                                    <div class="col-lg-7 col-md-9">
                                                        <select class="form-control" name="data[Employee][local_govt_id]" id="local_govt_id">
                                                            <option value="">  (Select Employee's L.G.A)  </option>

                                                         </select>
                                                    </div>
                                                 </div>
                                            </div>
                                            <div class="form-group">
                                                <label for="marital_status" class="col-lg-2 col-md-3 control-label">Marital Status</label>
                                                <div class="col-lg-7 col-md-9">
                                                    <select class="form-control" id="marital_status" name="data[Employee][marital_status]" required="required">
                                                        <option value="">  (Select Employee's Marital Status)  </option>
                                                        <option value="Single">Single</option>
                                                        <option value="Married">Married</option>
                                                     </select>
                                                </div>
                                             </div>
                                            <div id="marital_status_div" class="hide">
                                                <div class="panel">
                                                    <div class="panel-body">
                                                        <div class="panel-heading text-primary"><h3 class="panel-title">Spouse Information</h3></div>
                                                        <div class="form-group">
                                                            <label for="spouse_name" class="col-lg-2 col-md-3 control-label">Full Name</label>
                                                            <div class="col-lg-7 col-md-">
                                                                <input type="text" class="form-control form-cascade-control input-small" name="data[Employee][spouse_name]" 
                                                                id="spouse_name" placeholder="Type Employee's Spouse Names"/>
                                                            </div>
                                                        </div>
                                                        <div class="form-group">
                                                            <label for="spouse_employer" class="col-lg-2 col-md-3 control-label">Current Employer</label>
                                                            <div class="col-lg-7 col-md-">
                                                                <input type="text" class="form-control form-cascade-control input-small" name="data[Employee][spouse_employer]" 
                                                                id="spouse_employer" placeholder="Type Employee's Spouse Employer"/>
                                                            </div>
                                                        </div>
                                                        <div class="form-group">
                                                            <label for="spouse_number" class="col-lg-2 col-md-3 control-label">Phone Number</label>
                                                            <div class="col-lg-7 col-md-">
                                                                <input type="text" class="form-control form-cascade-control input-small" name="data[Employee][spouse_number]" 
                                                                id="spouse_number" placeholder="Type Employee's Spouse Phone Number"/>
                                                            </div>
                                                        </div>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                                <div id="step-2">	
                                    <h2 class="StepTitle">Contact Information</h2>	
                                    <div class="panel">
                                        <div class="panel-body">
                                            <div class="form-group">
                                                <label for="form_of_identity" class="col-lg-2 col-md-3 control-label">Form of I.D</label>
                                                <div class="col-lg-7 col-md-9">
                                                    <select class="form-control" id="form_of_identity" name="data[Employee][form_of_identity]">
                                                        <option value="">  (Select Employee's Form of Identification)  </option>
                                                        <option value="National I.D Card">National I.D Card</option>
                                                        <option value="International Passport">International Passport</option>
                                                        <option value="Voters Card">Voters Card</option>
                                                        <option value="Drivers Licence">Drivers Licence </option>
                                                     </select>
                                                </div>
                                            </div>
                                            <div class="form-group">
                                                <label for="identity_no" class="col-lg-2 col-md-3 control-label">I.D No.</label>
                                                <div class="col-lg-7 col-md-">
                                                    <input type="text" class="form-control form-cascade-control input-small" name="data[Employee][identity_no]" 
                                                    id="identity_no" placeholder="Type Employee's I.D Number"/>
                                                </div>
                                            </div>
                                            <div class="form-group">
                                                <label for="identity_expiry_date" class="col-lg-2 col-md-3 control-label">Expiry Date</label>
                                                <div class="col-lg-7 col-md-">
                                                    <input type="text" class="form-control form-cascade-control input-small" name="data[Employee][identity_expiry_date]" 
                                                    id="identity_expiry_date" placeholder="Type Employee's I.D Expiry Date"/>
                                                </div>
                                            </div>
                                            <div class="form-group">
                                                <label for="email" class="col-lg-2 col-md-3 control-label">Email</label>
                                              <div class="col-lg-7 col-md-9">
                                                <input type="email" class="form-control form-cascade-control input-small" name="data[Employee][email]" 
                                                id="email" placeholder="Employee's e-mail">
                                              </div>
                                            </div>
                                            <div class="form-group">
                                                <label for="mobile_number1" class="col-lg-2 col-md-3 control-label">Mobile Number 1</label>
                                              <div class="col-lg-7 col-md-9">
                                                    <input type="text" class="form-control form-cascade-control input-small" name="data[Employee][mobile_number1]" 
                                                    id="mobile_number1" placeholder="Employee's Mobile number One" required>
                                              </div>
                                            </div>
                                            <div class="form-group">
                                                <label for="mobile_number2" class="col-lg-2 col-md-3 control-label">Mobile Number 2</label>
                                                <div class="col-lg-7 col-md-9">
                                                    <input type="text" class="form-control form-cascade-control input-small" name="data[Employee][mobile_number2]" 
                                                    id="mobile_number2" placeholder="Employee's Mobile number Two if any">
                                                </div>
                                            </div>
                                            <div class="form-group">
                                                <label class="col-lg-2 col-md-3 control-label">Contact Address</label>
                                                <div class="col-lg-7 col-md-9">
                                                    <textarea class="form-control form-cascade-control input-small" name="data[Employee][contact_address]" 
                                                    id="contact_address" placeholder="Employee's Contact Address" required></textarea>
                                                </div>
                                            </div>
                                            <div class="panel">
                                                <div class="panel-body">
                                                    <div class="panel-heading text-primary"><h3 class="panel-title">Next of Kin Information</h3></div>
                                                    <div class="form-group">
                                                        <label for="next_ofkin_name" class="col-lg-2 col-md-3 control-label">Full Name </label>
                                                      <div class="col-lg-7 col-md-9">
                                                        <input type="next_ofkin_name" class="form-control form-cascade-control input-small" name="data[Employee][next_ofkin_name]" 
                                                        id="next_ofkin_name" placeholder="Employee's Next of Kin Name">
                                                      </div>
                                                    </div>
                                                    <div class="form-group">
                                                        <label for="next_ofkin_number" class="col-lg-2 col-md-3 control-label">Mobile Number</label>
                                                      <div class="col-lg-7 col-md-9">
                                                            <input type="text" class="form-control form-cascade-control input-small" name="data[Employee][next_ofkin_number]" 
                                                            id="next_ofkin_number" placeholder="Employee's Next of Kin Mobile No." required>
                                                      </div>
                                                    </div>
                                                    <div class="form-group">
                                                        <label for="next_ofkin_relate" class="col-lg-2 col-md-3 control-label">Relationship</label>
                                                        <div class="col-lg-7 col-md-9">
                                                            <input type="text" class="form-control form-cascade-control input-small" name="data[Employee][next_ofkin_relate]" 
                                                            id="next_ofkin_relate" placeholder="Employee's Next of Kin Relationship">
                                                        </div>
                                                    </div>
                                                </div>
                                            </div>
                                            <!--div class="form-group">
                                                <label class="col-lg-2 col-md-3 control-label">Employee Type</label>
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
                                    <h2 class="StepTitle">Institutions Attended and Qualifications</h2>	
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
                                                     <tr>
                                                         <td>1</td>
                                                         <td>
                                                             <textarea class="form-control form-cascade-control input-medium" name="data[Employee][institution][]" 
                                                                id="institution" placeholder="Employee's Institution" required></textarea>
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
                                                            <input ng-disabled="disabled" type="file" name="data[Employee][image_url]" id="image_url" onChange="readURL(this);" required="required" /><br>
                                                            <img data-src="holder.js/140x140" class="img-rounded" id="img_prev" src="javascript:void(0);" style="width: 140px; height: 140px;"/>
                                                        </span>
                                                        <div id="image_error"></div>
                                                    </div>
                                                </div><br><br>
                                                <div class="form-group">
                                                  <label class="col-lg-2 col-md-3 control-label">&nbsp;&nbsp;</label>
                                                  <div class="col-lg-7 col-md-9">
                                                      <button type="submit" id="register_emp_btn" class="btn btn-info">Register Employee</button>
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
