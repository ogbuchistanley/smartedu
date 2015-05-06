<?php echo $this->Html->script("../app/jquery/custom.weekly.report.js", FALSE);?>
<?php //print_r($results);//echo date('Y-m-d h:m:s'); ?>
<?php
    App::uses('Encryption', 'Utility');
    $Encryption = new Encryption();
?>
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
        <div class="row">
            <!-- Panel with Tables -->
            <div class="col-md-5">
                <div class="panel">
                    <div class="panel-body">
                        <div class="panel panel-primary">
                            <div class="panel-heading panel-title  text-white">Subject Details</div>
                            <table class="table table-bordered table-hover table-striped">
                                <?php if(!empty($subject_classlevel['SubjectClasslevel'])):?>
                                    <tr>
                                        <th>Academic Term</th>
                                        <td><?php echo $subject_classlevel['AcademicTerm']['academic_term'];?></td>
                                    </tr>
                                    <tr>
                                        <th>Subject Name</th>
                                        <td><?php echo $subject_classlevel['Subject']['subject_name'];?></td>
                                    </tr>
                                    <tr>
                                        <th>Class Level</th>
                                        <td><?php echo $subject_classlevel['Classlevel']['classlevel'];?></td>
                                    </tr>
                                    <tr>
                                        <th>Class Room</th>
                                        <td><?php echo $subject_classlevel['Classroom']['class_name'];?></td>
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
            <div class="col-md-12">
                <div class="panel-body">
                    <div class="panel panel-info">
                        <div class="panel-heading panel-title text-white">Weekly Reports By Subjects Table</div>
                        <div style="overflow-x: scroll" class="panel-body">
                            <table  class="table table-bordered table-hover table-striped display">
                                <?php if(!empty($results)):?>
                                    <thead>
                                    <tr>
                                        <th>#</th>
                                        <th>Submission Date</th>
                                        <th>Weight Point</th>
                                        <th>Report No.</th>
                                        <th>C.A (%)</th>
                                        <th>Description</th>
                                        <th>Status</th>
                                        <th>Notification</th>
                                        <th>Action</th>
                                    </tr>
                                    </thead>
                                    <tbody>
                                        <?php $i=1; foreach($results as $result):
                                            $result = array_shift($result);
                                            $encrypted_id = $Encryption->encode($result['weekly_detail_setup_id'].'/'.$subject_classlevel['SubjectClasslevel']['subject_classlevel_id']);
                                        ?>
                                            <tr>
                                                <td><?php echo $i++;?></td>
                                                <td><?php echo $this->Utility->SQLDateToPHP($result['submission_date'])?></td>
                                                <td><?php echo $result['weekly_weight_point']?></td>
                                                <td><?php echo $this->Utility->formatPosition($result['weekly_report_no'])?></td>
                                                <td><?php echo h($result['weekly_weight_percent']), ' %'?></td>
                                                <td><?php echo h($result['report_description'])?></td>
                                                <td style="font-size: medium"><?php echo (empty($result['marked_status']) || $result['marked_status'] == 2) ?
                                                        '<span class="label label-danger"><i class="fa fa-times"></i> Not Mark</span>' : '<span class="label label-success"><i class="fa fa-check"></i> Marked</span>'?></td>
                                                <td style="font-size: medium"><?php echo (empty($result['notification_status']) || $result['notification_status'] == 2) ?
                                                        '<span class="label label-danger"><i class="fa fa-times"></i> Not Sent</span>' : '<span class="label label-success"><i class="fa fa-check"></i> Sent</span>'?></td>
                                                <td>
                                                    <?php //if($result['notification_status'] == 1) : ?>
                                                        <!--a target="__blank" href="<?php //echo DOMAIN_NAME ?>/weekly_reports/view/<?php //echo $encrypted_id;?>" class="btn btn-default btn-xs"><i class="fa fa-eye"></i> View Scores</a-->
                                                    <?php //else : ?>
                                                        <?php if(empty($result['marked_status']) || $result['marked_status'] == 2) : ?>
                                                            <a target="__blank" href="<?php echo DOMAIN_NAME ?>/weekly_reports/scores/<?php echo $encrypted_id;?>" class="btn btn-primary btn-xs"><i class="fa fa-plus-circle"></i> Input Scores</a>
                                                        <?php else : ?>
                                                            <a target="__blank" href="<?php echo DOMAIN_NAME ?>/weekly_reports/scores/<?php echo $encrypted_id;?>" class="btn btn-warning btn-xs"><i class="fa fa-edit"></i> Edit Scores</a>
                                                        <?php endif; ?>
                                                    <?php //endif; ?>
                                                </td>
                                            </tr>
                                        <?php endforeach; ?>
                                    </tbody>
                                    <tfoot>
                                    <tr>
                                        <th>#</th>
                                        <th>Submission Date</th>
                                        <th>Weight Point</th>
                                        <th>Report No.</th>
                                        <th>C.A (%)</th>
                                        <th>Description</th>
                                        <th>Status</th>
                                        <th>Notification</th>
                                        <th>Action</th>
                                    </tr>
                                    </tfoot>
                                <?php else:?>
                                    <tr>
                                        <th>No Record Found</th>
                                    </tr>
                                <?php endif;?>
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
        setTabActive("[href=\"'.DOMAIN_NAME.'/weekly_reports/report\"]", 0);
    ');
?>