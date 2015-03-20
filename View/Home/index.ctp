<?php echo $this->Html->script("../app/js/bootstrap-datatables.js", FALSE);?>
<?php echo $this->Html->script("../app/js/dataTables-custom.js", FALSE);?>
<?php echo $this->Html->script("../app/jquery/custom.student.js", FALSE);?>
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
                <i class="fa fa-list"></i> Students Information <label class="label label-primary">View List of Your Students</label>
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
                            <th>Parent Name</th>
                            <th>Birth Date</th>
                            <th>Class</th>
                            <th>Status</th>
                            <th>View</th>
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
                                    echo '<span class="label label-success"> '.$student['StudentStatus']['student_status'].'</span>';
                                }else if(h($student['Student']['student_status_id']) === '3'){
                                    echo '<span class="label label-warning"> '.$student['StudentStatus']['student_status'].'</span>';
                                }else{
                                    echo '<span class="label label-danger"> '.$student['StudentStatus']['student_status'].'</span>';
                                }
                                ?>
                            </td>
                            <td><a target="__blank" href="<?php echo DOMAIN_NAME ?>/students/view/<?php echo $encrypted_student_id; ?>" class="btn btn-info btn-xs"><i class="fa fa-eye"></i> View</a></td>
                            <?php endforeach; ?>
                        </tbody>
                        <tfoot>
                        <tr>
                            <th>ID</th>
                            <th>Full Name</th>
                            <th>Gender</th>
                            <th>Parent Name</th>
                            <th>Birth Date</th>
                            <th>Class</th>
                            <th>Status</th>
                            <th>View</th>
                        </tr>
                        </tfoot>
                    </table>
                </div> <!-- /panel body -->
            </div>
        </div> <!-- /panel body -->
    </div>
</div> <!-- /col-md-12 -->
<?php
//on click of Manage Students link... activate the link
echo $this->Js->buffer('
        setTabActive("[href=\"'.DOMAIN_NAME.'/students/\"]", 1);
    ');
?> 
 