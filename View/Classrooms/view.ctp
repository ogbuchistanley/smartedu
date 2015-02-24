<!-- Page Scripts =============================-->
<?php echo $this->Html->script("../app/js/bootstrap-datatables.js", FALSE);?>
<?php echo $this->Html->script("../app/js/dataTables-custom.js", FALSE);?>
<?php echo $this->Html->script("../app/jquery/custom.classroom.js", FALSE);?>

<div class="col-md-12">
    <div class="panel">
        <!-- Info Boxes -->
        <div class="row">
            <div class="col-md-12">
                <div class="info-box  bg-info  text-white">
                    <div class="info-icon bg-info-dark">
                        <i class="fa fa-group fa-4x"></i>
                    </div> 
                    <div class="info-details">
                        <h4>List of  Students Assigned To The Class</h4>
                    </div> 
                </div>
            </div>
        </div>
        <!-- / Info Boxes -->
        <div class="panel-heading text-primary">
            <h3 class="panel-title">                
               <i class="fa fa-male"></i>
                Students Assigned
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
                    <div class="panel-heading panel-title  text-white">Table Displaying List of Students Assigned</div>
                    <div style="overflow-x: scroll" class="panel-body">
                        <table  class="table table-bordered table-hover table-striped display custom_tables">
                            <?php if(!empty($Students['StudentsClass'])):?>
                            <thead>
                             <tr>
                                <th>#</th>
                                <th>No.</th>
                                <th>Full Name</th>
                                <th>Gender</th>
                                <th>Birth Date</th>
                                <th>Class</th>
                                <th>Details</th>
                            </tr>
                          </thead>
                          <tbody>
                              <?php $i=1; foreach ($Students['StudentsClass'] as $Student): ?>
                             <tr class="gradeA">
                                 <td><?php echo $i++; ?></td>
                                 <td><?php echo h($Student['student_no']); ?>&nbsp;</td>
                                 <td><?php echo h($Student['first_name']), ' ', h($Student['surname']), ' ', h($Student['other_name']); ?>&nbsp;</td>
                                 <td><?php echo h($Student['gender']); ?>&nbsp;</td>
                                 <td><?php echo h($Student['birth_date']); ?>&nbsp;</td>                             
                                 <td><?php echo h($Student['class_name']); ?>&nbsp;</td>                             
                                 <td>
                                    <a target="__blank" href="<?php echo DOMAIN_NAME ?>/students/view/<?php echo $Student['hashed_id']; ?>" class="btn btn-primary btn-xs">
                                    <i class="fa fa-eye"></i> View</a>
                                 </td>
                             </tr>
                             <?php endforeach; ?>
                            </tbody>
                            <tfoot>
                             <tr>
                                <th>#</th>
                                <th>No.</th>
                                <th>Full Name</th>
                                <th>Gender</th>
                                <th>Birth Date</th>
                                <th>Class</th>
                                <th>Details</th>
                            </tr>
                          </tfoot>
                          <?php else :?>
                            <tr><th>No Student Has Been Assign To The Class Yet</th></tr>
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
 