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
                            <a href="<?php echo DOMAIN_NAME ?>/subjects/add2class#assign2class" data-toggle="tab"><b><i class="fa fa-plus-square"></i> Assign to a Class Room</b></a>
                        </li>
                        <li>
                            <a href="<?php echo DOMAIN_NAME ?>/subjects/add2class#assign2classlevel" data-toggle="tab"><b><i class="fa fa-ticket"></i> Assign to a Class Level</b></a>
                        </li>
                        <li>
                            <a href="<?php echo DOMAIN_NAME ?>/subjects/add2class#assign2teachers" data-toggle="tab"><b><i class="fa fa-plus-circle"></i> Assign To Teachers</b></a>
                        </li>
                        <li>
                            <a href="<?php echo DOMAIN_NAME ?>/subjects/add2class#adjust_subjects_assign" data-toggle="tab"><b><i class="fa fa-edit"></i> Manage Subjects / Students</b></a>
                        </li>
                    </ul>
                    <div id="myTabContent" class="tab-content">
                        <div class="tab-pane fade in active" id="assign2class"><br>
                            <div class="col-md-7">
                                <div class="panel panel-cascade">
                                    <div class="panel-body">
                                        <div class="panel panel-default">
                                            <div class="panel-heading">Assign Subjects To Classrooms Only</div>
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
                                                            <select class="form-control" name="data[SubjectClasslevel][class_id]" id="class_id" required="required">
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
                        <div class="tab-pane fade in" id="assign2classlevel"><br>
                            <div class="col-md-7">
                                <div class="panel panel-cascade">
                                    <div class="panel-body">
                                        <div class="panel panel-default">
                                            <div class="panel-heading">Assign Subjects To Classlevels Only</div>
                                            <div class="panel-body">
                                                <?php
                                                    //Creates The Form
                                                    echo $this->Form->create('SubjectAssignLevel', array(
                                                            'action' => 'search',
                                                            'class' => 'form-horizontal',
                                                            'id' => 'assign_subjectlevel_form'
                                                        )
                                                    );
                                                ?>
                                                <div class="form-group">
                                                    <label for="classlevel_id_level" class="col-sm-4 control-label">Class Levels</label>
                                                    <div class="col-sm-8">
                                                        <?php
                                                        echo $this->Form->input('classlevel_id_level', array(
                                                                'div' => false,
                                                                'label' => false,
                                                                'class' => 'form-control',
                                                                'id' => 'classlevel_id_level',
                                                                'required' => "required",
                                                                'options' => $Classlevels,
                                                                'empty' => '(Select Classlevel)'
                                                            )
                                                        );
                                                        ?>
                                                    </div>
                                                </div>
                                                <div class="form-group">
                                                    <label for="academic_year_id_level" class="col-sm-4 control-label">Academic Years</label>
                                                    <div class="col-sm-8">
                                                        <?php
                                                        echo $this->Form->input('academic_year_id_level', array(
                                                                'div' => false,
                                                                'label' => false,
                                                                'class' => 'form-control',
                                                                'id' => 'academic_year_id_level',
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
                                                    <label for="academic_term_id_level" class="col-sm-4 control-label">Academic Terms</label>
                                                    <div class="col-sm-8">
                                                        <select class="form-control" name="data[SubjectAssignLevel][academic_term_id_level]" id="academic_term_id_level" required="required">
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
                            <div class="col-md-5" id="msg_box1">     </div>
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
                                                        <label for="subject_search_id" class="col-sm-4 control-label">Subjects</label>
                                                        <div class="col-sm-8">
                                                            <?php
                                                                echo $this->Form->input('subject_search_id', array(
                                                                        'div' => false,
                                                                        'label' => false,
                                                                        'class' => 'form-control',
                                                                        'id' => 'subject_search_id',
                                                                        'options' => $Subjects,
                                                                        'empty' => '(Select Subject)'
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
    <!-- Modal For Assigning Subjects To Classroom-->
    <div id="assign_subject_modal_1" class="modal fade" tabindex="-1" data-width="700" style="display: none;">
        <div class="modal-header">
            <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
            <div class="modal-title alert alert-info" id="msg_box_modal_1"></div>
        </div>
        <div class="modal-body">
            <div class="row">
                <div class="col-md-12" style="overflow-x:scroll;" >
                    <?php
                        //Creates The Form
                        echo $this->Form->create('Subject', array(
                                'action' => 'assign',
                                'class' => 'form-horizontal',
                                'id' => 'confirm_subject_form'
                            )
                        );
                    ?>
                        <table class="table table-bordered table-hover table-striped">
                            <tr>
                                <td><label>List of Subjects || <span id="available_span_1"></span></label></td>
                                <td></td>
                                <td><label>Subjects Assigned || <span id="assign_span_1"></span></label></td>
                            </tr>
                            <tr>
                                <td>
                                    <select style="width:280px;" size="10" multiple class="form-control" id="AvailableLB_1"></select>
                                </td>
                                <td align="center"><br>
                                    <button title="Move All From Left To Right" class="btn btn-xs btn-success" type="button" id="student_RightAllButton_1">
                                        <i class="fa fa-chevron-right"></i><i class="fa fa-chevron-right"></i>
                                    </button><br><br>
                                    <button title="Move Selected From Left To Right" class="btn btn-xs btn-success" type="button" id="student_RightButton_1">
                                        <i class="fa fa-chevron-right"></i>
                                    </button><br><br>
                                    <button title="Move Selected From Right To Left" class="btn btn-xs btn-success" type="button" id="student_LeftButton_1">
                                        <i class="fa fa-chevron-left"></i>
                                    </button><br><br>
                                    <button title="Move All From Right To Left" class="btn btn-xs btn-success" type="button" id="student_LeftAllButton_1">
                                        <i class="fa fa-chevron-left"></i><i class="fa fa-chevron-left"></i>
                                    </button>
                                </td>
                                <td align="center" colspan="2">
                                    <select style="width:280px;" size="10" multiple class="form-control" id="LinkedLB_1"></select>
                                </td>
                            </tr>
                            <tr>
                                <td>
                                    <button type="button" data-dismiss="modal" class="btn btn-default">Close</button>
                                    <button type="button" id="assign_subject_btn" class="btn btn-sm btn-success">Assign Subjects</button>
                                    <input type="hidden" name="data[Subject][subject_ids]" id="subject_ids_1">
                                    <input type="hidden" name="data[Subject][class_id]" id="class_id_1">
                                    <input type="hidden" name="data[Subject][classlevel_id]" id="classlevel_id_1">
                                    <input type="hidden" name="data[Subject][academic_term_id]" id="academic_term_id_1">
                                </td>
                            </tr>
                        </table>
                    </form>
                </div>
            </div>
        </div>
    </div><!-- /Modal For Assigning Subjects To Classroom-->
    <!-- Modal For Assigning Subjects To Classlevel-->
    <div id="assign_subject_modal_2" class="modal fade" tabindex="-1" data-width="700" style="display: none;">
        <div class="modal-header">
            <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
            <div class="modal-title alert alert-info" id="msg_box_modal_2"></div>
        </div>
        <div class="modal-body">
            <div class="row">
                <div class="col-md-12" style="overflow-x:scroll;" >
                    <?php
                        //Creates The Form
                        echo $this->Form->create('Subject', array(
                                'action' => 'assign_level',
                                'class' => 'form-horizontal',
                                'id' => 'subjectclasslevel_form'
                            )
                        );
                    ?>
                        <table class="table table-bordered table-hover table-striped">
                            <tr>
                                <td><label>List of Subjects || <span id="available_span_2"></span></label></td>
                                <td></td>
                                <td><label>Subjects Assigned || <span id="assign_span_2"></span></label></td>
                            </tr>
                            <tr>
                                <td>
                                    <select style="width:280px;" size="10" multiple class="form-control" id="AvailableLB_2"></select>
                                </td>
                                <td align="center"><br>
                                    <button title="Move All From Left To Right" class="btn btn-xs btn-success" type="button" id="student_RightAllButton_2">
                                        <i class="fa fa-chevron-right"></i><i class="fa fa-chevron-right"></i>
                                    </button><br><br>
                                    <button title="Move Selected From Left To Right" class="btn btn-xs btn-success" type="button" id="student_RightButton_2">
                                        <i class="fa fa-chevron-right"></i>
                                    </button><br><br>
                                    <button title="Move Selected From Right To Left" class="btn btn-xs btn-success" type="button" id="student_LeftButton_2">
                                        <i class="fa fa-chevron-left"></i>
                                    </button><br><br>
                                    <button title="Move All From Right To Left" class="btn btn-xs btn-success" type="button" id="student_LeftAllButton_2">
                                        <i class="fa fa-chevron-left"></i><i class="fa fa-chevron-left"></i>
                                    </button>
                                </td>
                                <td align="center" colspan="2">
                                    <select style="width:280px;" size="10" multiple class="form-control" id="LinkedLB_2"></select>
                                </td>
                            </tr>
                            <tr>
                                <td>
                                    <button type="button" data-dismiss="modal" class="btn btn-default">Close</button>
                                    <button type="button" id="assign_levelsubject_btn" class="btn btn-sm btn-success">Assign To Classlevel</button>
                                    <input type="hidden" name="data[Subject][subject_ids]" id="subject_ids_2">
                                    <input type="hidden" name="data[Subject][classlevel_id]" id="classlevel_id_2">
                                    <input type="hidden" name="data[Subject][academic_term_id]" id="academic_term_id_2">
                                </td>
                            </tr>
                        </table>
                    </form>
                </div>
            </div>
        </div>
    </div><!-- /Modal For Assigning Subjects To Classlevel-->
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
                                </button><br><br>
                                <button title="Move Selected From Left To Right" class="btn btn-xs btn-success" type="button" id="student_RightButton">
                                    <i class="fa fa-chevron-right"></i>
                                </button><br><br>
                                <button title="Move Selected From Right To Left" class="btn btn-xs btn-success" type="button" id="student_LeftButton">
                                    <i class="fa fa-chevron-left"></i>
                                </button><br><br>
                                <button title="Move All From Right To Left" class="btn btn-xs btn-success" type="button" id="student_LeftAllButton">
                                    <i class="fa fa-chevron-left"></i><i class="fa fa-chevron-left"></i>
                                </button>
                            </td> 
                            <td align="center" colspan="2">
                                <select style="width:280px;" size="10" multiple class="form-control" id="LinkedLB"></select>
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
    //on click of Manage Sponsors Record link... activate the link
    echo $this->Js->buffer('
        setTabActive("[href=\"'.DOMAIN_NAME.'/subjects/add2class#assign2class\"]", 1);
    ');
?>