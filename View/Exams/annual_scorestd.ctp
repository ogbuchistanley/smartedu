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
                        <i class="fa fa-book fa-4x"></i>
                    </div>
                    <div class="info-details">
                        <h4>View Students Annual Subjects Scores (CA's or Exams) </h4>
                    </div>
                </div>
            </div>
        </div>
        <!-- / Info Boxes -->
        <div class="panel-heading text-primary">
            <h3 class="panel-title">
               <i class="fa fa-bookmark"></i> View Student Annual Exam Subjects Scores
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
                        <div class="panel-heading panel-title  text-white">Annual Class Position Details</div>
                            <table class="table table-bordered table-hover table-striped">
                                <?php
                                    if(!empty($AnnualPositionArray['ClassPos'])):   
                                        $AnnualPosition = $AnnualPositionArray['ClassPos'];
                                        $AnnualPosition = array_shift($AnnualPosition);
                                ?>
                                    <tr>
                                        <th>Student Name</th>
                                        <td>
                                            <?php 
                                                if ($AnnualPosition['class_annual_position'] === '1') {
                                                    echo '<span class="label label-success" style="font-size: medium">'.h($AnnualPosition['full_name']).'</span>';
                                                }else if ($AnnualPosition['class_annual_position'] === '2') {
                                                    echo '<span class="label label-info" style="font-size: medium">'.h($AnnualPosition['full_name']).'</span>';
                                                }else if ($AnnualPosition['class_annual_position'] === '3') {
                                                    echo '<span class="label label-warning" style="font-size: medium">'.h($AnnualPosition['full_name']).'</span>';
                                                }else if ($AnnualPosition['class_annual_position'] === $AnnualPosition['class_size']) {
                                                    echo '<span class="label label-danger" style="font-size: medium">'.h($AnnualPosition['full_name']).'</span>';
                                                }else{
                                                    echo h($AnnualPosition['full_name']);
                                                } 
                                                    
                                             ?>
                                        </td>
                                    </tr>
                                    <tr>
                                        <th>Class Position</th>
                                        <td><?php echo $AnnualPosition['class_annual_position'];?></td>
                                    </tr>
                                    <tr>
                                        <th>No. of Students</th>
                                        <td><?php echo $AnnualPosition['class_size'];?></td>
                                    </tr>
                                    <tr>
                                        <th>Class Room</th>
                                        <td><?php echo $AnnualPosition['class_name'];?></td>
                                    </tr>
                                    <tr>
                                        <th>Total Sum</th>
                                        <td><?php echo $AnnualPosition['student_annual_total_score'];?></td>
                                    </tr>
                                    <tr>
                                        <th>Perfect Score</th>
                                        <td><?php echo $AnnualPosition['exam_annual_perfect_score'];?></td>
                                    </tr>
                                    <tr>
                                        <th>Academic Year</th>
                                        <td><?php echo $AnnualPosition['academic_year'];?></td>
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
            </div>
            <div class="col-md-7">
                <div class="panel">
                    <div class="panel-body">
                        <div class="panel panel-primary">
                        <div class="panel-heading panel-title  text-white">Overall Annual List of Subjects Summary</div>
                            <table class="table table-bordered table-hover table-striped">
                                <?php
                                    if(!empty($AnnualSubArray['ScoresSub'])):                                     
                                ?>
                                    <thead>
                                        <tr class="text-white" style="background-color: #999;">
                                           <th colspan="2"></th>
                                           <th colspan="3" style="text-align: center">Academic Terms Scores</th>
                                           <th colspan="2" style="text-align: center">Annual Average</th>
                                        </tr>
                                        <tr class="text-white" style="background-color: #999;">
                                          <th>#</th>
                                          <th>Subject Name</th>
                                          <th>First</th>
                                          <th>Second</th>
                                          <th>Third</th>
                                          <th>Score</th>
                                          <th>Remark</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <?php $frs=0; $sec=0; $thr=0; $avg=0;?>
                                        <?php $i=1; foreach ($AnnualSubArray['ScoresSub'] as $ScoresSub): ?>
                                            <tr>
                                                <td><?php echo $i++;?></td>
                                                <td><?php echo $ScoresSub['subject_name'];?></td>
                                                <td><?php $frs += $ScoresSub['first_term']; echo (!empty($ScoresSub['first_term'])) ? h($ScoresSub['first_term']) : '<span class="label label-danger">****</span>';?></td>
                                                <td><?php $sec += $ScoresSub['second_term']; echo (!empty($ScoresSub['second_term'])) ? h($ScoresSub['second_term']) : '<span class="label label-danger">****</span>';?></td>
                                                <td><?php $thr += $ScoresSub['third_term']; echo (!empty($ScoresSub['third_term'])) ? h($ScoresSub['third_term']) : '<span class="label label-danger">****</span>';?></td>
                                                <td><?php $avg += $ScoresSub['annual_average']; echo (!empty($ScoresSub['annual_average'])) ? h($ScoresSub['annual_average']) : '<span class="label label-danger">****</span>';?></td>
                                                <td><?php echo $ScoresSub['annual_grade'];?></td>
                                            </tr>
                                        <?php endforeach;?>
                                            <tr>
                                                <th>Total</th>
                                                <th></th>
                                                <th><?php echo (!empty($frs)) ? $frs : '<span class="label label-danger">****</span>';?></th>
                                                <th><?php echo (!empty($sec)) ? $sec : '<span class="label label-danger">****</span>';?></th>
                                                <th><?php echo (!empty($thr)) ? $thr : '<span class="label label-danger">****</span>';?></th>
                                                <th><?php echo (!empty($avg)) ? $avg : '<span class="label label-danger">****</span>';?></th>
                                            </tr>
                                    </tbody>
                                <?php else:?>
                                    <tr>
                                        <th>No Record Found</th>
                                    </tr>
                                <?php endif;?>
                            </table>
                        </div>
                    </div>
                </div>
            </div><!-- /Panel with Tables -->
        </div>
        
        <div class="row">
            <div class="col-md-12">
               <div class="panel">
                    <div class="panel-body">
                        <div class="panel panel-info">
                            <div class="panel-heading panel-title  text-white">Terminal List of Student Subjects and their exam Scores</div>
                            <div style="overflow-x: scroll" class="panel-body">
                                <?php if(!empty($AnnualScoresArray[0])):?>
                                <table  class="table table-bordered table-hover table-striped display">
                                    <thead>
                                     <tr class="text-white" style="background-color: #999;">
                                        <th colspan="3"></th>
                                        <th colspan="6" style="text-align: center">Student Score(s) and Grade</th>
                                        <th colspan="4" style="text-align: center">Weightage</th>
                                     </tr>
                                    <tr class="text-white" style="background-color: #999;">
                                      <th>#</th>
                                      <th>Term</th>
                                      <th>Subject Name</th>
                                      <th>1st C.A</th>
                                      <th>2nd C.A</th>
                                      <th>Exam</th>
                                      <th>Total</th>
                                      <th>Total (100%)</th>
                                      <th>Grades</th>
                                      <th>1st C.A</th>
                                      <th>2nd C.A</th>
                                      <th>Exam</th>
                                      <th>C.A + Exam Total</th>
                                    </tr>
                                  </thead>
                                  <tbody>
                                      <?php for($j=0; $j<(count($AnnualScoresArray) / 2); $j++): ?>
                                        <?php if($AnnualScoresArray[$j] !== null): ?>
                                            <tr>
                                                <th></th>
                                                <th colspan="12"><?php echo $AnnualScoresArray['AcademicTermName'][$j];?></th>
                                            </tr>
                                            <?php $ca1Sum=0; $ca2Sum=0; $examSum=0; $stdSSum=0; $stdPSum=0;?>
                                            <?php $wa1Sum=0; $wa2Sum=0; $wexamSum=0; $wSum=0;?>
                                            <?php $i=1; foreach ($AnnualScoresArray[$j] as $TermScore): ?>
                                                <tr>
                                                   <td><?php echo $i++;?></td>
                                                   <td></td>
                                                   <td><?php echo h($TermScore['subject_name']);?></td>
                                                   <td><?php $ca1Sum += $TermScore['ca1'];  echo h($TermScore['ca1']);?></td>
                                                   <td><?php $ca2Sum += $TermScore['ca2'];  echo h($TermScore['ca2']);?></td>
                                                   <td><?php $examSum += $TermScore['exam'];  echo h($TermScore['exam']);?></td>
                                                   <td><?php $stdSSum += $TermScore['studentSubjectTotal'];  echo h($TermScore['studentSubjectTotal']);?></td>
                                                   <td><?php $stdPSum += $TermScore['studentPercentTotal'];  echo h($TermScore['studentPercentTotal']);?></td>
                                                   <td><?php echo h($TermScore['grade']);?></td>
                                                   <td><?php $wa1Sum += $TermScore['weightageCA1'];  echo h($TermScore['weightageCA1']);?></td>
                                                   <td><?php $wa2Sum += $TermScore['weightageCA2'];  echo h($TermScore['weightageCA2']);?></td>
                                                   <td><?php $wexamSum += $TermScore['weightageExam'];  echo h($TermScore['weightageExam']);?></td>
                                                   <td><?php $wSum += $TermScore['weightageTotal'];  echo h($TermScore['weightageTotal']);?></td>
                                                </tr>
                                            <?php endforeach; ?>
                                            <tr>
                                                <th></th>
                                                <th colspan="2">Term Sub Total</th>
                                                <th><?php echo $ca1Sum;?></th>
                                                <th><?php echo $ca2Sum;?></th>
                                                <th><?php echo $examSum;?></th>
                                                <th><?php echo $stdSSum;?></th>
                                                <th><?php echo $stdPSum;?></th>
                                                <th></th>
                                                <th><?php echo $wa1Sum;?></th>
                                                <th><?php echo $wa2Sum;?></th>
                                                <th><?php echo $wexamSum;?></th>
                                                <th><?php echo $wSum;?></th>
                                            </tr>
                                            <tr><th colspan="13"></th></tr>
                                        <?php endif; ?>
                                     <?php endfor; ?>
                                    </tbody>
                                    <tfoot>
                                     <tr class="text-white" style="background-color: #999;">
                                      <th>#</th>
                                      <th>Term</th>
                                      <th>Subject Name</th>
                                      <th>1st C.A</th>
                                      <th>2nd C.A</th>
                                      <th>Exam</th>
                                      <th>Total</th>
                                      <th>Total (100%)</th>
                                      <th>Grades</th>
                                      <th>1st C.A</th>
                                      <th>2nd C.A</th>
                                      <th>Exam</th>
                                      <th>C.A + Exam Total</th>
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
 