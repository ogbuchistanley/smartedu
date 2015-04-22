<?php echo $this->Html->script("../app/js/bootstrap-datatables.js", FALSE);?>
<?php echo $this->Html->script("../app/js/dataTables-custom.js", FALSE);?>
<?php echo $this->Html->script("../app/jquery/custom.exam.js", FALSE);?>

<?php $StudentModel = ClassRegistry::init('Student');?>
<?php  $ExamSubject = array_shift($ExamSubject); ?>
<?php  $exam_id = $ExamSubject['Exam']['exam_id']; ?>

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
               <i class="fa fa-edit"></i> Enter Students Subjects Scores or Modify Inputed Scores (CA's or Exams)
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
                        <div class="panel-heading panel-title  text-white">Exam Details</div>
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
                                        <th>Marked Status</th>
                                        <td style="font-size: medium"><?php echo ($ExamSubject['Exam']['exammarked_status_id'] === '2') ? '<span class="label label-danger">Subject Not Marked</span>' : '<span class="label label-success">Subject Marked</span>';?></td>
                                        <th>Weight Point CA1</th>
                                        <td><?php echo $ExamSubject['Exam']['weightageCA1'];?></td>
                                    </tr>
                                    <tr>
                                        <th>Weight Point CA2</th>
                                        <td><?php echo $ExamSubject['Exam']['weightageCA2'];?></td>
                                        <th>Weight Point Exam</th>
                                        <td><?php echo $ExamSubject['Exam']['weightageExam'];?></td>
                                        <input type="hidden" id="hidden_WA_value" value="<?php echo $ExamSubject['Exam']['weightageCA1'].'-'.$ExamSubject['Exam']['weightageCA2'].'-'.$ExamSubject['Exam']['weightageExam'];?>">
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
                            <div class="panel-heading panel-title  text-white">Input Scores Table</div>
                            <div style="overflow-x: scroll" class="panel-body">
                                <?php if(!empty($ExamDetails)):?>
                                <?php 
                                    //Creates The Form
                                    echo $this->Form->create('Exam', array(
                                            'action' => 'enter_scores',
                                            'class' => 'form-horizontal',
                                            'id' => 'exam_details_form'
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
                                      <th>Class</th>
                                      <th>First CA</th>
                                      <th>Second CA</th>
                                      <th>Exam</th>
                                    </tr>
                                  </thead>
                                  <tbody>
                                      <?php $i=1; foreach ($ExamDetails as $ExamDetail): ?>
                                     <tr class="gradeA">
                                         <?php 
                                            $options = array('conditions' => array('Student.' . $StudentModel->primaryKey => $ExamDetail['Student']['student_id']));
                                            $Student = $StudentModel->find('first', $options);
                                         ?>
                                         <td><?php echo $i++; ?></td>
                                         <td><input type="hidden" class="input-small col-md-5" name="data[ExamDetail][exam_detail_id][]" value="<?php echo h($ExamDetail['ExamDetail']['exam_detail_id']).'-'.$exam_id;?>">
                                         <?php echo h($ExamDetail['Student']['student_no']); ?>&nbsp;</td>
                                         <td><?php echo h($ExamDetail['Student']['first_name']), ' ', h($ExamDetail['Student']['surname']), ' '; echo (!empty($ExamDetail['Student']['other_name'])) ? h($ExamDetail['Student']['other_name']) : '' ?>&nbsp;</td>
                                         <td><?php echo h($ExamDetail['Student']['gender']); ?>&nbsp;</td>
                                         <td><?php echo (!empty($ExamDetail['Student']['class_id'])) ? h($Student['Classroom']['class_name']) : '<span class="label label-danger">nill</span>'; ?>&nbsp;</td>
                                         <td><input style="width: 100px;" class="form-cascade-control input-sm ca1_value" name="data[ExamDetail][ca1][]" value="<?php echo h($ExamDetail['ExamDetail']['ca1']);?>" maxlength="4"><span></span></td>
                                         <td><input style="width: 100px;" class="form-cascade-control input-sm ca2_value" name="data[ExamDetail][ca2][]" value="<?php echo h($ExamDetail['ExamDetail']['ca2']);?>" maxlength="4"><span></span></td>
                                         <td><input style="width: 100px;" class="form-cascade-control input-sm exam_value" name="data[ExamDetail][exam][]" value="<?php echo h($ExamDetail['ExamDetail']['exam']);?>" maxlength="4"><span></span></td>
                                     </tr>
                                     <?php endforeach; ?>
                                    </tbody>
                                    <tfoot>
                                     <tr>
                                      <th>#</th>
                                      <th>Student ID</th>
                                      <th>Full Name</th>
                                      <th>Gender</th>
                                      <th>Class</th>
                                      <th>First CA</th>
                                      <th>Second CA</th>
                                      <th>Exam</th>
                                    </tr>
                                  </tfoot>
                                </table> 
                                    <div class="form-group">
                                        <div class="col-sm-offset-2 col-sm-10">
                                            <button type="submit" class="btn btn-info">Submit Input Scores</button>
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
 