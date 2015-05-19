<!-- Page Scripts =============================-->
<?php echo $this->Html->script("../app/js/bootstrap-datatables.js", FALSE);?>
<?php echo $this->Html->script("../app/js/dataTables-custom.js", FALSE);?>
<?php //echo $this->Html->script("../app/jquery/custom.classroom.js", FALSE);?>
<?php echo $this->Html->script("../app/jquery/custom.exam.js", FALSE);?>

<div class="col-md-12">
    <div class="panel">
        <!-- Info Boxes -->
        <div class="row">
            <div class="col-md-12">
                <div class="info-box  bg-info  text-white">
                    <div class="info-icon bg-info-dark">
                        <i class="fa fa-building fa-4x"></i>
                    </div>
                    <div class="info-details">
                        <h4>List of  Class Room(s) Assigned To You</h4>
                    </div>
                </div>
            </div>
        </div>
        <!-- / Info Boxes -->
        <div class="panel-heading text-primary">
            <h3 class="panel-title">
                <i class="fa fa-home"></i>
                Displays Class Room(s) Assigned
                <span class="pull-right">
                    <a href="javascript:void(0)"  title="Refresh"><i class="fa fa-refresh"></i></a>
                    <a href="#" class="panel-minimize"><i class="fa fa-chevron-up"></i></a>
                    <a href="#" class="panel-close"><i class="fa fa-times"></i></a>
                </span>
            </h3>
        </div>
        <div class="col-md-9">
            <div class="panel-body">
                <div class="panel panel-info">
                    <div class="panel-heading panel-title  text-white">Table Displaying List of Class Room(s) Assigned</div>
                    <div style="overflow-x: scroll" class="panel-body">
                        <table  class="table table-bordered table-hover table-striped display custom_tables">
                            <?php if(!empty($ClassRooms['Classroom'])):?>
                                <thead>
                                <tr>
                                    <th>#</th>
                                    <th>Class Name</th>
                                    <th>Academic Year</th>
                                    <th>Head Tutor</th>
                                    <th>Date Assign</th>
                                    <th>View Students</th>
                                </tr>
                                </thead>
                                <tbody>
                                <?php $i=1; foreach ($ClassRooms['Classroom'] as $ClassRoom): ?>
                                    <tr class="gradeA">
                                        <?php
                                        //$encrypted_user_id = $Encryption->encode($ClassRoom['class_id']);
                                        ?>
                                        <td><?php echo $i++; ?></td>
                                        <td><?php echo h($ClassRoom['class_name']); ?>&nbsp;</td>
                                        <td><?php echo h($ClassRoom['academic_year']); ?>&nbsp;</td>
                                        <td><?php echo h($ClassRoom['employee_name']); ?>&nbsp;</td>
                                        <td><?php echo h($ClassRoom['created_at']); ?>&nbsp;</td>
                                        <td>
                                            <a target="__blank" href="<?php echo DOMAIN_NAME ?>/exams/view/<?php echo $ClassRoom['cls_yr_id']; ?>" class="btn btn-info btn-xs">
                                                <i class="fa fa-eye"></i> View</a>
                                        </td>
                                    </tr>
                                <?php endforeach; ?>
                                </tbody>
                                <tfoot>
                                <tr>
                                    <th>#</th>
                                    <th>Class Name</th>
                                    <th>Academic Year</th>
                                    <th>Head Tutor</th>
                                    <th>Date Assign</th>
                                    <th>View Students</th>
                                </tr>
                                </tfoot>
                            <?php else :?>
                                <tr><th>No Class Has Been Assign to you Yet</th></tr>
                            <?php endif;?>
                        </table>
                    </div> <!-- /panel body -->
                </div>
            </div> <!-- /panel body -->
        </div>
    </div>
</div>
<?php
//on click of Manage Students link... activate the link
echo $this->Js->buffer('
        setTabActive("[href=\"'.DOMAIN_NAME.'/classrooms/myclass\"]", 1);
    ');
?> 
 