<?php echo $this->Html->script("../web/js/custom.home.js", FALSE);?>
<?php 
    App::uses('Encryption', 'Utility'); 
    $Encryption = new Encryption();
?>
<!-- Start Content-->
<section id="content">
    <div class="container">
        <div class="col-md-12">
            <div class="panel">
                <!-- Info Boxes -->
                <div class="row">
                    <div class="col-md-12">
                        <div class="info-box  bg-info  text-white">
                            <div class="info-icon bg-info-dark">
                                <i class="fa fa-list fa-4x"></i>
                            </div>
                            <div class="info-details">
                                <h4>Mange List of Students by Editing, Viewing or Deleting </h4>
                            </div>
                        </div>
                    </div>
                </div>
                <!-- / Info Boxes -->
                <div class="panel-heading">
                    <h3 class="panel-title">
                       <i class="fa fa-list"></i> Manage Students Information
                        <span class="pull-right">
                            <div class="btn-group code">
                                <a href="javascript:void(0)"  title="Refresh"><i class="fa fa-refresh"></i></a>
                                <a href="#" class="panel-minimize"><i class="fa fa-chevron-up"></i></a>
                                <a href="#" class="panel-close"><i class="fa fa-times"></i></a>
                            </div>
                        </span>
                    </h3>
                </div>
                <div class="panel-body">
                    <div class="panel panel-default">
                        <div style="overflow-x: scroll" class="panel-body">
                            <table  class="table table-bordered table-hover table-striped display" id="student_table" >
                                <thead>
                                 <tr>
                                  <th>ID</th>
                                  <th>Full Name</th>
                                  <th>Gender</th>
                                  <th>Sponsor</th>
                                  <th>Birth Date</th>
                                  <th>Class</th>
                                  <th>Status</th>
                                  <th>Action</th>
                                </tr>
                              </thead>
                              <tbody>
                                  <?php $i=1; foreach ($students as $student): ?>
                                 <tr class="gradeA">
                                     <?php $encrypted_student_id = $Encryption->encode($student['Student']['student_id']); ?>
                                     <td><?php echo h($student['Student']['student_no']); ?>&nbsp;</td>
                                     <td><?php echo h($student['Student']['first_name']), ' ', h($student['Student']['surname']), ' '; echo (!empty($student['Student']['other_name'])) ? h($student['Student']['other_name']) : '' ?>&nbsp;</td>
                                     <td><?php echo h($student['Student']['gender']); ?>&nbsp;</td>
                                     <td><?php echo h($student['Sponsor']['first_name']), ' ', h($student['Sponsor']['other_name']); ?>&nbsp;</td>
                                     <td><?php echo h($student['Student']['birth_date']); ?>&nbsp;</td>
                                     <td><?php echo (!empty($student['Student']['class_id'])) ? h($student['Classroom']['class_name']) : '<span class="label label-danger">nill</span>'; ?>&nbsp;</td>
                                     <td><?php echo h($student['StudentStatus']['student_status']); ?>&nbsp;</td>
                                     <td><a target="__blank" href="<?php echo DOMAIN_NAME ?>/home/record/<?php echo $encrypted_student_id; ?>" class="btn btn-info btn-xs"><i class="fa fa-eye"></i> View</a></td>
                                 </tr>
                                 <?php endforeach; ?>
                                </tbody>
                            </table>
                        </div> <!-- /panel body -->
                    </div>
                </div> <!-- /panel body -->  
            </div>
         </div> <!-- /col-md-12 -->
        <!-- divider -->
        <div class="row bottom2">
            <div class="span12">
                <div class="solidline"></div>
            </div>
        </div>
        <!-- end divider -->
    </div>
</section>
<!-- End Content-->