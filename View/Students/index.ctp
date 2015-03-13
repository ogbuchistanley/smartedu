<?php echo $this->Html->script("../app/js/bootstrap-datatables.js", FALSE);?>
<?php echo $this->Html->script("../app/js/dataTables-custom.js", FALSE);?>
<?php echo $this->Html->script("../app/jquery/custom.student.js", FALSE);?>
<?php 
    App::uses('Encryption', 'Utility'); 
    $Encryption = new Encryption();
    
    $student_delete = Configure::read('student_delete');
?>

<div class="col-md-12">
    <div class="panel">
        <!-- Info Boxes -->
        <!--div class="row">
            <div class="col-md-12">
                <div class="info-box  bg-info  text-white">
                    <div class="info-icon bg-info-dark">
                        <i class="fa fa-list fa-4x"></i>
                    </div>
                    <div class="info-details">
                        <h4>Manage List of Students by Editing, Viewing or Deleting </h4>
                    </div>
                </div>
            </div>
        </div>
        <!-- / Info Boxes -->
        <div class="panel-heading text-primary">
            <h3 class="panel-title">
               <i class="fa fa-list"></i> Manage Students Information <label class="label label-primary">Mange List of Students by Editing, Viewing or Deleting</label>
                <span class="pull-right">
                    <a href="javascript:void(0)"  title="Refresh"><i class="fa fa-refresh"></i></a>
                    <a href="#" class="panel-minimize"><i class="fa fa-chevron-up"></i></a>
                    <a href="#" class="panel-close"><i class="fa fa-times"></i></a>
                </span>
            </h3>
        </div>
        <div class="panel-body">
            <div class="panel panel-info">
                <div class="panel-heading panel-title  text-white">Student's Table</div>
                <div style="overflow-x: scroll" class="panel-body">
                    <table  class="table table-bordered table-hover table-striped display" id="student_table" >
                        <thead>
                         <tr>
                          <th>ID</th>
                          <th>Full Name</th>
                          <th>Gender</th>
                          <th>Sponsor Name</th>
                          <th>Birth Date</th>
                          <th>Class</th>
                          <th>Status</th>
                          <th>View</th>
                          <th>Edit</th>
                          <?php if($student_delete):?>
                            <th>Delete</th>
                          <?php endif;?>
                        </tr>
                      </thead>
                      <tbody>
                          <?php $i=1; foreach ($students as $student): ?>
                         <tr class="gradeA">
                             <?php 
                                $encrypted_student_id = $Encryption->encode($student['Student']['student_id']);
                                $encrypted_sponsor_id = $Encryption->encode($student['Student']['sponsor_id']);
                             ?>
                             <td><?php echo h($student['Student']['student_no']); ?>&nbsp;</td>
                             <td><?php echo h($student['Student']['first_name']), ' ', h($student['Student']['surname']), ' '; echo (!empty($student['Student']['other_name'])) ? h($student['Student']['other_name']) : '' ?>&nbsp;</td>
                             <td><?php echo h($student['Student']['gender']); ?>&nbsp;</td>
                             <td>
                                 <a target="__blank" href="<?php echo DOMAIN_NAME ?>/sponsors/view/<?php echo $encrypted_sponsor_id; ?>" class="btn-link">
                                    <?php echo h($student['Sponsor']['first_name']), ' ', h($student['Sponsor']['other_name']); ?>
                                 </a>
                            </td>
                             <td><?php echo h($student['Student']['birth_date']); ?>&nbsp;</td>
                             <td><?php echo (!empty($student['Student']['class_id'])) ? h($student['Classroom']['class_name']) : '<span class="label label-danger">nill</span>'; ?>&nbsp;</td>
                             <td>
                                 <?php 
                                    if(h($student['Student']['student_status_id']) === '1' || h($student['Student']['student_status_id']) === '2'){
                                        echo '<button title="'.$student['Student']['student_status_id'].'" value="'.$student['Student']['student_id'].'" class="btn btn-success btn-xs student_status_edit">'
                                            . '<i class="fa fa-check-square-o fa-1x"></i><span class="label label-success"> '.$student['StudentStatus']['student_status'].'</span></button>';
                                    }else if(h($student['Student']['student_status_id']) === '3'){
                                        echo '<button title="'.$student['Student']['student_status_id'].'" value="'.$student['Student']['student_id'].'" class="btn btn-warning  btn-xs student_status_edit">'
                                            . '<i class="fa fa-warning fa-1x"></i><span class="label label-warning"> '.$student['StudentStatus']['student_status'].'</span></button>';
                                    }else{
                                        echo '<button title="'.$student['Student']['student_status_id'].'" value="'.$student['Student']['student_id'].'" class="btn btn-danger  btn-xs student_status_edit">'
                                            . '<i class="fa fa-times-circle-o fa-1x"></i><span class="label label-danger"> '.$student['StudentStatus']['student_status'].'</span></button>';
                                    }
                                 ?>
                             </td>
                             <td><a target="__blank" href="<?php echo DOMAIN_NAME ?>/students/view/<?php echo $encrypted_student_id; ?>" class="btn btn-info btn-xs"><i class="fa fa-eye"></i> View</a></td>
                             <td><a href="<?php echo DOMAIN_NAME ?>/students/adjust/<?php echo $encrypted_student_id; ?>" class="btn btn-warning btn-xs"><i class="fa fa-edit"></i> Edit</a></td>
                             <?php if($student_delete):?>
                                <td><button class="demo btn pull-right btn-danger btn-xs btn-delete delete_student" value="<?php echo $encrypted_student_id; ?>" data-toggle="modal" href="#student_delete_modal"><i class="fa fa-trash-o"></i> Delete</button></td>
                             <?php endif;?>
                         </tr>
                         <?php endforeach; ?>
                        </tbody>
                        <tfoot>
                         <tr>
                          <th>ID</th>
                          <th>Full Name</th>
                          <th>Gender</th>
                          <th>Sponsor Name</th>
                          <th>Birth Date</th>
                          <th>Class</th>
                          <th>Status</th>
                          <th>View</th>
                          <th>Edit</th>
                          <?php if($student_delete):?>
                            <th>Delete</th>
                          <?php endif;?>
                        </tr>
                      </tfoot>
                    </table>
                    <?php 
                        echo $this->Form->input('students_status', array(
                                'div' => false,
                                'label' => false,
                                'class' => 'form-control input-medium',
                                'id' => 'students_status',
                                'options' => $StudentStatuss
                            )
                        ); 
                    ?>
                </div> <!-- /panel body -->
            </div>
        </div> <!-- /panel body -->  
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
        setTabActive("[href=\"'.DOMAIN_NAME.'/students/\"]", 1);
    ');
?> 
 