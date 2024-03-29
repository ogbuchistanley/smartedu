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
                        <h4>View Students Terminal Subjects Scores (CA's and Exams) </h4>
                    </div>
                </div>
            </div>
        </div>
        <!-- / Info Boxes -->
        <div class="panel-heading text-primary">
            <h3 class="panel-title">
               <i class="fa fa-bookmark-o"></i> View Student Terminal Exam Subjects Scores (CA's and Exams)
                <a class="btn btn-default" href="<?php echo DOMAIN_NAME ?>/exams/print_result/<?php echo $encrypt_id?>"  title="Print"><i class="fa fa-2x fa-print"></i> Print</a>
                <span class="pull-right">
                    <a href="<?php echo DOMAIN_NAME ?>/exams/print_result/<?php echo $encrypt_id?>"  title="Print"><i class="fa fa-print"></i></a>
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
                        <div class="panel-heading panel-title  text-white">
                            Overall Terminal Student Class Position
                            <a class="btn btn-default" href="<?php echo DOMAIN_NAME ?>/exams/print_result/<?php echo $encrypt_id?>"  title="Print"><i class="fa fa-2x fa-print"></i> Print</a>
                        </div>
                            <table class="table table-bordered table-hover table-striped">
                                <?php if($ClassPosition['ClassPositions']): ?>
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
                                                }else if ($ClassPosition['ClassPositions']['class_position'] === $ClassPosition['ClassPositions']['class_size']) {
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
                                        <th>Total Score</th>
                                        <td><?php echo $ClassPosition['ClassPositions']['student_sum_total'];?></td>
                                    </tr>
                                    <tr>
                                        <th>Exam Perfect Score</th>
                                        <td><?php echo $ClassPosition['ClassPositions']['exam_perfect_score'];?></td>
                                    </tr>
                                    <tr>
                                        <th>Position</th>
                                        <td><?php echo $this->Utility->formatPosition($ClassPosition['ClassPositions']['class_position']);?></td>
                                    </tr>
                                    <tr>
                                        <th>Out of.</th>
                                        <td><?php echo $ClassPosition['ClassPositions']['class_size'];?></td>
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
            </div><!-- /Panel with Tables -->

            <div class="col-md-6"><!-- Panel with Tables -->
                <div class="panel">
                    <div class="panel-body">
                        <div class="panel panel-primary">
                            <div class="panel-heading panel-title  text-white">
                                Terminal Student Assessment Report
                                <a class="btn btn-default" href="<?php echo DOMAIN_NAME ?>/exams/print_result/<?php echo $encrypt_id?>"  title="Print"><i class="fa fa-2x fa-print"></i> Print</a>
                            </div>
                            <table class="table table-bordered table-hover table-striped">
                                <?php if(!empty($SkillsAssess)): ?>
                                    <thead>
                                        <tr>
                                            <th>Assessment Skills</th>
                                            <th>5</th>
                                            <th>4</th>
                                            <th>3</th>
                                            <th>2</th>
                                            <th>1</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <?php foreach($SkillsAssess as $skill):?>
                                            <tr>
                                                <td><?php echo $skill['Skill']['skill']?>:</td>
                                                <?php echo ($skill['SkillAssessment']['option'] == 5) ? '<td><span class="badge bg-success-dark">5</span></td>' : '<td></td>'; ?>
                                                <?php echo ($skill['SkillAssessment']['option'] == 4) ? '<td><span class="badge bg-primary-dark">4</span></td>' : '<td></td>'; ?>
                                                <?php echo ($skill['SkillAssessment']['option'] == 3) ? '<td><span class="badge bg-info-dark">3</span></td>' : '<td></td>'; ?>
                                                <?php echo ($skill['SkillAssessment']['option'] == 2) ? '<td><span class="badge bg-warning-dark">2</span></td>' : '<td></td>'; ?>
                                                <?php echo ($skill['SkillAssessment']['option'] == 1) ? '<td><span class="badge bg-danger-dark">1</span></td>' : '<td></td>'; ?>
                                            </tr>
                                        <?php endforeach; ?>
                                    </tbody>
                                    <?php else:?>
                                        <tr>
                                            <th>Assessment Has Not Been Carried Out</th>
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
                            <div class="panel-heading panel-title  text-white">
                                List of Student Subjects and their exam Scores
                                <a class="btn btn-default text-primary" href="<?php echo DOMAIN_NAME ?>/exams/print_result/<?php echo $encrypt_id?>"  title="Print"><i class="fa fa-2x fa-print"></i> Print</a>
                            </div>
                            <div style="overflow-x: scroll" class="panel-body">
                                <?php if(!empty($TermScores['Scores'])):?>
                                <table  class="table table-bordered table-hover table-striped display">
                                    <thead>
                                     <tr>
                                        <th colspan="2"></th>
                                        <th colspan="5" style="text-align: center">Student Score(s) and Grade</th>
                                        <th colspan="3" style="text-align: center">Weight Point</th>
                                     </tr>
                                    </thead>
                                    <thead>
                                     <tr>
                                      <th>#</th>
                                      <th>Subject Name</th>
                                      <th>C. A</th>
                                      <th>Exam</th>
                                      <th>Total</th>
                                      <th>Total (100%)</th>
                                      <th>Grades</th>
                                      <th>C. A</th>
                                      <th>Exam</th>
                                      <th>C.A + Exam Total</th>
                                    </tr>
                                  </thead>
                                  <tbody>
                                      <?php $i=1; foreach ($TermScores['Scores'] as $TermScore): ?>
                                     <tr class="gradeA">
                                         <td><?php echo $i++;?></td>
                                         <td><?php echo h($TermScore['subject_name']);?></td>
                                         <td><?php echo h($TermScore['ca']);?></td>
                                         <td><?php echo h($TermScore['exam']);?></td>
                                         <td><?php echo h($TermScore['studentSubjectTotal']);?></td>
                                         <td><?php echo h($TermScore['studentPercentTotal']);?></td>
                                         <td><?php echo h($TermScore['grade']);?></td>
                                         <td><?php echo h($TermScore['ca_weight_point']);?></td>
                                         <td><?php echo h($TermScore['exam_weight_point']);?></td>
                                         <td><?php echo h($TermScore['weightageTotal']);?></td>
                                     </tr>
                                     <?php endforeach; ?>
                                    </tbody>
                                    <tfoot>
                                     <tr>
                                      <th>#</th>
                                      <th>Subject Name</th>
                                      <th>C. A</th>
                                      <th>Exam</th>
                                      <th>Total</th>
                                      <th>Total (100%)</th>
                                      <th>Grades</th>
                                      <th>C. A</th>
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
 