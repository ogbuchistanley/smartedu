<?php echo $this->Html->script("../app/jquery/custom.exam.js", FALSE);?>
<?php $setup_exam = Configure::read('setup_exam'); ?>
<?php $term_id = ClassRegistry::init('AcademicTerm'); //echo date('Y-m-d h:m:s');?>
<?php $AcademicYear = ClassRegistry::init('AcademicYear'); //echo date('Y-m-d h:m:s');?>
<div class="col-md-12">
    <div class="panel">
        <!-- Info Boxes -->
        <!--div class="row">
            <div class="col-md-12">
                <div class="info-box  bg-info  text-white">
                    <div class="info-icon bg-info-dark">
                        <i class="fa fa-folder-open-o fa-4x"></i>
                    </div> 
                    <div class="info-details">
                        <h4>Manage and View Exams Assigned to a Subjects</h4>
                    </div> 
                </div>
            </div>
        </div>
        <!-- / Info Boxes -->
        <div class="panel-heading text-primary">
            <h3 class="panel-title">                
               <i class="fa fa-folder-open"></i>
               Management of Exams Setups in a Class Room 
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
                        <?php if ($setup_exam) :?>
                            <li class="active">
                                <a href="<?php echo DOMAIN_NAME ?>/exams/index#setupExam" data-toggle="tab"><b><i class="fa fa-gear"></i> Setup All Exams</b></a>
                            </li>
                        <?php endif; ?>
                        <li>
                            <a href="<?php echo DOMAIN_NAME ?>/exams/index#subjectScores" data-toggle="tab"><b><i class="fa fa-th"></i> Input / <i class="fa fa-edit"></i> Edit Scores</b></a>
                        </li>
                        <li>
                            <a href="<?php echo DOMAIN_NAME ?>/exams/index#viewTAScores" data-toggle="tab"><b><i class="fa fa-eye"></i> Terminal / Annual Scores </b></a>
                        </li>
                    </ul>
                    <div id="myTabContent" class="tab-content"> 
                        <?php if ($setup_exam) :?>
                            <div class="tab-pane fade in active" id="setupExam"><br> <!-- setupExam -->
                                <!--div class="col-md-7">
                                    <div class="panel panel-cascade">
                                        <div class="panel-body">
                                            <div class="panel panel-default">
                                                <div class="panel-heading"><i class="fa fa-search fa-1x"></i> Search Subjects Assigned</div>
                                                <div class="panel-body">
                                                    <?php
                                                        //Creates The Form
    //                                                    echo $this->Form->create('SubjectClasslevel', array(
    //                                                            'action' => 'search',
    //                                                            'class' => 'form-horizontal',
    //                                                            'id' => 'search_subject_assigned_form'
    //                                                        )
    //                                                    );
                                                    ?>
                                                        <div class="form-group">
                                                            <label for="classlevel_id_all" class="col-sm-4 control-label">Class Levels</label>
                                                            <div class="col-sm-8">
                                                                <?php
    //                                                                echo $this->Form->input('classlevel_id_all', array(
    //                                                                        'div' => false,
    //                                                                        'label' => false,
    //                                                                        'class' => 'form-control',
    //                                                                        'id' => 'classlevel_id_all',
    //                                                                         'required' => "required",
    //                                                                        'options' => $Classlevels,
    //                                                                        'empty' => '(Select Classlevel)'
    //                                                                    )
    //                                                                );
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
                                                            <label for="academic_year_id_all" class="col-sm-4 control-label">Academic Years</label>
                                                            <div class="col-sm-8">
                                                                <?php
    //                                                                echo $this->Form->input('academic_year_id_all', array(
    //                                                                        'div' => false,
    //                                                                        'label' => false,
    //                                                                        'class' => 'form-control',
    //                                                                        'id' => 'academic_year_id_all',
    //                                                                        'required' => "required",
    //                                                                        'selected' => $term_id->getCurrentYearID(),
    //                                                                        'options' => $AcademicYears,
    //                                                                        'empty' => '(Select Academic Year)'
    //                                                                    )
    //                                                                );
                                                                ?>
                                                            </div>
                                                        </div>
                                                        <div class="form-group">
                                                            <label for="academic_term_id_all" class="col-sm-4 control-label">Academic Terms</label>
                                                            <div class="col-sm-8">
                                                                <select class="form-control" name="data[SubjectClasslevel][academic_term_id_all]" id="academic_term_id_all" required="required">
                                                                    <option value="<?php //echo $term_id->getCurrentTermID();?>"><?php //echo $term_id->getCurrentTermName();?></option>

                                                                </select>
                                                            </div>
                                                        </div>
                                                        <div class="form-group">
                                                            <div class="col-sm-offset-2 col-sm-10">
                                                                <button type="submit" class="btn btn-info">Search Assigned Subject</button>
                                                            </div>
                                                        </div>
                                                    </form>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div-->
                                <div class="col-md-6">
                                    <div class="panel panel-cascade">
                                        <div class="panel-body">
                                            <div class="panel panel-default">
                                                <div class="panel-heading"><i class="fa fa-search fa-1x"></i> Search Subjects Assigned</div>
                                                <div class="panel-body">
                                                    <?php
                                                        //Creates The Form
                                                        echo $this->Form->create('ExamSetup', array(
                                                                'class' => 'form-horizontal',
                                                                'id' => 'setup_exam'
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
                                                            <select class="form-control" name="data[ExamSetup][academic_term_id_all]" id="academic_term_id_all" required="required">
                                                                <option value="<?php echo $term_id->getCurrentTermID();?>"><?php echo $term_id->getCurrentTermName();?></option>

                                                            </select>
                                                        </div>
                                                    </div>
                                                    <div class="form-group">
                                                        <div class="col-sm-offset-2 col-sm-10">
                                                            <button type="submit" class="btn btn-info">Setup Exam</button>
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
                                        <table  class="table table-bordered table-hover table-striped display" id="search_subjects_assigned_table" >

                                        </table>
                                    </div>
                                </div>
                            </div>
                        <?php endif;?><!-- / setupExam -->
                        <div class="tab-pane fade in <?php echo !($setup_exam) ? 'active' : '';?>" id="subjectScores"><br><!-- Input subject Scores -->
                            <div class="col-md-7">
                                <div class="panel panel-cascade">
                                    <div class="panel-body">
                                        <div class="panel panel-default">
                                            <div class="panel-heading"><i class="fa fa-search fa-1x"></i> Search Subjects Assigned CA's or Exams Scores</div>                                            
                                            <div class="panel-body">
                                                <?php 
                                                    //Creates The Form
                                                    echo $this->Form->create('SearchExamSetup', array(
                                                            'action' => 'search',
                                                            'class' => 'form-horizontal',
                                                            'id' => 'search_examSetup_form'
                                                        )
                                                    );     
                                                ?>                                                                                                  
                                                    <div class="form-group">
                                                        <label for="academic_year_examSetup_id" class="col-sm-4 control-label">Academic Years</label>
                                                        <div class="col-sm-8">
                                                            <?php 
                                                                echo $this->Form->input('academic_year_examSetup_id', array(
                                                                        'div' => false,
                                                                        'label' => false,
                                                                        'class' => 'form-control',
                                                                        'id' => 'academic_year_examSetup_id',
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
                                                        <label for="academic_term_examSetup_id" class="col-sm-4 control-label">Academic Terms</label>
                                                        <div class="col-sm-8">
                                                            <select class="form-control" name="data[SearchExamSetup][academic_term_examSetup_id]" id="academic_term_examSetup_id" required="required">
                                                                <option value="<?php echo $term_id->getCurrentTermID();?>"><?php echo $term_id->getCurrentTermName();?></option>

                                                            </select>
                                                        </div>
                                                    </div>
                                                    <div class="form-group">
                                                        <label for="classlevel_examSetup_id" class="col-sm-4 control-label">Class Levels</label>
                                                        <div class="col-sm-8">
                                                            <?php 
                                                                echo $this->Form->input('classlevel_examSetup_id', array(
                                                                        'div' => false,
                                                                        'label' => false,
                                                                        'class' => 'form-control',
                                                                        'id' => 'classlevel_examSetup_id',
                                                                         'required' => "required",
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
                            <div class="col-md-5" id="msg_box2"> </div>
                            <div class="col-md-12">
                                <div style="overflow-x: scroll" class="panel-body">
                                    <table  class="table table-bordered table-hover table-striped display" id="search_subjects_scores_table" >
                                        
                                    </table>
                                </div> 
                            </div>                            
                        </div><!-- Input subject Scores -->
                        <div class="tab-pane fade in" id="viewTAScores"><br><!-- View Terminal / annual Scores -->
                            <div class="col-md-7">
                                <div class="panel panel-cascade">
                                    <div class="panel-body">
                                        <div class="panel panel-default">
                                            <div class="panel-heading"><i class="fa fa-search fa-1x"></i> Search for CLass Room or Students Exams Scores </div>                                            
                                            <div class="panel-body">
                                                <?php 
                                                    //Creates The Form
                                                    echo $this->Form->create('SearchExamTAScores', array(
                                                            'action' => 'search',
                                                            'class' => 'form-horizontal',
                                                            'id' => 'search_examTAScores_form'
                                                        )
                                                    );     
                                                ?>                                                                                                  
                                                    <div class="form-group">
                                                        <label for="academic_year_examTAScores_id" class="col-sm-4 control-label">Academic Years</label>
                                                        <div class="col-sm-8">
                                                            <?php 
                                                                echo $this->Form->input('academic_year_examTAScores_id', array(
                                                                        'div' => false,
                                                                        'label' => false,
                                                                        'class' => 'form-control',
                                                                        'id' => 'academic_year_examTAScores_id',
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
                                                        <label for="academic_term_examTAScores_id" class="col-sm-4 control-label">Academic Terms</label>
                                                        <div class="col-sm-8">
                                                            <select class="form-control" name="data[SearchExamTAScores][academic_term_examTAScores_id]" id="academic_term_examTAScores_id" required="required">
                                                                <option value="<?php echo $term_id->getCurrentTermID();?>"><?php echo $term_id->getCurrentTermName();?></option>

                                                            </select>
                                                        </div>
                                                    </div>
                                                    <div class="form-group">
                                                        <label for="classlevel_examTAScores_id" class="col-sm-4 control-label">Class Levels</label>
                                                        <div class="col-sm-8">
                                                            <?php 
                                                                echo $this->Form->input('classlevel_examTAScores_id', array(
                                                                        'div' => false,
                                                                        'label' => false,
                                                                        'class' => 'form-control',
                                                                        'id' => 'classlevel_examTAScores_id',
                                                                         'required' => "required",
                                                                        'options' => $Classlevels,
                                                                        'empty' => '(Select Classlevel)'
                                                                    )
                                                                ); 
                                                            ?>
                                                        </div>
                                                    </div>
                                                    <div class="form-group">
                                                        <label for="class_examTAScores_id" class="col-sm-4 control-label">Class Rooms</label>
                                                        <div class="col-sm-8">
                                                            <select class="form-control" name="data[SearchExamTAScores][class_examTAScores_id]" id="class_examTAScores_id">
                                                                <option value="">  (Select Class Room)  </option>

                                                            </select>
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
                            <div class="col-md-5" id="msg_box3"> </div>
                            <div class="col-md-11">
                                <div style="overflow-x: scroll" class="panel-body">
                                    <table  class="table table-bordered table-hover table-striped display" id="view_TA_scores_table" >
                                        
                                    </table>
                                </div> 
                            </div>                            
                        </div><!-- View Terminal / annual Scores -->
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- Model for modifying subjects assigned to classrooms-->
    <div id="setup_exam_modal" class="modal fade" tabindex="-1" data-width="400" style="display: none;">
        <div class="modal-header">
            <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
            <h4 class="modal-title">Setup Exam Confirmation</h4>
        </div>
        <div class="panel-body">
            <?php
                //Creates The Form
                echo $this->Form->create('Exam', array(
                        'action' => 'setup_exam',
                        'class' => 'form-horizontal',
                        'id' => 'exam_setup_modal_form'
                    )
                );
            ?>

                <div class="modal-body">
                    <div class="row">
                        <div class="col-md-12">
                            <p>Are You Sure You Want Setup The Exam</p>
                        </div>
                    </div>
                </div>
                <div class="col-md-12" id="msg_box1_modal">     </div>
                <div class="modal-footer">
                    <input type="hidden" name="data[Exam][hidden_term_id]" id="hidden_term_id" value="">
                    <button type="button" data-dismiss="modal" class="btn btn-default">Close</button>
                    <button type="submit" class="btn btn-primary">Yes Setup</button>
                </div>
            </form>
        </div>
   </div><!--/ Modal Modifying Subjects Assigned-->
    
    <!-- Model for modifying subjects assigned to classrooms-->
    <!--div id="setup_exam_modal" class="modal fade" tabindex="-1" data-width="530" style="display: none;">
       <div class="modal-header">
           <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
           <div class="modal-title alert alert-info">Setting up Exams Weight Points <b>(WP)</b> </div>
       </div>
        <div class="panel-body">
            <?php 
                //Creates The Form
//                echo $this->Form->create('Exam', array(
//                        'action' => 'setup_exam',
//                        'class' => 'form-horizontal',
//                        'id' => 'exam_setup_modal_form'
//                    )
//                );
            ?>
                
                <!--div class="form-group">
                    <label for="weightageCA1" class="col-sm-4 control-label">First CA (W.P)</label>
                    <div class="col-sm-8">
                        <input type="text" class="form-control form-cascade-control input-small"
                        name="data[Exam][weightageCA1]" id="weightageCA1" placeholder="First CA Weight Point" required="required"/>
                    </div>
                </div>
                <div class="form-group">
                    <label for="weightageCA2" class="col-sm-4 control-label">Second CA (W.P)</label>
                    <div class="col-sm-8">
                        <input type="text" class="form-control form-cascade-control input-small"
                        name="data[Exam][weightageCA2]" id="weightageCA2" placeholder="Second CA Weight Point" required="required"/>
                    </div>
                </div>
                <div class="form-group">
                    <label for="weightageExam" class="col-sm-4 control-label">Exams (W.P)</label>
                    <div class="col-sm-8">
                        <input type="text" class="form-control form-cascade-control input-small"
                        name="data[Exam][weightageExam]" id="weightageExam" placeholder="Exams Weight Point" required="required"/>
                    </div>
                </div>
                
                <div class="form-group">
                    <label for="exam_desc" class="col-sm-4 control-label">Exams Description</label>
                    <div class="col-sm-8">
                        <textarea class="form-control form-cascade-control input-small" name="data[Exam][exam_desc]"
                        id="exam_desc" placeholder="Exams Description"></textarea>
                    </div>
                </div>
                <div class="form-group">
                    <div class="col-sm-offset-2 col-sm-10">
                        <input type="hidden" id="class_id" name="data[Exam][class_id]">
                        <input type="hidden" id="subject_classlevel_id" name="data[Exam][subject_classlevel_id]">
                        <input type="hidden" id="edit_exam_id" name="data[Exam][edit_exam_id]">
                        <button type="button" data-dismiss="modal" class="btn btn-default">Close</button>
                        <button type="submit" class="btn btn-info">Setup Exams</button>
                    </div>
                </div>
            <div class="col-md-12" id="msg_box1_modal">     </div>
            </form>
        </div>
   </div--><!--/ Modal Modifying Subjects Assigned-->
</div>
<?php
    // OnChange Of Classlevel Get Class Room
//    $this->Utility->getDependentListBox('#classlevel_id_all', '#class_id_all', 'classrooms', 'ajax_get_classes', 'SubjectClasslevel');
//    $this->Utility->getDependentListBox('#classlevel_examTAScores_id', '#class_examTAScores_id', 'classrooms', 'ajax_get_classes', 'SearchExamTAScores');
//
//    // OnChange of Academic Year Get Academic Term
//    $this->Utility->getDependentListBox('#academic_year_id_all', '#academic_term_id_all', 'academic_terms', 'ajax_get_terms', 'SubjectClasslevel');
//    $this->Utility->getDependentListBox('#academic_year_examSetup_id', '#academic_term_examSetup_id', 'academic_terms', 'ajax_get_terms', 'SearchExamSetup');
//    $this->Utility->getDependentListBox('#academic_year_examTAScores_id', '#academic_term_examTAScores_id', 'academic_terms', 'ajax_get_terms', 'SearchExamTAScores');
?>
<?php
    //on click of Manage Sponsors Record link... activate the link
    echo $this->Js->buffer('
        setTabActive("[href=\"'.DOMAIN_NAME.'/exams/index#setupExam\"]", 1);
    ');
?>