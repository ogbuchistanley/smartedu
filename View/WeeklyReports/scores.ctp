<?php echo $this->Html->script("../app/jquery/custom.weekly.report.js", FALSE);?>
<?php $StudentModel = ClassRegistry::init('Student');?>
<?php
    $AllWeeklyRDs = $WeeklyRDs;
    $temp = array_shift($AllWeeklyRDs);
    App::uses('Encryption', 'Utility');
    $Encryption = new Encryption();
    $encrypted_id = $Encryption->encode($subject_classlevel['SubjectClasslevel']['subject_classlevel_id'].'/'.$temp['WeeklyReportDetail']['weekly_report_id']);
?>
<?php //print_r($WeeklyRDs);//echo date('Y-m-d h:m:s'); ?>

<div class="col-md-12">
    <div class="panel">
        <!-- Info Boxes -->
        <!--div class="row">
            <div class="col-md-12">
                <div class="info-box  bg-info  text-white">
                    <div class="info-icon bg-info-dark">
                        <i class="fa fa-ticket fa-4x"></i>
                    </div>
                    <div class="info-details">
                        <h4>Enter Students Subjects Scores or Modify Inputed Scores (CA's or Exams) </h4>
                    </div>
                </div>
            </div>
        </div>
        <!-- / Info Boxes -->
        <div class="panel-heading text-primary">
            <h3 class="panel-title">
                <i class="fa fa-tasks"></i>
                Inputting Scores For Weekly Reports By Subjects in a Class Room
                <span class="pull-right">
                    <a href="javascript:void(0)"  title="Refresh"><i class="fa fa-refresh"></i></a>
                    <a href="#" class="panel-minimize"><i class="fa fa-chevron-up"></i></a>
                    <a href="#" class="panel-close"><i class="fa fa-times"></i></a>
                </span>
            </h3>
        </div>
        <div class="row">
            <!-- Panel with Tables -->
            <div class="col-md-7">
                <div class="panel">
                    <div class="panel-body">
                        <div class="panel panel-primary">
                            <div class="panel-heading panel-title  text-white">Weekly Subject Report Details</div>
                            <table class="table table-bordered table-hover table-striped">
                                <?php if(!empty($subject_classlevel['SubjectClasslevel'])):?>
                                    <tr>
                                        <th>Academic Term</th>
                                        <td><?php echo $subject_classlevel['AcademicTerm']['academic_term'];?></td>
                                       <th>Subject Name</th>
                                        <td><?php echo $subject_classlevel['Subject']['subject_name'];?></td>
                                    </tr>
                                    <tr>
                                        <th>Class Level</th>
                                        <td><?php echo $subject_classlevel['Classlevel']['classlevel'];?></td>
                                        <th>Class Room</th>
                                        <td><?php echo $subject_classlevel['Classroom']['class_name'];?></td>
                                    </tr>
                                    <tr>
                                        <th>Report No.</th>
                                        <td><?php echo $this->Utility->formatPosition($WeeklyDS['WeeklyDetailSetup']['weekly_report_no']);?></td>
                                        <th>Submission Date</th>
                                        <td><?php echo $this->Utility->SQLDateToPHP($WeeklyDS['WeeklyDetailSetup']['submission_date']);?></td>
                                    </tr>
                                    <tr>
                                        <th>Weight Point</th>
                                        <td><?php echo h($WeeklyDS['WeeklyDetailSetup']['weekly_weight_point']);?></td>
                                        <th>Mark Status</th>
                                        <td><?php echo ($temp['WeeklyReport']['marked_status'] == 2) ? '<span class="label label-danger">Not Mark</span>' : '<span class="label label-success">Marked</span>';?></td>
                                    </tr>
                                    <tr>
                                        <th>C.A (%)</th>
                                        <td><?php echo h($WeeklyDS['WeeklyDetailSetup']['weekly_weight_percent']), ' %';?></td>
                                        <th>Description</th>
                                        <td><?php echo h($WeeklyDS['WeeklyDetailSetup']['report_description']);?></td>
                                    </tr>
                                <?php else:?>
                                    <tr>
                                        <th>No Record Found</th>
                                    </tr>
                                <?php endif;?>
                            </table>
                        </div>
                    </div>
                </div>
            </div> <!-- /Panel with Tables -->
        </div>
        <div class="row">
            <div class="col-md-8">
               <div class="panel">
                    <div class="panel-body">
                        <div class="panel panel-info">
                            <div class="panel-heading panel-title  text-white">Input Scores Table</div>
                            <div style="overflow-x: scroll" class="panel-body">
                                <?php if(!empty($WeeklyRDs)):?>
                                    <?php
                                        //Creates The Form
                                        echo $this->Form->create('WeeklyReport', array(
                                                'action' => 'save_scores/'.$encrypted_id,
                                                'class' => 'form-horizontal',
                                                'id' => 'weekly_report_form'
                                            )
                                        );
                                    ?>
                                        <table  class="table table-bordered table-hover table-striped display">
                                            <thead>
                                            <tr>
                                                <th>#</th>
                                                <th>Student ID</th>
                                                <th>Full Name</th>
                                                <th>Gender</th>
                                                <th>Weekly CA (<?php echo h($WeeklyDS['WeeklyDetailSetup']['weekly_weight_point']);?>)</th>
                                            </tr>
                                            </thead>
                                            <tbody>
                                                <input type="hidden" id="hidden_weight_point" value="<?php echo h($WeeklyDS['WeeklyDetailSetup']['weekly_weight_point']);?>">
                                                <?php $i=1; foreach($WeeklyRDs as $WeeklyRD): ?>
                                                    <tr>
                                                        <td><?php echo $i++;?></td>
                                                        <td>
                                                            <input type="hidden" name="data[WeeklyReport][weekly_report_detail_id][]" value="<?php echo h($WeeklyRD['WeeklyReportDetail']['weekly_report_detail_id']);?>">
                                                            <?php echo h($WeeklyRD['Student']['student_no']); ?>
                                                        </td>
                                                        <td><?php echo h(strtoupper($WeeklyRD['Student']['first_name'])), ' ', h($WeeklyRD['Student']['surname']), ' '; echo (!empty($WeeklyRD['Student']['other_name'])) ? h($WeeklyRD['Student']['other_name']) : '' ?>&nbsp;</td>
                                                        <td><?php echo h($WeeklyRD['Student']['gender']); ?>&nbsp;</td>
                                                        <td>
                                                            <input style="width: 100px;" class="form-control form-cascade-control weekly_ca" name="data[WeeklyReport][weekly_ca][]"
                                                                   value="<?php echo h($WeeklyRD['WeeklyReportDetail']['weekly_ca']);?>" maxlength="4"><span></span>
                                                        </td>
                                                    </tr>
                                                <?php endforeach; ?>
                                            </tbody>
                                            <tfoot>
                                            <tr>
                                                <th>#</th>
                                                <th>Student ID</th>
                                                <th>Full Name</th>
                                                <th>Gender</th>
                                                <th>Weekly CA (<?php echo h($WeeklyDS['WeeklyDetailSetup']['weekly_weight_point']);?>)</th>
                                            </tr>
                                            </tfoot>
                                        </table>
                                        <div class="form-group">
                                            <div class="col-sm-offset-2 col-sm-10">
                                                <button type="submit" class="btn btn-info" id="weekly_report_form_btn">Submit Input Scores</button>
                                            </div>
                                        </div>
                                    </form>
                                <?php else:?>
                                    <tr>
                                        <th>No Record Found</th>
                                    </tr>
                                <?php endif;?>
                            </div>
                        </div>
                    </div> <!-- /panel body --> 
               </div> <!-- /panel -->
            </div>
        </div>
    </div>
 </div> <!-- /col-md-12 -->
 <?php
    //on click of Manage Students link... activate the link
    echo $this->Js->buffer('
        setTabActive("[href=\"'.DOMAIN_NAME.'/weekly_reports/scores\"]", 0);
    ');
?> 
 