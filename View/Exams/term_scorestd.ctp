<?php echo $this->Html->script("../app/js/bootstrap-datatables.js", FALSE);?>
<?php echo $this->Html->script("../app/js/dataTables-custom.js", FALSE);?>
<?php echo $this->Html->script("../app/jquery/custom.exam.js", FALSE);?>

<div class="col-md-12">
    <div class="panel">
        <!-- Info Boxes -->
        <div class="row">
            <div class="col-md-12">
                <div class="info-box  bg-info  text-white">
                    <div class="info-icon bg-info-dark">
                        <i class="fa fa-book fa-4x"></i>
                    </div>
                    <div class="info-details">
                        <h4>View Students Terminal Subjects Scores (CA's or Exams) </h4>
                    </div>
                </div>
            </div>
        </div>
        <!-- / Info Boxes -->
        <div class="panel-heading text-primary">
            <h3 class="panel-title">
               <i class="fa fa-bookmark-o"></i> View Student Terminal Exam Subjects Scores
                <span class="pull-right">
                    <a href="javascript:void(0)"  title="Refresh"><i class="fa fa-refresh"></i></a>
                    <a href="#" class="panel-minimize"><i class="fa fa-chevron-up"></i></a>
                    <a href="#" class="panel-close"><i class="fa fa-times"></i></a>
                </span>
            </h3>
        </div>        
        <div class="row">
            <!-- Panel with Tables -->
            <div class="col-md-6">
                <div class="panel">
                    <div class="panel-body">
                        <div class="panel panel-primary">
                        <div class="panel-heading panel-title  text-white">Overall Terminal Student Class Position</div>
                            <table class="table table-bordered table-hover table-striped">
                                <?php
                                    if($ClassPosition['ClassPositions']):                                     
                                ?>
                                    
                                    <tr>
                                        <th>Student Full Name</th>
                                        <td>
                                            <?php 
                                                if ($ClassPosition['ClassPositions']['class_position'] === '1') {
                                                    echo '<span class="label label-success" style="font-size: medium">'.h($ClassPosition['ClassPositions']['full_name']).'</span>';
                                                }else if ($ClassPosition['ClassPositions']['class_position'] === '2') {
                                                    echo '<span class="label label-info" style="font-size: medium">'.h($ClassPosition['ClassPositions']['full_name']).'</span>';
                                                }else if ($ClassPosition['ClassPositions']['class_position'] === '3') {
                                                    echo '<span class="label label-warning" style="font-size: medium">'.h($ClassPosition['ClassPositions']['full_name']).'</span>';
                                                }else if ($ClassPosition['ClassPositions']['class_position'] === $ClassPosition['ClassPositions']['clas_size']) {
                                                    echo '<span class="label label-danger" style="font-size: medium">'.h($ClassPosition['ClassPositions']['full_name']).'</span>';
                                                }else{
                                                    echo h($ClassPosition['ClassPositions']['full_name']);
                                                } 
                                                    
                                             ?>
                                        </td>
                                    </tr>
                                    <tr>
                                        <th>Class Room</th>
                                        <td><?php echo $ClassPosition['ClassPositions']['class_name'];?></td>
                                    </tr>
                                    <tr>
                                        <th>Academic Term</th>
                                        <td><?php echo $ClassPosition['ClassPositions']['academic_term'];?></td>
                                    </tr>
                                    <tr>
                                        <th>Student Sum Total Score</th>
                                        <td><?php echo $ClassPosition['ClassPositions']['student_sum_total'];?></td>
                                    </tr>
                                    <tr>
                                        <th>Exam Perfect Score</th>
                                        <td><?php echo $ClassPosition['ClassPositions']['exam_perfect_score'];?></td>
                                    </tr>
                                    <tr>
                                        <th>Class Position</th>
                                        <td><?php echo $ClassPosition['ClassPositions']['class_position'];?></td>
                                    </tr>
                                    <tr>
                                        <th>No. of Students in Class</th>
                                        <td><?php echo $ClassPosition['ClassPositions']['clas_size'];?></td>
                                        <!--td><span class="label label-danger">Subject Not Marked</span></td-->
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
               <div class="panel">
                    <div class="panel-body">
                        <div class="panel panel-info">
                            <div class="panel-heading panel-title  text-white">List of Student Subjects and their exam Scores</div>
                            <div style="overflow-x: scroll" class="panel-body">
                                <?php if(!empty($TermScores['Scores'])):?>
                                <table  class="table table-bordered table-hover table-striped display">
                                    <thead>
                                     <tr>
                                        <th colspan="2"></th>
                                        <th colspan="6" style="text-align: center">Student Score(s) and Grade</th>
                                        <th colspan="4" style="text-align: center">Weightage</th>
                                     </tr>
                                    </thead>
                                    <thead>
                                     <tr>
                                      <th>#</th>
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
                                      <?php $i=1; foreach ($TermScores['Scores'] as $TermScore): ?>
                                     <tr class="gradeA">
                                         <td><?php echo $i++;?></td>
                                         <td><?php echo h($TermScore['subject_name']);?></td>
                                         <td><?php echo h($TermScore['ca1']);?></td>
                                         <td><?php echo h($TermScore['ca2']);?></td>
                                         <td><?php echo h($TermScore['exam']);?></td>
                                         <td><?php echo h($TermScore['studentSubjectTotal']);?></td>
                                         <td><?php echo h($TermScore['studentPercentTotal']);?></td>
                                         <td><?php echo h($TermScore['grade']);?></td>
                                         <td><?php echo h($TermScore['weightageCA1']);?></td>
                                         <td><?php echo h($TermScore['weightageCA2']);?></td>
                                         <td><?php echo h($TermScore['weightageExam']);?></td>
                                         <td><?php echo h($TermScore['weightageTotal']);?></td>
                                     </tr>
                                     <?php endforeach; ?>
                                    </tbody>
                                    <tfoot>
                                     <tr>
                                      <th>#</th>
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
 