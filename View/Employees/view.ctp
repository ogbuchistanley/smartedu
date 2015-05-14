<?php echo $this->Html->script("../app/jquery/custom.employee.js", FALSE);?>
<div class="col-md-12">
    <div class="panel">
        <!-- Info Boxes -->
        <!--div class="row">
            <div class="col-md-12">
                <div class="info-box  bg-info  text-white">
                    <div class="info-icon bg-info-dark">
                        <i class="fa fa-info-circle fa-4x"></i>
                    </div>
                    <div class="info-details">
                        <h4>Employee Complete Information   
                            <span class="badge pull-right bg-white text-info"><?php //echo $employee['Employee']['first_name'], ' ', $employee['Employee']['other_name'];?>
                            <i class="fa fa-user fa-1x"></i> 
                            </span> 
                        </h4>
                    </div>
                </div>
            </div>
        </div>
        <!-- / Info Boxes -->
        <div class="panel-heading text-primary">
            <h3 class="panel-title">
               <i class="fa fa-info-circle"></i>
               Staffs Information
                <span class="pull-right">
                    <a href="javascript:void(0)"  title="Refresh"><i class="fa fa-refresh"></i></a>
                    <a href="#" class="panel-minimize"><i class="fa fa-chevron-up"></i></a>
                    <a href="#" class="panel-close"><i class="fa fa-times"></i></a>
                </span>
            </h3>
        </div>
        <div class="col-md-8">
            <div class="panel panel-info">
                <div class="panel-heading panel-title  text-white">Details Table</div>
                <div style="overflow-x: scroll" class="panel-body">
                    <table  class="table table-bordered table-hover table-striped display" id="student_table" >
                        <tbody>
                            <tr>
                                <th>Full Name</th>
                                <td>
                                    <?php
                                        echo h($employee['Salutation']['salutation_abbr']), ' ', h($employee['Employee']['first_name']), ' ', h($employee['Employee']['other_name']);
                                        $nil = '<span class="label label-danger">nill</span>';
                                    ?>
                                </td>
                            </tr>
                            <tr>
                                <th>Staff ID</th>
                                <td><?php echo h($employee['Employee']['employee_no']); ?></td>
                            </tr>
                            <tr>
                                <th>Gender</th>
                                <td><?php echo h($employee['Employee']['gender']); ?></td>
                            </tr>
                            <tr>
                                <th>Date of Birth</th>
                                <td><?php echo h($employee['Employee']['birth_date']); ?></td>
                            </tr>
                            <tr>
                                <th>Marital Status</th>
                                <td><?php echo h($employee['Employee']['marital_status']); ?></td>
                            </tr>
                            <tr>
                                <th>Email</th>
                                <td><?php echo (!empty($employee['Employee']['email'])) ? h($employee['Employee']['email']) : $nil; ?></td>
                            </tr>
                            <tr>
                                <th>Mobile Number 1</th>
                                <td><?php echo h($employee['Employee']['mobile_number1']); ?></td>
                            </tr>
                            <tr>
                                <th>Mobile Number 2</th>
                                <td><?php echo (!empty($employee['Employee']['mobile_number2'])) ? h($employee['Employee']['mobile_number2']) : $nil; ?></td>
                            </tr>
                            <tr>
                                <th>Contact Address</th>
                                <td><?php echo (!empty($employee['Employee']['contact_address'])) ? h($employee['Employee']['contact_address']) : $nil; ?></td>
                            </tr>
                            <?php if(!empty($SpouseDetail) && $SpouseDetail === 'hide') :?>
                                <tr>
                                    <th>Spouse Name</th>
                                    <td><?php echo (!empty($SpouseDetail['SpouseDetail']['spouse_name'])) ? h($SpouseDetail['SpouseDetail']['spouse_name']) : $nil; ?></td>
                                </tr>
                                <tr>
                                    <th>Spouse Mobile Number</th>
                                    <td><?php echo (!empty($SpouseDetail['SpouseDetail']['spouse_number'])) ? h($SpouseDetail['SpouseDetail']['spouse_number']) : $nil; ?></td>
                                </tr>
                                <tr>
                                    <th>Spouse Employer</th>
                                    <td><?php echo (!empty($SpouseDetail['SpouseDetail']['spouse_employer'])) ? h($SpouseDetail['SpouseDetail']['spouse_employer']) : $nil; ?></td>
                                </tr>
                            <?php endif;?>
                            <?php if(!empty($SpouseDetail) && $SpouseDetail === 'hide') :?>
                            <tr>
                                <th>Nationality</th>
                                <td><?php echo (!empty($employee['Employee']['country_id'])) ? h($employee['Country']['country_name']) : $nil;?></td>
                            </tr>
                            <tr>
                                <th>State of Origin</th>
                                <td><?php echo (!empty($employee['Employee']['state_id'])) ? h($employee['State']['state_name']).' State' : $nil;?></td>
                            </tr>
                            <tr>
                                <th>Local Govt. Area</th>
                                <td><?php echo (!empty($employee['Employee']['local_govt_id'])) ? h($employee['LocalGovt']['local_govt_name']) : $nil;?></td>
                            </tr>
                            <tr>
                                <th>Next of Kin Name</th>
                                <td><?php echo (!empty($employee['Employee']['next_ofkin_name'])) ? h($employee['Employee']['next_ofkin_name']) : $nil;?></td>
                            </tr>
                            <tr>
                                <th>Next of Kin Number</th>
                                <td><?php echo (!empty($employee['Employee']['next_ofkin_number'])) ? h($employee['Employee']['next_ofkin_number']) : $nil;?></td>
                            </tr>
                            <tr>
                                <th>Next of Kin Relationship</th>
                                <td><?php echo (!empty($employee['Employee']['next_ofkin_relate'])) ? h($employee['Employee']['next_ofkin_relate']) : $nil;?></td>
                            </tr>
                            <tr>
                                <th>Form of Identification</th>
                                <td><?php echo (!empty($employee['Employee']['form_of_identity'])) ? h($employee['Employee']['form_of_identity']) : $nil;?></td>
                            </tr>
                            <tr>
                                <th>Identification Number</th>
                                <td><?php echo (!empty($employee['Employee']['identity_no'])) ? h($employee['Employee']['identity_no']) : $nil;?></td>
                            </tr>
                            <tr>
                                <th>I.D Expiry Date</th>
                                <td><?php echo (!empty($employee['Employee']['identity_expiry_date'])) ? h($employee['Employee']['identity_expiry_date']) : $nil;?></td>
                            </tr>
                            <?php endif;?>
                        </tbody>
                    </table>
                </div> <!-- /panel body -->
            </div>
        </div>
        <div class="price-list row">
            <div class="price-box col-md-3 col-sm-6 col-xs-12 col-lg-3 featured">
                <div class="price-header">
                    <h3 class="bg-info">Passport</h3>
                </div>
                <ul class="list-group features">
                    <li class="list-group-item">
                        <img class="img-rounded" data-src="holder.js/140x140"  style='width: 140px; height: 140px;'
                             src="<?php echo DOMAIN_NAME ?>/img/uploads/<?php echo ($employee['Employee']['image_url']) ? $employee['Employee']['image_url'] : 'avatar.jpg';?>"/>
                    </li>
                    <li class="list-group-item select">
                        <a class="btn btn-block bg-info text-white btn-lg "></a>
                    </li>
                </ul>
            </div>
        </div>


        <?php if(!empty($EmpQuas) && $EmpQuas === 'hide'):?>
            <div class="row" style="overflow: scroll">
                <div class="col-md-12">
                    <div class="panel-body">
                        <div class="panel panel-default">
                            <div class="panel-body panel-info">
                                <div class="panel-heading panel-title  text-white">Qualification Information</div>
                                <table  class="table table-bordered table-hover table-striped display custom_tables">
                                    <thead>
                                        <tr>
                                            <th></th>
                                            <th colspan="3" class="text-center">Institutions</th>
                                            <th colspan="2" class="text-center">Qualifications</th>
                                       </tr>
                                       <tr>
                                         <th>#</th>
                                         <th>Institution Name</th>
                                         <th>Date From</th>
                                         <th>Date To</th>
                                         <th>Obtained</th>
                                         <th>Date</th>
                                       </tr>
                                     </thead>
                                     <tbody>
                                        <?php $i=1; foreach ($EmpQuas as $EmpQua): ?>
                                            <tr class="gradeA">
                                               <td><?php echo $i++;?></td>
                                               <td><?php echo h($EmpQua['EmployeeQualification']['institution']);?></td>
                                               <td><?php echo (!empty($EmpQua['EmployeeQualification']['date_from'])) ? $EmpQua['EmployeeQualification']['date_from'] : '<span class="label label-danger">nill</span>';?></td>
                                               <td><?php echo (!empty($EmpQua['EmployeeQualification']['date_to'])) ? $EmpQua['EmployeeQualification']['date_to'] : '<span class="label label-danger">nill</span>';?></td>
                                               <td><?php echo h($EmpQua['EmployeeQualification']['qualification']);?></td>
                                               <td><?php echo (!empty($EmpQua['EmployeeQualification']['qualification_date'])) ? $EmpQua['EmployeeQualification']['qualification_date'] : '<span class="label label-danger">nill</span>';?></td>
                                            </tr>
                                        <?php endforeach; ?>
                                     </tbody>
                                     <tfoot>
                                         <tr>
                                            <th>#</th>
                                            <th>Institution Name</th>
                                            <th>Date From</th>
                                            <th>Date To</th>
                                            <th>Obtained</th>
                                            <th>Date</th>
                                        </tr>
                                     </tfoot>
                                </table>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        <?php endif;?>
    </div>
</div>
<?php
    //on click of View Staff Record link... activate the link
    echo $this->Js->buffer('
        setTabActive("[href=\"'.DOMAIN_NAME.'/employees/\"]", 0);
    ');
?>