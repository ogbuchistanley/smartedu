<?php echo $this->Html->script("../app/js/bootstrap-datatables.js", FALSE);?>
<?php echo $this->Html->script("../app/js/dataTables-custom.js", FALSE);?>
<?php echo $this->Html->script("../app/jquery/custom.exam.js", FALSE);?>

<?php $StudentModel = ClassRegistry::init('Student');?>
<?php  $ExamSubject = array_shift($ExamSubject); ?>
<?php  $exam_id = $ExamSubject['Exam']['exam_id']; ?>

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
                        <h4>View Students Subjects Scores (CA's or Exams) </h4>
                    </div>
                </div>
            </div>
        </div>
        <!-- / Info Boxes -->
        <div class="panel-heading text-primary">
            <h3 class="panel-title">
               <i class="fa fa-eye"></i> View Exam Subjects Scores
                <span class="pull-right">
                    <a href="javascript:void(0)"  title="Refresh"><i class="fa fa-refresh"></i></a>
                    <a href="#" class="panel-minimize"><i class="fa fa-chevron-up"></i></a>
                    <a href="#" class="panel-close"><i class="fa fa-times"></i></a>
                </span>
            </h3>
        </div>
        <div class="row">
            <!-- Panel with Tables -->
            <div class="col-md-8">
                <div class="panel">
                    <div class="panel-body">
                        <div class="panel panel-primary">
                        <div class="panel-heading panel-title  text-white">Exam Subject Details</div>
                            <table class="table table-bordered table-hover table-striped">
                                <?php if(!empty($ExamSubject['Exam'])):?>
                                    <tr>
                                        <th>Academic Term</th>
                                        <td><?php echo $ExamSubject['Exam']['academic_term'];?></td>
                                        <th>Subject Name</th>
                                        <td><?php echo $ExamSubject['Exam']['subject_name'];?></td>
                                    </tr>
                                    <tr>
                                        <th>Class Level</th>
                                        <td><?php echo $ExamSubject['Exam']['classlevel'];?></td>
                                        <th>Class Room</th>
                                        <td><?php echo (empty($ExamSubject['Exam']['class_name'])) ? '<span class="label label-danger">nill</span>' : $ExamSubject['Exam']['class_name'];?></td>
                                    </tr>
                                    <tr>
                                        <th>Weightage CA1</th>
                                        <td><?php echo $ExamSubject['Exam']['weightageCA1'];?></td>
                                        <th>Weightage CA2</th>
                                        <td><?php echo $ExamSubject['Exam']['weightageCA2'];?></td>
                                    </tr>
                                    <tr>
                                        <th>Weightage Exam</th>
                                        <td><?php echo $ExamSubject['Exam']['weightageExam'];?></td>
                                        <th>Weightage Total Sum</th>
                                        <td><?php echo ($ExamSubject['Exam']['weightageCA1']+$ExamSubject['Exam']['weightageCA2']+$ExamSubject['Exam']['weightageExam']);?></td>
                                    </tr>
                                    <tr>
                                        <th>Exam Description</th>
                                        <td><?php echo $ExamSubject['Exam']['exam_desc'];?></td>
                                        <th>Marked Status</th>
                                        <td style="font-size: medium"><?php echo ($ExamSubject['Exam']['exammarked_status_id'] === '2') ? '<span class="label label-danger">Subject Not Marked</span>' : '<span class="label label-success">Subject Marked</span>';?></td>                                        
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
                            <div class="panel-heading panel-title  text-white">Exam Scores Table</div>
                            <div style="overflow-x: scroll" class="panel-body">
                                <?php if(!empty($ExamSubject['Exam'])):?>
                                <table  class="table table-bordered table-hover table-striped display" id="exam_scores_table" >
                                    <thead>
                                     <tr>
                                      <th>Student ID</th>
                                      <th>Full Name</th>
                                      <th>Gender</th>
                                      <th>Class</th>
                                      <th>First CA</th>
                                      <th>Second CA</th>
                                      <th>Exam</th>
                                      <th>Exam Total(Sum)</th>
                                    </tr>
                                  </thead>
                                  <tbody>
                                      <?php $i=1; foreach ($ExamDetails as $ExamDetail): ?>
                                     <tr class="gradeA">
                                         <?php 
                                            $options = array('conditions' => array('Student.' . $StudentModel->primaryKey => $ExamDetail['Student']['student_id']));
                                            $Student = $StudentModel->find('first', $options);
                                         ?>
                                         <td><input type="hidden" class="input-small col-md-5" name="data[ExamDetail][exam_detail_id][]" value="<?php echo h($ExamDetail['ExamDetail']['exam_detail_id']).'-'.$exam_id;?>">
                                         <?php echo h($ExamDetail['Student']['student_no']); ?>&nbsp;</td>
                                         <td><?php echo h($ExamDetail['Student']['first_name']), ' ', h($ExamDetail['Student']['surname']), ' '; echo (!empty($ExamDetail['Student']['other_name'])) ? h($ExamDetail['Student']['other_name']) : '' ?>&nbsp;</td>
                                         <td><?php echo h($ExamDetail['Student']['gender']); ?>&nbsp;</td>
                                         <td><?php echo (!empty($ExamDetail['Student']['class_id'])) ? h($Student['Classroom']['class_name']) : '<span class="label label-danger">nill</span>'; ?>&nbsp;</td>
                                         <td><?php echo h($ExamDetail['ExamDetail']['ca1']);?></td>
                                         <td><?php echo h($ExamDetail['ExamDetail']['ca2']);?></td>
                                         <td><?php echo h($ExamDetail['ExamDetail']['exam']);?></td>
                                         <td><?php echo h($ExamDetail['ExamDetail']['ca1']) + h($ExamDetail['ExamDetail']['ca2']) + h($ExamDetail['ExamDetail']['exam']);?></td>
                                     </tr>
                                     <?php endforeach; ?>
                                    </tbody>
                                    <tfoot>
                                     <tr>
                                      <th>Student ID</th>
                                      <th>Full Name</th>
                                      <th>Gender</th>
                                      <th>Class</th>
                                      <th>First CA</th>
                                      <th>Second CA</th>
                                      <th>Exam</th>
                                      <th>Exam Total(Sum)</th>
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
    
    <div id="student_delete_modal" class="modal fade" tabindex="-1" data-width="400" style="display: none;">
       <div class="modal-header">
           <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
           <h4 class="modal-title">Deleting A Student Record</h4>
       </div>
        <form action="#" id="student_delete_form" method="post">
            <div class="modal-body">
                <div class="row">
                    <div class="col-md-12">
                        <p>Are You Sure You Want To Delete This Record</p>
                    </div>
                </div>
            </div>
            <div class="modal-footer">
                <input type="hidden" name="hidden_student_id" id="hidden_student_id" value="">                                    
                <button type="button" data-dismiss="modal" class="btn btn-default">Close</button>
                <button type="submit" class="btn btn-primary">Yes Delete</button>
            </div>
        </form>
   </div>
 </div> <!-- /col-md-12 -->
 <?php
    //on click of Manage Students link... activate the link
    echo $this->Js->buffer('
        setTabActive("[href=\"'.DOMAIN_NAME.'/exams/index#subjectScores\"]", 0);
    ');
?> 
 