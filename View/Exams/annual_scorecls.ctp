<?php echo $this->Html->script("../app/js/bootstrap-datatables.js", FALSE);?>
<?php echo $this->Html->script("../app/js/dataTables-custom.js", FALSE);?>
<?php echo $this->Html->script("../app/jquery/custom.exam.js", FALSE);?>

<div class="col-md-12">
    <div class="panel">
        <!-- Info Boxes -->
        <!--div class="row">
            <div class="col-md-12">
                <div class="info-box  bg-info  text-white">
                    <div class="info-icon bg-info-dark">
                        <i class="fa fa-terminal fa-4x"></i>
                    </div>
                    <div class="info-details">
                        <h4>View Students Annual Class Room Positions </h4>
                    </div>
                </div>
            </div>
        </div>
        <!-- / Info Boxes -->
        <div class="panel-heading text-primary">
            <h3 class="panel-title">
               <i class="fa fa-book"></i> View Students Annual Class Positions
                <span class="pull-right">
                    <a href="javascript:void(0)"  title="Refresh"><i class="fa fa-refresh"></i></a>
                    <a href="#" class="panel-minimize"><i class="fa fa-chevron-up"></i></a>
                    <a href="#" class="panel-close"><i class="fa fa-times"></i></a>
                </span>
            </h3>
        </div>        
        <div class="row">
            <!-- Panel with Tables -->
            <div class="col-md-4">
                <div class="panel">
                    <div class="panel-body">
                        <div class="panel panel-primary">
                        <div class="panel-heading panel-title  text-white">Annual Class Summary</div>
                            <table class="table table-bordered table-hover table-striped">
                                <?php
                                    if($AnnualCLSPos['ScoresPos']):   
                                        $Temp = $AnnualCLSPos['ScoresPos'];
                                        $Temp = array_shift($Temp);
                                ?>
                                    <tr>
                                        <th>Class Room</th>
                                        <td><?php echo $Temp['class_name'];?></td>
                                    </tr>
                                    <tr>
                                        <th>Academic Year</th>
                                        <td><?php echo $Temp['academic_year'];?></td>
                                    </tr>
                                    <tr>
                                        <th>Exam Perfect Score</th>
                                        <td><?php echo $Temp['exam_annual_perfect_score'];?></td>
                                    </tr>
                                    <tr>
                                        <th>No. of Students in Class</th>
                                        <td><?php echo $Temp['clas_size'];?></td>
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
                            <div class="panel-heading panel-title  text-white">List of Students Annual Class Positions</div>
                            <div style="overflow-x: scroll" class="panel-body">
                                <?php if(!empty($AnnualCLSPos['ScoresPos'])):?>
                                <table  class="table table-bordered table-hover table-striped display scores_tables">
                                    <thead>
                                     <tr>
                                      <th>#</th>
                                      <th>Student Full Name</th>
                                      <th>Annual Total Sum</th>
                                      <th>Position</th>
                                    </tr>
                                  </thead>
                                  <tbody>
                                      <?php $i=1; foreach ($AnnualCLSPos['ScoresPos'] as $AnnualScore): ?>
                                      <tr class="gradeA" >
                                         <td><?php echo $i++;?></td>
                                         <td>
                                             <?php 
                                                if ($AnnualScore['class_annual_position'] === '1') {
                                                    echo '<span class="label label-success" style="font-size: medium">'.h($AnnualScore['full_name']).'</span>';
                                                }else if ($AnnualScore['class_annual_position'] === '2') {
                                                    echo '<span class="label label-info" style="font-size: medium">'.h($AnnualScore['full_name']).'</span>';
                                                }else if ($AnnualScore['class_annual_position'] === '3') {
                                                    echo '<span class="label label-warning" style="font-size: medium">'.h($AnnualScore['full_name']).'</span>';
                                                }else if ($AnnualScore['class_annual_position'] === $Temp['clas_size']) {
                                                    echo '<span class="label label-danger" style="font-size: medium">'.h($AnnualScore['full_name']).'</span>';
                                                }else{
                                                    echo h($AnnualScore['full_name']);
                                                } 
                                                    
                                             ?>
                                         </td>
                                         <td><?php echo h($AnnualScore['student_annual_total_score']);?></td>
                                         <td><?php echo $this->Utility->formatPosition(h($AnnualScore['class_annual_position']));?></td>
                                     </tr>
                                     <?php endforeach; ?>
                                    </tbody>
                                    <tfoot>
                                     <tr>
                                      <th>#</th>
                                      <th>Student Full Name</th>
                                      <th>Annual Total Sum</th>
                                      <th>Position</th>
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
        setTabActive("[href=\"'.DOMAIN_NAME.'/exams/index#subjectScores\"]", 0);
    ');
?> 
 