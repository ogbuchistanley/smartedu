<?php echo $this->Html->script("../app/js/jquery-ui.js", FALSE);?>

<?php echo $this->Html->script("../app/jquery/custom.attend.js", FALSE);?>
<?php echo $this->Html->script("../app/js/bootstrap-datatables.js", FALSE);?>
<?php echo $this->Html->script("../app/js/dataTables-custom.js", FALSE);?>

<?php $term_id = ClassRegistry::init('AcademicTerm'); ?>

<div class="col-md-12">
    <div class="panel">
        <!-- Info Boxes -->
        <div class="row">
            <div class="col-md-12">
                <div class="info-box  bg-info  text-white">
                    <div class="info-icon bg-info-dark">
                        <i class="fa fa-check-square-o fa-4x"></i>
                    </div> 
                    <div class="info-details">
                        <h4>Manage and View Students Attendance</h4>
                    </div> 
                </div>
            </div>
        </div>
        <!-- / Info Boxes -->
        <div class="panel-heading text-primary">
            <h3 class="panel-title">                
               <i class="fa fa-check"></i>
               Students Class Room Attendance
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
                        <li class="active"><a href="<?php echo DOMAIN_NAME ?>/attends/index#take_attend" data-toggle="tab">
                            <b><i class="fa fa-check-square"></i> Take or Mark Student Attendance</b></a>
                        </li>
                        <li><a href="<?php echo DOMAIN_NAME ?>/attends/index#edit_attend" data-toggle="tab">
                            <b><i class="fa fa-eye"></i> View / <i class="fa fa-edit"></i> Edit Attendance</b></a>
                        </li>
                        <li><a href="<?php echo DOMAIN_NAME ?>/attends/index#summary" data-toggle="tab">
                            <b><i class="fa fa-gears"></i> Attendance Summary</b></a>
                        </li>
                    </ul>
                    <div id="myTabContent" class="tab-content">
                        <div class="tab-pane fade in active" id="take_attend"><br>
                            <div class="col-md-8">
                                <div class="panel-body">
                                    <div class="panel panel-info">
                                        <div class="panel-heading panel-title  text-white">Table Displaying List of Class Room(s) Assigned</div>
                                        <div style="overflow-x: scroll" class="panel-body">
                                            <table  class="table table-bordered table-hover table-striped display custom_tables">
                                                <?php if(!empty($ClassRooms['Classroom'])):?>
                                                <thead>
                                                 <tr>
                                                  <th>#</th>
                                                  <th>Class Name</th>
                                                  <th>Academic Term</th>
                                                  <th>Head Tutor</th>
                                                  <th>Action</th>
                                                </tr>
                                              </thead>
                                              <tbody>
                                                  <?php $i=1; foreach ($ClassRooms['Classroom'] as $ClassRoom): ?>
                                                 <tr class="gradeA">
                                                     <?php 
                                                        //$encrypted_user_id = $Encryption->encode($ClassRoom['class_id']);
                                                     ?>
                                                     <td><?php echo $i++; ?></td>
                                                     <td><?php echo h($ClassRoom['class_name']); ?>&nbsp;</td>
                                                     <td><?php echo $term_id->getCurrentTermName();//h($ClassRoom['academic_year']); ?>&nbsp;</td>
                                                     <td><?php echo h($ClassRoom['employee_name']); ?>&nbsp;</td>
                                                     <td>
                                                         <button value="<?php echo $ClassRoom['cls_yr_id']; ?>" class="btn btn-info btn-xs mark_attend_btn">
                                                        <i class="fa fa-check-square-o"></i> Mark</button>
                                                     </td>
                                                 </tr>
                                                 <?php endforeach; ?>
                                                </tbody>
                                                <tfoot>
                                                 <tr>
                                                  <th>#</th>
                                                  <th>Class Name</th>
                                                  <th>Academic Term</th>
                                                  <th>Head Tutor</th>
                                                  <th>Action</th>
                                                </tr>
                                              </tfoot>
                                              <?php else :?>
                                                <tr><th>No Class Has Been Assign to you Yet</th></tr>
                                              <?php endif;?>
                                            </table>
                                        </div> <!-- /panel body -->
                                    </div>
                                </div> <!-- /panel body -->  
                            </div>
                            <div class="col-md-4" id="msg_box">     </div>
                            <div class="col-md-9">
                                <div style="overflow-x: scroll"  class="hide" id="attend_table_div">
                                    <?php 
                                        //Creates The Form
                                        echo $this->Form->create('Attend', array(
                                                'class' => 'form-horizontal cascde-forms',
                                                'id' => 'attendance_form'
                                            )
                                        );     
                                    ?>
                                        <table class="table table-bordered table-hover table-striped">
                                            <tr>
                                                <th style="text-align: center" colspan="3"><label class="text-center">Class Room Attendance For <span id="caption_span"></span></label></th>
                                            </tr>
                                            <tr>
                                                <td><label>Marked Students Count || <span id="mark_span"></span></label></td>
                                                <td align="center">
                                                    <div class="checkbox col-md-6 col-md-offset-3"><label class="label label-primary"><input id="check_all" type="checkbox">Check / Un-Check All</label></div>
                                                </td>
                                                <td><label>Unmarked Students Count || <span id="unmark_span"></span></label></td>
                                            </tr>
                                            <tr>
                                                <td align="center">
                                                    <!--select style="width:290px;" size="15" multiple class="form-control" id="AvailableLB"></select-->
                                                    <div id="AvailableLB"></div>
                                                </td> 
                                                <td align="center">
                                                    <div class="form-group">
                                                        <div class="col-md-10 col-md-offset-1">
                                                            <input type="text" class="form-control form-cascade-control input-small" placeholder="Attendance Date" 
                                                             id="attend_date" name="data[Attend][attend_date]" value="<?php echo date('m/d/Y'); ?>" required="required"/>
                                                         </div>
                                                    </div><br><br><br><br><br><br><br>
                                                    <div class="form-group aligncenter">
                                                        <div class="col-md-8 col-md-offset-2">
                                                            <button type="submit" class="btn btn-sm btn-success">Submit Attendance</button>
                                                            <input type="hidden" name="data[Attend][student_ids]" id="student_ids">
                                                            <input type="hidden" name="data[Attend][class_id]" id="class_id">
                                                        </div>
                                                    </div>
                                                    <!--button title="Move All From Left To Right" class="btn btn-xs btn-success" type="button" id="student_RightAllButton">
                                                        <i class="fa fa-chevron-right"></i><i class="fa fa-chevron-right"></i>
                                                    </button></br></br>
                                                    <button title="Move Selected From Left To Right" class="btn btn-xs btn-success" type="button" id="student_RightButton">
                                                        <i class="fa fa-chevron-right"></i>
                                                    </button></br></br>
                                                    <button title="Move Selected From Right To Left" class="btn btn-xs btn-success" type="button" id="student_LeftButton">
                                                        <i class="fa fa-chevron-left"></i>
                                                    </button></br></br>
                                                    <button title="Move All From Right To Left" class="btn btn-xs btn-success" type="button" id="student_LeftAllButton">
                                                        <i class="fa fa-chevron-left"></i><i class="fa fa-chevron-left"></i>
                                                    </button-->
                                                </td> 
                                                <td align="center">
                                                    <div id="LinkedLB"></div>
                                                    <!--select style="width:290px;"size="15" multiple class="form-control" id="LinkedLB"></select-->
                                                </td>
                                            </tr>
                                        </table>
                                    </form>
                                </div>
                            </div><div class="col-md-3" id="msg_box_1">     </div>
                        </div>
                        <div class="tab-pane fade" id="edit_attend"><br>
                            <div class="col-md-8">
                                <div class="panel panel-cascade">
                                    <div class="panel-body">
                                        <div class="panel panel-default">
                                            <div class="panel-heading">Search For Attendance To View or Edit </div> 
                                            <div class="panel-body">
                                                <?php 
                                                    //Creates The Form
                                                    echo $this->Form->create('SearchAttend', array(
                                                            'row' => 'form',
                                                            'id' => 'search_attend_form'
                                                        )
                                                    );     
                                                ?>
                                                <div class="col-md-6">
                                                    <div class="form-group">
                                                        <label for="academic_year_id">Academic Year</label>
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
                                                    <div class="form-group">
                                                        <label for="academic_term_id">Academic Terms</label>
                                                        <select class="form-control" name="data[SearchAttend][academic_term_id]" id="academic_term_id" required="required">
                                                            <option value="<?php echo $term_id->getCurrentTermID();?>"><?php echo $term_id->getCurrentTermName();?></option>

                                                        </select>
                                                    </div>
                                                    <div class="form-group">
                                                        <label for="classlevel_id">Class Level</label>
                                                        <?php                                                         
                                                            echo $this->Form->input('classlevel_id', array(
                                                                    'div' => false,
                                                                    'label' => false,
                                                                    'class' => 'form-control',
                                                                    'id' => 'classlevel_id',
                                                                    'options' => $Classlevels,
                                                                    'empty' => '(Select Classlevel)'
                                                                )
                                                            ); 
                                                        ?>
                                                    </div>
                                                    <div class="form-group">
                                                        <div class="col-sm-offset-2 col-sm-10">
                                                            <button type="submit" class="btn btn-info">Search</button>
                                                        </div>
                                                    </div>
                                                </div>
                                                <div class="col-md-6">
                                                    <div class="form-group">
                                                        <label for="search_date">Date Taken</label>
                                                            <input type="text" class="form-control form-cascade-control input-small" placeholder="Attendance Date" 
                                                             id="search_date" name="data[SearchAttend][search_date]"/>
                                                    </div>
                                                    <div class="form-group">
                                                        <label for="date_from">Date From</label>
                                                        <input type="text" class="form-control form-cascade-control input-small" placeholder="Attendance Date From" 
                                                             id="date_from" name="data[SearchAttend][date_from]"/>
                                                    </div>
                                                    <div class="form-group">
                                                        <label for="date_to">Date To</label>
                                                        <input type="text" class="form-control form-cascade-control input-small" placeholder="Attendance Date To" 
                                                             id="date_to" name="data[SearchAttend][date_to]"/>
                                                    </div>                                                    
                                                </div>
                                                </form>					
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                            <div class="col-md-4" id="msg_box2">     </div>
                            <div class="col-md-10">
                                <div style="overflow-x: scroll" class="panel-body">
                                    <table  class="table table-bordered table-hover table-striped display" id="attend_search_table_div" >
                                        
                                    </table>
                                </div> 
                            </div>
                        </div>
                        <div class="tab-pane fade in" id="summary"><br>
                            <div class="col-md-6">
                                <div class="panel panel-cascade">
                                    <div class="panel-body">
                                        <div class="panel panel-default">
                                            <div class="panel-heading">Search For Attendance Taken</div> 
                                            <div class="panel-body">
                                                <?php 
                                                    //Creates The Form
                                                    echo $this->Form->create('SummaryAttend', array(
                                                            'class' => 'form-horizontal',
                                                            'id' => 'search_summary_form'
                                                        )
                                                    );     
                                                ?>
                                                    <div class="form-group">
                                                        <label for="academic_year_id_all" class="col-sm-4 control-label">Academic Years</label>
                                                        <div class="col-sm-8">
                                                            <?php 
                                                                echo $this->Form->input('academic_year_id_all', array(
                                                                        'div' => false,
                                                                        'label' => false,
                                                                        'class' => 'form-control',
                                                                        'id' => 'academic_year_id_all',
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
                                                        <label for="academic_term_id_all" class="col-sm-4 control-label">Academic Terms</label>
                                                        <div class="col-sm-8">
                                                            <select class="form-control" name="data[SummaryAttend][academic_term_id_all]" id="academic_term_id_all" required="required">
                                                                <option value="<?php echo $term_id->getCurrentTermID();?>"><?php echo $term_id->getCurrentTermName();?></option>

                                                            </select>
                                                        </div>
                                                    </div>
                                                    <div class="form-group">
                                                        <label for="classlevel_id_all" class="col-sm-4 control-label">Class Levels</label>
                                                        <div class="col-sm-8">
                                                            <?php 
                                                                echo $this->Form->input('classlevel_id_all', array(
                                                                        'div' => false,
                                                                        'label' => false,
                                                                        'class' => 'form-control',
                                                                        'id' => 'classlevel_id_all',
                                                                        'options' => $Classlevels,
                                                                        'empty' => '(Select Classlevel)'
                                                                    )
                                                                ); 
                                                            ?>
                                                        </div>
                                                    </div>
                                                    <div class="form-group">
                                                        <div class="col-sm-offset-2 col-sm-10">
                                                            <button type="submit" class="btn btn-info">Search</button>
                                                        </div>
                                                    </div>
                                                </form>					
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                            <div class="col-md-4" id="msg_box3">     </div>
                            <div class="col-md-8">
                                <div style="overflow-x: scroll" class="panel-body">
                                    <table  class="table table-bordered table-hover table-striped display" id="summary_table_div" >
                                        
                                    </table>
                                </div> 
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>	
</div>
<?php
    // OnChange Of Classlevel Get Class Room
    //$this->Utility->getDependentListBox('#classlevel_id', '#class_id', 'classrooms', 'ajax_get_classes', 'StudentsClass');
    
//    $this->Utility->getDependentListBox('#academic_year_id', '#academic_term_id', 'academic_terms', 'ajax_get_terms', 'SearchAttend');
//    $this->Utility->getDependentListBox('#academic_year_id_all', '#academic_term_id_all', 'academic_terms', 'ajax_get_terms', 'SummaryAttend');
//
?>

<?php
    //on click of Manage Students link... activate the link
    echo $this->Js->buffer('
        setTabActive("[href=\"'.DOMAIN_NAME.'/attends/index#take_attend\"]", 1);
    ');
?> 
 