<?php echo $this->Html->script("../app/jquery/custom.attend.js", FALSE);?>
<?php echo $this->Html->script("../app/js/bootstrap-datatables.js", FALSE);?>
<?php echo $this->Html->script("../app/js/dataTables-custom.js", FALSE);?>

<div class="col-md-12">
    <div class="panel">
        <!-- Info Boxes -->
        <div class="row">
            <div class="col-md-12">
                <div class="info-box  bg-info  text-white">
                    <div class="info-icon bg-info-dark">
                        <i class="fa fa-list-ol fa-4x"></i>
                    </div>
                    <div class="info-details">
                        <h4>View Students Attendance Details</h4>
                    </div>
                </div>
            </div>
        </div>
        <!-- / Info Boxes -->
        <div class="panel-heading text-primary">
            <h3 class="panel-title">
               <i class="fa fa-eye"></i> View Students No. of Present / Absent Details
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
                        <div class="panel-heading panel-title  text-white">Student / Class Information</div>
                            <table class="table table-bordered table-hover table-striped">
                                <?php
                                    if(!empty($AttendDetails['AttendDetail'])):   
                                        $Temp = $AttendDetails['AttendDetail'];
                                        $Temp = array_shift($Temp);
                                ?>
                                    <tr>
                                        <th>Academic Term</th>
                                        <td><?php echo $Temp['academic_term'];?></td>
                                    </tr>
                                    <tr>
                                        <th>Class Room</th>
                                        <td><?php echo $Temp['class_name'];?></td>
                                    </tr>
                                    <tr>
                                        <th>Head Tutor</th>
                                        <td><?php echo $Temp['head_tutor'];?></td>
                                    </tr>
                                    <tr>
                                        <th>Student No.</th>
                                        <td><?php echo $Temp['student_no'];?></td>
                                    </tr>
                                    <tr>
                                        <th>Student Name</th>
                                        <td><?php echo $Temp['student_name'];?></td>
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
            <div class="col-md-6">
               <div class="panel">
                    <div class="panel-body">
                        <div class="panel panel-info">
                            <div class="panel-heading panel-title  text-white">Students Attendance Details Table</div>
                            <div style="overflow-x: scroll" class="panel-body">
                                <?php if(!empty($AttendDetails['AttendDetail'])):?>
                                <table  class="table table-bordered table-hover table-striped display" id="exam_scores_table" >
                                    <thead>
                                     <tr>
                                      <th>#</th>
                                      <th>Attendance Date</th>
                                      <th>Status</th>
                                    </tr>
                                  </thead>
                                  <tbody>
                                      <?php $i=1; foreach ($AttendDetails['AttendDetail'] as $AttendDetail): //date('Y-m-d', $AttendDetail['attend_date']);?>
                                     <tr class="gradeA">
                                         <td><?php echo $i++; ?>&nbsp;</td>
                                         <td><?php echo $this->Utility->SQLDateToPHP($AttendDetail['attend_date']); ?>&nbsp;</td>
                                         <td style="font-size: medium">
                                            <?php 
                                                if($AttendDetail['attend_status_id'] === '2'){
                                                    echo '<span class="label label-danger">'.$AttendDetail['attend_status'].'</span>'; 
                                                }else {
                                                    echo '<span class="label label-success">'.$AttendDetail['attend_status'].'</span>';
                                                }
                                            ?>
                                         </td>
                                     </tr>
                                     <?php endforeach; ?>
                                    </tbody>
                                    <tfoot>
                                     <tr>
                                      <th>#</th>
                                      <th>Attendance Date</th>
                                      <th>Status</th>
                                    </tr>
                                  </tfoot>
                                </table> 
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
        setTabActive("[href=\"'.DOMAIN_NAME.'/attends/index#take_attend\"]", 0);
    ');
?> 
 