<?php echo $this->Html->script("../app/jquery/custom.message.js", FALSE);?>
<?php echo $this->Html->script("../app/js/bootstrap-datatables.js", FALSE);?>
<?php echo $this->Html->script("../app/js/dataTables-custom.js", FALSE);?>
<?php $term_id = ClassRegistry::init('AcademicTerm'); ?>
<?php 
    App::uses('Encryption', 'Utility'); 
    $Encryption = new Encryption();
    
    //echo '234' . substr ('09023948573', 1); 
?>
<div class="col-md-12">
    <div class="panel">
        <!-- Info Boxes -->
        <div class="row">
            <div class="col-md-12">
                <div class="info-box  bg-info  text-white">
                    <div class="info-icon bg-info-dark">
                        <i class="fa fa-envelope fa-4x"></i>
                    </div> 
                    <div class="info-details">
                        <h4>Manage S.M.S and e-mails Sending</h4>
                    </div> 
                </div>
            </div>
        </div>
        <!-- / Info Boxes -->
        <div class="panel-heading text-primary">
            <h3 class="panel-title">                
               <i class="fa fa-envelope-o"></i>
               Message Management Center
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
                    <ul id="myTab" class="nav nav-tabs">
                        <li class="active">
                            <a href="<?php echo DOMAIN_NAME ?>/messages/index#sponsors" data-toggle="tab"><b><i class="fa fa-user"></i> Individual / <i class="fa fa-group"></i> Group Sponsors</b></a>                            
                        </li>
                        <li>
                            <a href="<?php echo DOMAIN_NAME ?>/messages/index#employees" data-toggle="tab"><b><i class="fa fa-male"></i> Individual / <i class="fa fa-group"></i> Group Employees</b></a>
                        </li>
                    </ul>
                    <div id="myTabContent" class="tab-content"> 
                        <div class="tab-pane fade in active" id="sponsors"><br> <!-- setupExam -->
                            <div class="col-md-7">
                                <div class="panel panel-cascade">
                                    <div class="panel-body">
                                        <div class="panel panel-default">
                                            <div class="panel-heading"><i class="fa fa-search fa-1x"></i> Search for Sponsors using their Ward(s)</div>                                            
                                            <div class="panel-body">
                                                <?php 
                                                    //Creates The Form
                                                    echo $this->Form->create('SearchForm', array(
                                                            'class' => 'form-horizontal',
                                                            'id' => 'search_sponsor_form'
                                                        )
                                                    );     
                                                ?>
                                                    <div class="form-group">
                                                        <label for="academic_year_id" class="col-sm-4 control-label">Academic Years</label>
                                                        <div class="col-sm-8">
                                                            <?php 
                                                                echo $this->Form->input('academic_year_id', array(
                                                                        'div' => false,
                                                                        'label' => false,
                                                                        'class' => 'form-control',
                                                                        'id' => 'academic_year_id',
                                                                        'required' => "required",
                                                                        'selected' => $term_id->getCurrentYearID(),
                                                                        'options' => $AcademicYears,
                                                                        'empty' => '(Select Academic Year)'
                                                                    )
                                                                ); 
                                                            ?>
                                                        </div>
                                                    </div>
                                                    <div class="form-group">
                                                        <label for="classlevel_id" class="col-sm-4 control-label">Class Levels</label>
                                                        <div class="col-sm-8">
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
                                                        <label for="class_id" class="col-sm-4 control-label">Class Rooms</label>
                                                        <div class="col-sm-8">
                                                            <select class="form-control" name="data[SearchForm][class_id]" id="class_id">
                                                                <option value="">  (Select Class Room)  </option>

                                                            </select>
                                                        </div>
                                                    </div>  
                                                    <div class="form-group">
                                                        <div class="col-sm-offset-2 col-sm-10">
                                                            <button type="submit" class="btn btn-info">Search Sponsors</button>
                                                            <a target="__blank" href="<?php echo DOMAIN_NAME ?>/messages/send/<?php echo $Encryption->encode('all/spn_all'); ?>" class="btn btn-success">Message all Sponsors</a>
                                                        </div>
                                                    </div>
                                                </form>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                            <div class="col-md-5" id="msg_box"> </div>
                            <div class="col-md-8">
                                <table  class="table table-bordered table-hover table-striped display" id="search_sponsors_table" >
                                        
                                </table>
                                <div></div>
                            </div>                            
                        </div>
                        <div class="tab-pane fade in" id="employees"><br>
                            <div class="col-md-12">
                                <div class="panel panel-cascade">
                                    <div class="panel-body">
                                        <div class="panel panel-info">
                                            <div class="panel-heading panel-title  text-white">Employee's Table</div>
                                               <table  class="table table-bordered table-hover table-striped display" >
                                                   <?php if(!empty($employees)) :?>
                                                        <div class="col-sm-offset-4 col-sm-10"><br>
                                                           <button type="button" class="mark_btn_emp btn btn-success">Mark All</button>
                                                           <button type="button" class="msg_all_mark_emp btn btn-primary" value="emp">Message Marked Employees</button>
                                                           <span style="font-size: medium" class="label label-danger err"></span><br>
                                                       </div>
                                                      <thead>
                                                       <tr>
                                                        <th>#</th>
                                                        <th>ID</th>
                                                        <th>Title</th>
                                                        <th>Full Name</th>
                                                        <th>Email</th>
                                                        <th>Phone No.</th>
                                                        <th>Status</th>
                                                        <th>Send</th>
                                                        <th>Mark</th>
                                                      </tr>
                                                    </thead>
                                                    <tbody>
                                                        <?php $i=1; foreach ($employees as $employee): ?>
                                                       <tr class="gradeA">
                                                           <?php 
                                                             $encrypted_employee_id = $Encryption->encode($employee['Employee']['employee_id'] . '/emp');
                                                           ?>
                                                           <td><?php echo $i++;?></td>
                                                           <td><?php echo h($employee['Employee']['employee_no']); ?>&nbsp;</td>
                                                           <td><?php echo h($employee['Salutation']['salutation_abbr']); ?>&nbsp;</td>
                                                           <td><?php echo h($employee['Employee']['first_name']), ' ', h($employee['Employee']['other_name']); ?>&nbsp;</td>
                                                           <td><?php echo h($employee['Employee']['email']); ?>&nbsp;</td>
                                                           <td><?php echo h($employee['Employee']['mobile_number1']); ?>&nbsp;</td>
                                                           <td style="font-size: medium">
                                                               <?php 
                                                                 if(h($employee['Employee']['status_id']) === '1'){
                                                                     echo '<span class="label label-success"><i class="fa fa-check fa-1x"></i> '.$employee['Status']['status'].'</span>';
                                                                 }else{
                                                                     echo '<span class="label label-danger"><i class="fa fa-times fa-1x"></i> '.$employee['Status']['status'].'</span>';
                                                                 }
                                                              ?>
                                                           </td>
                                                           <td>
                                                                <button class="btn btn-warning btn-xs send_message_employee" value="<?php echo $employee['Employee']['employee_id']; ?>" data-toggle="modal" href="#message_modal">
                                                                    <i class="fa fa-envelope"></i> Send
                                                                </button>
                                                            </td>
                                                           <!--td><a target="__blank" href="<?php //echo DOMAIN_NAME ?>/messages/send/<?php //echo $encrypted_employee_id; ?>" class="btn btn-warning btn-xs"><i class="fa fa-envelope"></i> Send</a></td-->
                                                           <td><input type="checkbox" value="<?php echo $employee['Employee']['employee_id']?>" class="message_check_emp"></td>
                                                       </tr>
                                                       <?php endforeach; ?>

                                                      </tbody>
                                                      <tfoot>
                                                       <tr>
                                                         <th>#</th>
                                                         <th>ID</th>
                                                         <th>Title</th>
                                                         <th>Full Name</th>
                                                         <th>Email</th>
                                                         <th>Phone No.</th>
                                                         <th>Status</th>
                                                         <th>Send</th>
                                                         <th>Mark</th>
                                                      </tr>
                                                    </tfoot>
                                                  <?php endif; ?>  
                                               </table>
                                            <div class="form-group">
                                                <div class="col-sm-offset-2 col-sm-10"><br><br><br>
                                                    <button type="button" class="mark_btn_emp btn btn-success">Mark All</button>
                                                    <button type="button" class="msg_all_mark_emp btn btn-primary" value="emp">Message Marked Employees</button>
                                                    <span style="font-size: medium" class="label label-danger err"></span>
                                                </div>
                                            </div>
                                        </div>
                                    </div> <!-- /panel body --> 
                                </div>
                            </div>
                        </div><!-- Input subject Scores -->
                    </div>
                </div>
            </div>
        </div>
    </div>
    
    <!-- Modal for sending messages-->
    <div id="message_modal" class="modal fade" tabindex="-1" data-width="600" style="display: none;">
       <div class="modal-header">
           <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
           <h4 class="modal-title">Sending Message Form</h4>
       </div>
        <div class="panel panel-default">
            <div class="panel-heading bg-primary-dark text-white"><i class="fa fa-envelope-o fa-1x"></i> S.M.S / e-mail Message Form for Sponsors / Employees</div>                                            
            <div class="panel-body">
                <?php 
                    //Creates The Form
                    echo $this->Form->create('Send', array(
                            'class' => 'form-horizontal',
                            'id' => 'message_form'
                        )
                    );     
                ?>

                    <div class="form-group">
                        <label for="subject" class="col-lg-3 col-md-3 control-label">Message Subject</label>
                        <div class="col-lg-7 col-md-9">
                            <input type="text" class="form-control form-cascade-control input-small" name="data[Send][subject]" 
                                   id="subject" maxlength="11" placeholder="Message Subject" required="required">
                        </div>
                    </div>
                    <div class="form-group">
                        <label for="subject" class="col-lg-3 col-md-3 control-label">Sending Options</label>
                        <div class="col-lg-7 col-md-9">
                            <div class="radio">
                                <label><input type="radio" name="data[Send][option]" id="sms" value="1">S.M.S Only</label>
                            </div>
                            <div class="radio">
                                <label><input type="radio" name="data[Send][option]" id="sms_email" value="2" checked="checked">S.M.S and e-mail</label>
                            </div>
                        </div>
                    </div>
                    <div class="form-group">
                        <label for="message" class="col-lg-3 col-md-3 control-label">Message Body</label>
                        <div class="col-lg-7 col-md-9">
                            <textarea rows="7" class="form-control form-cascade-control input-small" name="data[Send][message]" 
                            id="message" placeholder="Message Body" required="required"></textarea>
                        </div>
                    </div>
                <div id="msg_box4"></div>
                    <div class="form-group">
                        <div class="col-sm-offset-2 col-sm-9">
                            <input type="text" name="data[Send][hidden_id]" id="hidden_id" value=""> 
                            <input type="text" name="data[Send][type]" id="type" value=""> 
                            <button type="submit" class="btn btn-success">Send Message</button>
                        </div>
                    </div>
                </form>
            </div>
        </div>
   </div>
    
</div>
