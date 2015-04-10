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
               Managing Subjects Students Offers in a Class Room <label class="label label-primary">View Subjects Scores in a Class Room</label>
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
                            <a href="<?php echo DOMAIN_NAME ?>/subjects/staff#manage" data-toggle="tab"><b><i class="fa fa-ticket"></i> Manage Students</b></a>
                        </li>
                        <li>
                            <a href="<?php echo DOMAIN_NAME ?>/subjects/staff#view" data-toggle="tab"><b><i class="fa fa-eye-slash"></i> View Scores</b></a>
                        </li>
                    </ul>
                    <div id="myTabContent" class="tab-content">
                        <div class="tab-pane fade in active" id="manage"><br>
                            <div class="col-md-7">
                                <div class="panel panel-cascade">
                                    <div class="panel-body">
                                        <div class="panel panel-default">
                                            <div class="panel-heading"><i class="fa fa-search fa-1x"></i> Manage Subjects Registered to Students</div>
                                            <div class="panel-body">
                                                <?php
                                                //Creates The Form
                                                echo $this->Form->create('SubjectClasslevel', array(
                                                        'action' => 'search',
                                                        'class' => 'form-horizontal',
                                                        'id' => 'manage_student_subject_form'
                                                    )
                                                );
                                                ?>
                                                <div class="form-group">
                                                    <label for="classlevel_subject_id" class="col-sm-4 control-label">Class Levels</label>
                                                    <div class="col-sm-8">
                                                        <?php
                                                        echo $this->Form->input('classlevel_subject_id', array(
                                                                'div' => false,
                                                                'label' => false,
                                                                'class' => 'form-control',
                                                                'id' => 'classlevel_subject_id',
                                                                'required' => "required",
                                                                'options' => $Classlevels,
                                                                'empty' => '(Select Classlevel)'
                                                            )
                                                        );
                                                        ?>
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
                                                        <button type="submit" class="btn btn-info">Search Subject</button>
                                                    </div>
                                                </div>
                                                </form>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                            <div class="col-md-4" id="msg_box">     </div>
                            <div class="col-md-12">
                                <div style="overflow-x: scroll"  class="panel-body">
                                    <table class="table table-bordered table-hover table-striped display" id="manage_student_subject_table" >

                                    </table>
                                </div>
                            </div>
                        </div>
                        <div class="tab-pane fade in" id="view"><br>
                            <div class="col-md-7">
                                <div class="panel panel-cascade">
                                    <div class="panel-body">
                                        <div class="panel panel-default">
                                            <div class="panel-heading">Search for Students in a Classrooms</div>
                                            <div class="panel-body">
                                                <?php
                                                //Creates The Form
                                                echo $this->Form->create('SubjectStudentView', array(
                                                        'action' => 'search',
                                                        'class' => 'form-horizontal',
                                                        'id' => 'search_subject_view_form'
                                                    )
                                                );
                                                ?>
                                                <div class="form-group">
                                                    <label for="subject_view_group_id" class="col-sm-4 control-label">Subject Groups</label>
                                                    <div class="col-sm-8">
                                                        <?php
                                                        echo $this->Form->input('subject_view_group_id', array(
                                                                'div' => false,
                                                                'label' => false,
                                                                'class' => 'form-control',
                                                                'id' => 'subject_view_group_id',
                                                                'required' => "required",
                                                                'options' => $SubjectGroups,
                                                                'empty' => '(Select Subject Group)'
                                                            )
                                                        );
                                                        ?>
                                                    </div>
                                                </div>
                                                <div class="form-group">
                                                    <label for="subject_view_id" class="col-sm-4 control-label">Subject Names</label>
                                                    <div class="col-sm-8">
                                                        <select class="form-control" name="data[SubjectStudentView][subject_view_id]" id="subject_view_id" required="required">
                                                            <option value="">  (Select Subject)  </option>

                                                        </select>
                                                    </div>
                                                </div>
                                                <div class="form-group">
                                                    <label for="classlevel_view_id" class="col-sm-4 control-label">Class Levels</label>
                                                    <div class="col-sm-8">
                                                        <?php
                                                        echo $this->Form->input('classlevel_view_id', array(
                                                                'div' => false,
                                                                'label' => false,
                                                                'class' => 'form-control',
                                                                'id' => 'classlevel_view_id',
                                                                'required' => "required",
                                                                'options' => $Classlevels,
                                                                'empty' => '(Select Classlevel)'
                                                            )
                                                        );
                                                        ?>
                                                    </div>
                                                </div>
                                                <div class="form-group">
                                                    <label for="class_view_id" class="col-sm-4 control-label">Class Rooms</label>
                                                    <div class="col-sm-8">
                                                        <select class="form-control" name="data[SubjectStudentView][class_view_id]" id="class_view_id">
                                                            <option value="">  (Select Class Room)  </option>

                                                        </select>
                                                    </div>
                                                </div>
                                                <div class="form-group">
                                                    <label for="academic_view_year_id" class="col-sm-4 control-label">Academic Years</label>
                                                    <div class="col-sm-8">
                                                        <?php
                                                        echo $this->Form->input('academic_view_year_id', array(
                                                                'div' => false,
                                                                'label' => false,
                                                                'class' => 'form-control',
                                                                'id' => 'academic_view_year_id',
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
                                                    <label for="academic_view_term_id" class="col-sm-4 control-label">Academic Terms</label>
                                                    <div class="col-sm-8">
                                                        <select class="form-control" name="data[SubjectStudentView][academic_view_term_id]" id="academic_view_term_id" required="required">
                                                            <option value="<?php echo $term_id->getCurrentTermID();?>"><?php echo $term_id->getCurrentTermName();?></option>

                                                        </select>
                                                    </div>
                                                </div><br><br>
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
                            <div class="col-md-4 col-md-offset-1" id="msg_box">     </div>
                            <div class="col-md-10 col-md-offset-1">
                                <div style="overflow-x: scroll" class="panel-body">
                                    <table  class="table table-bordered table-hover table-striped display" id="subjects_view_table" >

                                    </table>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
    <!-- Modal For Managing Subjects Offered by Students in a class level or class room-->
    <div id="manage_students_modal" class="modal fade" tabindex="-1" data-width="700" style="display: none;">
        <div class="modal-header">
            <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
            <div class="modal-title alert alert-info" id="msg_box_modal"></div>
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
                                <button type="button" id="manage_student_sub_btn" class="btn btn-sm btn-success">Update Students</button>
                                <input type="hidden" id="manage_student_sub_hidden">
                                <input type="hidden" id="manage_class_sub_hidden">
                            </td>
                        </tr>
                    </table>
                </div>
            </div>
        </div>
    </div><!-- /Modal For Managing Subjects Offered by Students-->
</div>
<?php
    //on click of Manage Sponsors Record link... activate the link
    echo $this->Js->buffer('
        setTabActive("[href=\"'.DOMAIN_NAME.'/subjects/add2class#assign2class\"]", 1);
    ');
?>