<?php echo $this->Html->script("../app/jquery/custom.weekly.report.js", FALSE);?>
<?php $term_id = ClassRegistry::init('AcademicTerm'); //echo date('Y-m-d h:m:s');?>
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
               <i class="fa fa-tasks"></i>
               Weekly Reports By Subjects in a Class Room
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
                    <div class="col-md-7">
                        <div class="panel panel-cascade">
                            <div class="panel-body">
                                <div class="panel panel-default">
                                    <div class="panel-heading"><i class="fa fa-search fa-1x"></i> Search For Subjects Assigned To You For The Academic Term</div>
                                    <div class="panel-body">
                                        <?php
                                        //Creates The Form
                                        echo $this->Form->create('SubjectClasslevel', array(
                                                'action' => 'search',
                                                'class' => 'form-horizontal',
                                                'id' => 'search_subject_assign_form'
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
                    <div class="col-md-10">
                        <div style="overflow-x: scroll"  class="panel-body">
                            <table class="table table-bordered table-hover table-striped display" id="subject_assigned_table" >

                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
<?php
    //on click of Manage Sponsors Record link... activate the link
    echo $this->Js->buffer('
        setTabActive("[href=\"'.DOMAIN_NAME.'/weekly_reports/index\"]", 1);
    ');
?>