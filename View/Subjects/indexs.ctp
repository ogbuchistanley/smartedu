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
               Analysis of Subjects in a Class Room <label class="label label-primary">View Students Subject Scores in a Class Room</label>
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
                            <a href="<?php echo DOMAIN_NAME ?>/subjects/index#view" data-toggle="tab"><b><i class="fa fa-eye-slash"></i> View Scores</b></a>
                        </li>
                        <!--li>
                            <a href="<?php echo DOMAIN_NAME ?>/subjects/add2class#assign2teachers" data-toggle="tab"><b><i class="fa fa-eye"></i> View / <i class="fa fa-plus-circle"></i> Assign To Teachers</b></a>
                        </li-->
                    </ul>
                    <div id="myTabContent" class="tab-content">
                        <div class="tab-pane fade in active" id="view"><br>
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