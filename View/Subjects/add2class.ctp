<?php echo $this->Html->script("../app/jquery/custom.subject.js", FALSE);?>
<?php $term_id = ClassRegistry::init('AcademicTerm'); ?>
<div class="col-md-12">
    <div class="panel">
        <!-- Info Boxes -->
        <!--div class="row">
            <div class="col-md-12">
                <div class="info-box  bg-info  text-white">
                    <div class="info-icon bg-info-dark">
                        <i class="fa fa-list-alt fa-4x"></i>
                    </div> 
                    <div class="info-details">
                        <h4>Manage and View Subjects Assigned to a Class Room</h4>
                    </div> 
                </div>
            </div>
        </div>
        <!-- / Info Boxes -->
        <div class="panel-heading text-primary">
            <h3 class="panel-title">                
               <i class="fa fa-align-center"></i>
               Management of Subjects in a Class Room <label class="label label-primary">Manage and View Subjects Assigned to a Class Room</label>
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
                            <a href="<?php echo DOMAIN_NAME ?>/subjects/add2class#assign2class" data-toggle="tab"><b><i class="fa fa-plus-square"></i> Assign to a Class</b></a>
                        </li>
                        <li>
                            <a href="<?php echo DOMAIN_NAME ?>/subjects/add2class#assign2teachers" data-toggle="tab"><b><i class="fa fa-eye"></i> View / <i class="fa fa-plus-circle"></i> Assign To Teachers</b></a>
                        </li>
                        <li>
                            <a href="<?php echo DOMAIN_NAME ?>/subjects/add2class#adjust_subjects_assign" data-toggle="tab">
                                <b><i class="fa fa-edit"></i> Modify Subjects /</b>
                                <b><i class="fa fa-ticket"></i> Manage Students</b>
                            </a>
                        </li>
                    </ul>
                    <div id="myTabContent" class="tab-content">
                        <div class="tab-pane fade in active" id="assign2class"><br>
                            <div class="col-md-7">
                                <div class="panel panel-cascade">
                                    <div class="panel-body">
                                        <div class="panel panel-default">
                                            <div class="panel-heading">Assign Subjects To Class Levels or Classrooms</div>
                                            <div class="panel-body">
                                                <?php 
                                                    //Creates The Form
                                                    echo $this->Form->create('SubjectClasslevel', array(
                                                            'action' => 'search',
                                                            'class' => 'form-horizontal',
                                                            'id' => 'assign_subject_form'
                                                        )
                                                    );     
                                                ?>
                                                    <div class="form-group">
                                                        <label for="subject_group_id" class="col-sm-4 control-label">Subject Groups</label>
                                                        <div class="col-sm-8">
                                                            <?php 
                                                                echo $this->Form->input('subject_group_id', array(
                                                                        'div' => false,
                                                                        'label' => false,
                                                                        'class' => 'form-control',
                                                                        'id' => 'subject_group_id',
                                                                         'required' => "required",
                                                                        'options' => $SubjectGroups,
                                                                        'empty' => '(Select Subject Group)'
                                                                    )
                                                                ); 
                                                            ?>
                                                        </div>
                                                    </div>
                                                    <div class="form-group">
                                                        <label for="subject_id" class="col-sm-4 control-label">Subject Names</label>
                                                        <div class="col-sm-8">
                                                            <select class="form-control" name="data[SubjectClasslevel][subject_id]" id="subject_id" required="required">
                                                                <option value="">  (Select Subject)  </option>

                                                            </select>
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
                                                            <select class="form-control" name="data[SubjectClasslevel][class_id]" id="class_id">
                                                                <option value="">  (Select Class Room)  </option>

                                                            </select>
                                                        </div>
                                                    </div>
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
                                                        <label for="academic_term_id" class="col-sm-4 control-label">Academic Terms</label>
                                                        <div class="col-sm-8">
                                                            <select class="form-control" name="data[SubjectClasslevel][academic_term_id]" id="academic_term_id" required="required">
                                                                <option value="<?php echo $term_id->getCurrentTermID();?>"><?php echo $term_id->getCurrentTermName();?></option>

                                                            </select>
                                                        </div>
                                                    </div>
                                                    <div class="form-group">
                                                        <div class="col-sm-offset-2 col-sm-10">
                                                            <button type="submit" class="btn btn-info">Assign Subject</button>
                                                        </div>
                                                    </div>
                                                </form>					
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                            <div class="col-md-5" id="msg_box2">     </div>
                        </div>
                        <div class="tab-pane fade in" id="assign2teachers"><br>
                            <div class="col-md-7">
                                <div class="panel panel-cascade">
                                    <div class="panel-body">
                                        <div class="panel panel-default">
                                            <div class="panel-heading"><i class="fa fa-search fa-1x"></i> Search Subjects Assigned To Teachers</div>                                            
                                            <div class="panel-body">
                                                <?php 
                                                    //Creates The Form
                                                    echo $this->Form->create('SubjectClasslevel', array(
                                                            'action' => 'search',
                                                            'class' => 'form-horizontal',
                                                            'id' => 'search_subject_form'
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
                                                            <select class="form-control" name="data[SubjectClasslevel][academic_term_id_all]" id="academic_term_id_all" required="required">
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
                                                                         'required' => "required",
                                                                        'options' => $Classlevels,
                                                                        'empty' => '(Select Classlevel)'
                                                                    )
                                                                ); 
                                                            ?>
                                                        </div>
                                                    </div>
                                                    <div class="form-group">
                                                        <label for="class_id_all" class="col-sm-4 control-label">Class Rooms</label>
                                                        <div class="col-sm-8">
                                                            <select class="form-control" name="data[SubjectClasslevel][class_id_all]" id="class_id_all">
                                                                <option value="">  (Select Class Room)  </option>

                                                            </select>
                                                        </div>
                                                    </div>
                                                    <div class="form-group">
                                                        <div class="col-sm-8">
                                                            <?php 
                                                                echo $this->Form->input('employee_names', array(
                                                                        'div' => false,
                                                                        'label' => false,
                                                                        'class' => 'form-control',
                                                                        'id' => 'employee_names',
                                                                        'options' => $Employees
                                                                    )
                                                                ); 
                                                            ?>
                                                        </div>
                                                    </div>
                                                    <div class="form-group">                                                
                                                        <div class="col-sm-offset-2 col-sm-10">
                                                            <button type="submit" class="btn btn-info">Search Subject</button>
                                                        </div>
                                                    </div>
                                                </form>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                            <div class="col-md-5" id="msg_box"> </div>
                            <div class="col-md-12">
                                <div style="overflow-x: scroll" class="panel-body">
                                    <table  class="table table-bordered table-hover table-striped display" id="subjects_table_div_all" >
                                        
                                    </table>
                                </div> 
                            </div>                            
                        </div><!-- /panel body -->                        
                        <div class="tab-pane fade" id="adjust_subjects_assign"><br>
                            <div class="col-md-8">
                                <div class="panel panel-cascade">
                                    <div class="panel-body">
                                        <div class="panel panel-default">
                                            <div class="panel-heading"><i class="fa fa-search fa-1x"></i> Modify Subjects Assigned To Classrooms or Manage Subjects Registered to Students</div>
                                            <div class="panel-body">
                                                <?php 
                                                    //Creates The Form
                                                    echo $this->Form->create('SubjectClasslevel', array(
                                                            'action' => 'search',
                                                            'class' => 'form-horizontal',
                                                            'id' => 'modify_subject_search_form'
                                                        )
                                                    );     
                                                ?>
                                                    <div class="form-group">
                                                        <label for="classlevel_search_id" class="col-sm-4 control-label">Class Levels</label>
                                                        <div class="col-sm-8">
                                                            <?php 
                                                                echo $this->Form->input('classlevel_search_id', array(
                                                                        'div' => false,
                                                                        'label' => false,
                                                                        'class' => 'form-control',
                                                                        'id' => 'classlevel_search_id',
                                                                         'required' => "required",
                                                                        'options' => $Classlevels,
                                                                        'empty' => '(Select Classlevel)'
                                                                    )
                                                                ); 
                                                            ?>
                                                        </div>
                                                    </div>                                                
                                                    <div class="form-group">
                                                        <label for="academic_year_search_id" class="col-sm-4 control-label">Academic Years</label>
                                                        <div class="col-sm-8">
                                                            <?php 
                                                                echo $this->Form->input('academic_year_search_id', array(
                                                                        'div' => false,
                                                                        'label' => false,
                                                                        'class' => 'form-control',
                                                                        'id' => 'academic_year_search_id',
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
                                                        <label for="academic_term_search_id" class="col-sm-4 control-label">Academic Terms</label>
                                                        <div class="col-sm-8">
                                                            <select class="form-control" name="data[SubjectClasslevel][academic_term_search_id]" id="academic_term_search_id" required="required">
                                                                <option value="<?php echo $term_id->getCurrentTermID();?>"><?php echo $term_id->getCurrentTermName();?></option>

                                                            </select>
                                                        </div>
                                                    </div>
                                                    <div class="form-group">
                                                        <div class="col-sm-offset-2 col-sm-10">
                                                            <button type="submit" class="btn btn-info">Search Subject</button>
                                                        </div>
                                                    </div>
                                                </form>					
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                            <div class="col-md-4" id="msg_box3">     </div>
                            <div class="col-md-12">
                                <div style="overflow-x: scroll"  class="panel-body">
                                    <table class="table table-bordered table-hover table-striped display" id="modify_subjects_table_div" >
                                        
                                    </table>
                                </div> 
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>	
    <!-- Model for confirming the subject assignment to classlevel or classroom -->
    <div id="confirm_subject_modal" class="modal fade" tabindex="-1" data-width="400" style="display: none;">
       <div class="modal-header">
           <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
           <div class="modal-title alert alert-info">Confirming Subject Assignment</div>
       </div>
        <form action="#" id="confirm_subject_form" method="post">
            <div class="modal-body">
                <div class="row">
                    <div class="col-md-12" id="confirm_output"></div>
                </div>
                <div class="row">
                    <div class="col-md-12">
                        <p style="color: orangered">
                            Are You Really Sure You Want To Assign This Subject To The Classlevel or Classroom
                            <i class="fa fa-warning fa-1x"></i>
                            <i class="fa fa-warning fa-1x"></i>
                            <i class="fa fa-warning fa-1x"></i>
                        </p>
                    </div>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" data-dismiss="modal" class="btn btn-default">Close</button>
                <button type="submit" class="btn btn-primary">Yes Confirm</button>
            </div>
            <div class="col-md-12" id="msg_box_modal">     </div>
        </form>
   </div><!-- /Modal Form Confirmation of subject-->
    <!-- Model for modifying subjects assigned to classrooms-->
    <div id="modify_subject_assign_modal" class="modal fade" tabindex="-1" data-width="500" style="display: none;">
       <div class="modal-header">
           <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
            <div class="modal-title alert alert-info">Modification of Subjects Assigned to a Class Level or Class Room</div>
       </div>
        <div class="panel-body">
            <?php 
                //Creates The Form
                echo $this->Form->create('ModifySubjectClasslevel', array(
                        'action' => 'search',
                        'class' => 'form-horizontal',
                        'id' => 'modify_subject_form'
                    )
                );     
            ?>
                <div class="form-group">
                    <label for="classlevel_id" class="col-sm-4 control-label">Subject Groups</label>
                    <div class="col-sm-8">
                        <?php 
                            echo $this->Form->input('subject_group_modify_id', array(
                                    'div' => false,
                                    'label' => false,
                                    'class' => 'form-control',
                                    'id' => 'subject_group_modify_id',
                                    'options' => $SubjectGroups,
                                    'empty' => '(Select Subject Group)'
                                )
                            ); 
                        ?>
                    </div>
                </div>
                <div class="form-group">
                    <label for="subject_modify_id" class="col-sm-4 control-label">Subject Names</label>
                    <div class="col-sm-8">
                        <select class="form-control" name="data[ModifySubjectClasslevel][subject_modify_id]" id="subject_modify_id" required="required">
                            <option value="">  (Select Subject)  </option>

                        </select>
                    </div>
                </div>
                <div class="form-group">
                    <label for="classlevel_modify_id" class="col-sm-4 control-label">Class Levels</label>
                    <div class="col-sm-8">
                        <?php 
                            echo $this->Form->input('classlevel_modify_id', array(
                                    'div' => false,
                                    'label' => false,
                                    'class' => 'form-control',
                                    'id' => 'classlevel_modify_id',
                                     'required' => "required",
                                    'options' => $Classlevels,
                                    'empty' => '(Select Classlevel)'
                                )
                            ); 
                        ?>
                    </div>
                </div>
                <div class="form-group">
                    <label for="class_modify_id" class="col-sm-4 control-label">Class Rooms</label>
                    <div class="col-sm-8">
                        <select class="form-control" name="data[ModifySubjectClasslevel][class_modify_id]" id="class_modify_id">
                            <option value="">  (Select Class Room)  </option>

                        </select>
                    </div>
                </div>
                <div class="form-group">
                    <label for="academic_year_modify_id" class="col-sm-4 control-label">Academic Years</label>
                    <div class="col-sm-8">
                        <?php 
                            echo $this->Form->input('academic_year_modify_id', array(
                                    'div' => false,
                                    'label' => false,
                                    'class' => 'form-control',
                                    'id' => 'academic_year_modify_id',
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
                    <label for="academic_term_modify_id" class="col-sm-4 control-label">Academic Terms</label>
                    <div class="col-sm-8">
                        <select class="form-control" name="data[ModifySubjectClasslevel][academic_term_modify_id]" id="academic_term_modify_id" required="required">
                            <option value="<?php echo $term_id->getCurrentTermID();?>"><?php echo $term_id->getCurrentTermName();?></option>

                        </select>
                    </div>
                </div>
                <div class="form-group">
                    <div class="col-sm-offset-2 col-sm-10">
                        <button type="button" data-dismiss="modal" class="btn btn-default">Close</button>
                        <input type="hidden" class="input-small" id="subject_classlevel_modify_id" name="data[ModifySubjectClasslevel][subject_classlevel_modify_id]">
                        <button type="submit" class="btn btn-info">Assign Subject</button>
                    </div>
                </div>
                <div class="col-md-12" id="msg_box2_modal">     </div>
            </form>					
        </div>
   </div><!--/ Modal Modifying Subjects Assigned-->
   <!-- Modal For Managing Subjects Offered by Students in a class level or class room-->
    <div id="manage_students_modal" class="modal fade" tabindex="-1" data-width="700" style="display: none;">
        <div class="modal-header">
           <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
           <div class="modal-title alert alert-info" id="msg_box3_modal"></div>
        </div>
        <div class="modal-body">
            <div class="row">
                <div class="col-md-12" style="overflow-x:scroll;" >
                    <table class="table table-bordered table-hover table-striped">
                        <tr>
                            <td><label>Students Not Registered || <span id="available_span"></span></label></td>
                            <td></td>
                            <td><label>List of Students Registered || <span id="assign_span"></span></label></td>
                        </tr>
                        <tr>
                            <td>
                                <select style="width:280px;" size="10" multiple class="form-control" id="AvailableLB"></select>
                            </td> 
                            <td align="center"><br>
                                <button title="Move All From Left To Right" class="btn btn-xs btn-success" type="button" id="student_RightAllButton">
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
                                </button>
                            </td> 
                            <td align="center" colspan="2">
                                <select style="width:280px;"size="10" multiple class="form-control" id="LinkedLB"></select>
                            </td>
                        </tr>
                        <tr>
                            <td>
                                <button type="button" data-dismiss="modal" class="btn btn-default">Close</button>
                                <button type="button" id="manage_student_btn" class="btn btn-sm btn-success">Update Students</button>
                                <input type="hidden" id="manage_student_hidden">
                            </td>
                        </tr>
                    </table>
                </div>
            </div>
        </div>      
    </div><!-- /Modal For Managing Subjects Offered by Students-->
    <!-- Model for Deleting the subject assignment to classlevel or classroom -->
    <div id="delete_subject_modal" class="modal fade" tabindex="-1" data-width="400" style="display: none;">
        <div class="modal-header">
            <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
            <div class="modal-title alert alert-info">Deleting Subject Assignment</div>
        </div>
        <form action="#" id="delete_subject_form" method="post">
            <div class="modal-body">
                <div class="row">
                    <div class="col-md-12" id="delete_output"></div>
                </div>
                <div class="row">
                    <div class="col-md-12">
                        <p style="color: red">
                            Are You Really Sure You Want To Delete This Subject Assigned To The Classlevel or Classroom
                            <i class="fa fa-warning fa-2x"></i>
                            <i class="fa fa-warning fa-2x"></i>
                            <i class="fa fa-warning fa-2x"></i>
                        </p>
                    </div>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" data-dismiss="modal" class="btn btn-default">Close</button>
                <button type="submit" name="delete_subject_button" id="delete_subject_button" class="btn btn-primary">Yes Confirm</button>
            </div>
            <div class="col-md-12" id="msg_box_modal4">     </div>
        </form>
    </div><!-- /Modal Form For deleting the subject assigned-->
</div>
<?php
    // OnChange Of Subject Groups Get Subjects
//    $this->Utility->getDependentListBox('#subject_group_id', '#subject_id', 'subjects', 'ajax_get_subjects', 'SubjectClasslevel');
//    $this->Utility->getDependentListBox('#subject_group_modify_id', '#subject_modify_id', 'subjects', 'ajax_get_subjects', 'ModifySubjectClasslevel');
//    // OnChange Of Classlevel Get Class Room
//    $this->Utility->getDependentListBox('#classlevel_id', '#class_id', 'classrooms', 'ajax_get_classes', 'SubjectClasslevel');
//    $this->Utility->getDependentListBox('#classlevel_id_all', '#class_id_all', 'classrooms', 'ajax_get_classes', 'SubjectClasslevel');
//    $this->Utility->getDependentListBox('#classlevel_modify_id', '#class_modify_id', 'classrooms', 'ajax_get_classes', 'ModifySubjectClasslevel');
//
//    // OnChange of Academic Year Get Academic Term
//    $this->Utility->getDependentListBox('#academic_year_id', '#academic_term_id', 'academic_terms', 'ajax_get_terms', 'SubjectClasslevel');
//    $this->Utility->getDependentListBox('#academic_year_id_all', '#academic_term_id_all', 'academic_terms', 'ajax_get_terms', 'SubjectClasslevel');
//    $this->Utility->getDependentListBox('#academic_year_search_id', '#academic_term_search_id', 'academic_terms', 'ajax_get_terms', 'SubjectClasslevel');
//    $this->Utility->getDependentListBox('#academic_year_modify_id', '#academic_term_modify_id', 'academic_terms', 'ajax_get_terms', 'ModifySubjectClasslevel');
?>

<?php
    //on click of Manage Sponsors Record link... activate the link
    echo $this->Js->buffer('
        setTabActive("[href=\"'.DOMAIN_NAME.'/subjects/add2class#assign2class\"]", 1);
    ');
?>