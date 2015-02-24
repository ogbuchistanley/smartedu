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
                        <i class="fa fa-eye-slash fa-4x"></i>
                    </div>
                    <div class="info-details">
                        <h4>View Students Attendance </h4>
                    </div>
                </div>
            </div>
        </div>
        <!-- / Info Boxes -->
        <div class="panel-heading text-primary">
            <h3 class="panel-title">
               <i class="fa fa-eye"></i> View Students That are Present and Those Absent
                <span class="pull-right">
                    <a href="javascript:void(0)"  title="Refresh"><i class="fa fa-refresh"></i></a>
                    <a href="#" class="panel-minimize"><i class="fa fa-chevron-up"></i></a>
                    <a href="#" class="panel-close"><i class="fa fa-times"></i></a>
                </span>
            </h3>
        </div>
        <div class="row">
            <div class="col-md-8">
               <div class="panel">
                    <div class="panel-body">
                        <div class="panel panel-info">
                            <div class="panel-heading panel-title  text-white">Students Attendance for 
                                <?php echo $Attends['Classroom']['class_name'].' '.$Attends['AcademicTerm']['academic_term'].' on '.$Attends['Attend']['attend_date']; ?>
                            </div>
                            <div style="overflow-x: scroll" class="panel-body">
                                <?php if(!empty($AttendDetails['AttendDetail'])):?>
                                <table  class="table table-bordered table-hover table-striped display" id="exam_scores_table" >
                                    <thead>
                                     <tr>
                                      <th>#</th>
                                      <th>Student No.</th>
                                      <th>Full Name</th>
                                      <th>Class Name</th>
                                      <th>Status</th>
                                      <th>Student Info</th>
                                    </tr>
                                  </thead>
                                  <tbody>
                                      <?php $i=1; foreach ($AttendDetails['AttendDetail'] as $AttendDetail): ?>
                                     <tr class="gradeA">
                                         <td><?php echo $i++; ?>&nbsp;</td>
                                         <td><?php echo h($AttendDetail['student_no']); ?>&nbsp;</td>
                                         <td><?php echo h($AttendDetail['student_name']); ?>&nbsp;</td>
                                         <td><?php echo h($AttendDetail['class_name']); ?>&nbsp;</td>
                                         <td style="font-size: medium"><?php echo ($AttendDetail['attend_id'] === '-1') ? '<span class="label label-danger">Absent</span>' : '<span class="label label-success">Present</span>'; ?>&nbsp;</td>
                                         <td>
                                             <a target="__blank" href="<?php echo DOMAIN_NAME ?>/students/view/<?php echo h($AttendDetail['student_id']); ?>" class="btn btn-info btn-xs">
                                            <i class="fa fa-eye"></i> View</a>
                                         </td>
                                     </tr>
                                     <?php endforeach; ?>
                                    </tbody>
                                    <tfoot>
                                     <tr>
                                      <th>#</th>
                                      <th>Student No.</th>
                                      <th>Full Name</th>
                                      <th>Class Name</th>
                                      <th>Status</th>
                                      <th>Student Info</th>
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
 