<?php echo $this->Html->script("../app/jquery/custom.employee.js", FALSE);?>
<?php echo $this->Html->script("../app/js/bootstrap-datatables.js", FALSE);?>
<?php echo $this->Html->script("../app/js/dataTables-custom.js", FALSE);?>
<?php 
    App::uses('Encryption', 'Utility'); 
    $Encryption = new Encryption();
    
    $employee_delete = Configure::read('employee_delete');
?>

<?php //echo $this->Html->script("../app/js/prettify.js", FALSE);?>


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
                        <h4>Manage List of Employees by Editing, Viewing or Deleting </h4>
                    </div>
                </div>
            </div>
        </div>
        <!-- / Info Boxes -->
        <div class="panel-heading text-primary">
            <h3 class="panel-title">
               <i class="fa fa-list"></i> Manage Staffs' Information
                <span class="pull-right">
                    <a href="javascript:void(0)"  title="Refresh"><i class="fa fa-refresh"></i></a>
                    <a href="#" class="panel-minimize"><i class="fa fa-chevron-up"></i></a>
                    <a href="#" class="panel-close"><i class="fa fa-times"></i></a>
                </span>
            </h3>
        </div>
        <div class="panel-body">
            <div class="panel panel-info">
                <div class="panel-heading panel-title  text-white">Staff's Table</div>
                <div style="overflow-x: scroll" class="panel-body">
                   <table  class="table table-bordered table-hover table-striped display" id="employee_table" >
                     <thead>
                      <tr>
                       <th>ID</th>
                       <th>Title</th>
                       <th>Full Name</th>
                       <th>Email</th>
                       <th>Phone No.</th>
                       <th>Status</th>
                       <th>View</th>
                       <th>Edit</th>
                       <?php if($employee_delete):?>
                        <th>Delete</th>
                       <?php endif;?>
                     </tr>
                   </thead>
                   <tbody>
                       <?php foreach ($employees as $employee): ?>
                      <tr class="gradeA">
                          <?php 
                            $encrypted_employee_id = $Encryption->encode($employee['Employee']['employee_id']);
                          ?>
                          <td><?php echo h($employee['Employee']['employee_no']); ?>&nbsp;</td>
                          <td><?php echo h($employee['Salutation']['salutation_abbr']); ?>&nbsp;</td>
                          <td><?php echo h($employee['Employee']['first_name']), ' ', h($employee['Employee']['other_name']); ?>&nbsp;</td>
                          <td><?php echo ($employee['Employee']['email']) ? $employee['Employee']['email'] : '<span class="label label-danger">nill</span>'; ?>&nbsp;</td>
                          <td><?php echo h($employee['Employee']['mobile_number1']); ?>&nbsp;</td>
                          <td>
                              <?php 
                                if(h($employee['Employee']['status_id']) === '1'){
                                    echo '<button title="'.$employee['Employee']['status_id'].'" value="'.$employee['Employee']['employee_id'].'" class="btn btn-success btn-xs employee_status_edit">'
                                        . '<i class="fa fa-check-square-o fa-1x"></i><span class="label label-success"> '.$employee['Status']['status'].'</span></button>';
                                }else{
                                    echo '<button title="'.$employee['Employee']['status_id'].'" value="'.$employee['Employee']['employee_id'].'" class="btn btn-danger  btn-xs employee_status_edit">'
                                        . '<i class="fa fa-times-circle-o fa-1x"></i><span class="label label-danger"> '.$employee['Status']['status'].'</span></button>';
                                }
                             ?>
                          </td>
                          <td><a target="__blank" href="<?php echo DOMAIN_NAME ?>/employees/view/<?php echo $encrypted_employee_id; ?>" class="btn btn-info btn-xs"><i class="fa fa-eye"></i> View</a></td>
                          <td><a href="<?php echo DOMAIN_NAME ?>/employees/adjust/<?php echo $encrypted_employee_id; ?>" class="btn btn-warning btn-xs"><i class="fa fa-edit"></i> Edit</a></td>
                          <?php if($employee_delete):?>
                            <td><button class="demo btn pull-right btn-danger btn-xs btn-delete delete_employee" value="<?php echo $encrypted_employee_id; ?>" data-toggle="modal" href="#employee_delete_modal"><i class="fa fa-trash-o"></i> Delete</button></td>
                          <?php endif;?> 
                      </tr>
                      <?php endforeach; ?>
                     </tbody>
                     <tfoot>
                      <tr>
                       <th>ID</th>
                       <th>Title</th>
                       <th>Full Name</th>
                       <th>Email</th>
                       <th>Phone No.</th>
                       <th>Status</th>
                       <th>View</th>
                       <th>Edit</th>
                       <?php if($employee_delete):?>
                        <th>Delete</th>
                       <?php endif;?> 
                     </tr>
                   </tfoot>
                 </table>
               </div> <!-- /panel body -->
            </div>
        </div> <!-- /panel body -->    
    </div> <!-- /panel-->
    <!-- Modal Definitions (tabbed over for <pre>) -->
    <div id="employee_delete_modal" class="modal fade" tabindex="-1" data-width="400" style="display: none;">
       <div class="modal-header">
           <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
           <h4 class="modal-title">Deleting A Staff Record</h4>
       </div>
        <form action="#" id="employee_delete_form" method="post">
            <div class="modal-body">
                <div class="row">
                    <div class="col-md-12">
                        <p>Are You Sure You Want To Delete This Record</p>
                    </div>
                </div>
            </div>
            <div class="modal-footer">
                <input type="hidden" name="hidden_employee_id" id="hidden_employee_id" value="">                                    
                <button type="button" data-dismiss="modal" class="btn btn-default">Close</button>
                <button type="submit" class="btn btn-primary">Yes Delete</button>
            </div>
        </form>
   </div>
</div>
<?php
    //on click of Manage Sponsors Record link... activate the link
    echo $this->Js->buffer('
        setTabActive("[href=\"'.DOMAIN_NAME.'/employees/\"]", 1);
    ');
?>