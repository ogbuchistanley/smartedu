<?php 
    App::uses('Encryption', 'Utility'); 
    $Encryption = new Encryption();
?>
<!-- Page Scripts =============================-->
<?php echo $this->Html->script("../app/js/bootstrap-editable.min.js", FALSE);?>
<?php echo $this->Html->script("../app/js/bootstrap-editable-custom.js", FALSE);?>

<?php echo $this->Html->script("../app/js/bootstrap-datatables.js", FALSE);?>
<?php echo $this->Html->script("../app/js/dataTables-custom.js", FALSE);?>

<?php echo $this->Html->script("../app/jquery/custom.user.js", FALSE); //echo $s, '<br>kyuthkj';?>
<?php $Employee = ClassRegistry::init('Employee');?>
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
                        <h4>Mange List of Users by Editing, Viewing or Deleting </h4>
                    </div>
                </div>
            </div>
        </div>
        <!-- / Info Boxes -->
        <div class="panel-heading">
            <h3 class="panel-title">
               <i class="fa fa-list"></i> Manage Users Information
                <span class="pull-right">
                    <div class="btn-group code">
                        <a href="javascript:void(0)"  title="Refresh"><i class="fa fa-refresh"></i></a>
                        <a href="#" class="panel-minimize"><i class="fa fa-chevron-up"></i></a>
                        <a href="#" class="panel-close"><i class="fa fa-times"></i></a>
                    </div>
                </span>
            </h3>
        </div>
        <div class="row">
            <div class="col-md-10">
                <div class="panel-body">
                    <div class="panel panel-info">
                        <div class="panel-heading panel-title  text-white">User's Table</div>
                        <div style="overflow-x: scroll" class="panel-body">
                            <table  class="table table-bordered table-hover table-striped display" id="user_table" >
                                <thead>
                                    <tr>
                                     <th>#</th>
                                     <th>Display Name</th>
                                     <th>Username</th>
                                     <th>User Role</th>
                                     <th>Created By</th>
                                     <th>Status</th>
                                     <th>Edit</th>
                                   </tr>
                                </thead>
                                <tbody>
                                <?php $i=1; foreach ($users as $user): ?>
                                  <?php 
                                    $encrypted_user_id = $Encryption->encode($user['User']['user_id']);
                                    $emp = $Employee->find('first', array('conditions' => array('Employee.employee_id' => $user['User']['created_by'])));
                                    $emp_name = (empty($emp['Employee']['first_name'])) ? '' : $emp['Employee']['first_name'].' '.$emp['Employee']['other_name'];
                                 ?>
                                    <tr class="gradeA">
                                        <td><?php echo $i++; ?></td>
                                        <td><?php echo h($user['User']['display_name']); ?>&nbsp;</td>
                                        <td><?php echo h($user['User']['username']); ?>&nbsp;</td>
                                        <td><?php echo h($user['UserRole']['user_role']); ?></td>
                                        <td><?php echo $emp_name; ?>&nbsp;</td>
                                        <td>
                                            <?php 
                                               if(h($user['User']['status_id']) === '1'){
                                                   echo '<button title="'.$user['User']['status_id'].'" value="'.$user['User']['user_id'].'" class="btn btn-success btn-xs user_status_edit">'
                                                       . '<i class="fa fa-check-square-o fa-1x"></i><span class="label label-success"> '.$user['Status']['status'].'</span></button>';
                                               }else{
                                                   echo '<button title="'.$user['User']['status_id'].'" value="'.$user['User']['user_id'].'" class="btn btn-danger  btn-xs user_status_edit">'
                                                       . '<i class="fa fa-times-circle-o fa-1x"></i><span class="label label-danger"> '.$user['Status']['status'].'</span></button>';
                                               }
                                            ?>
                                        </td>
                                        <td><a target="__blank" href="<?php echo DOMAIN_NAME ?>/users/adjust/<?php echo $encrypted_user_id; ?>" class="btn btn-warning btn-xs"><i class="fa fa-edit"></i> Edit</a></td>
                                   </tr>
                                   <?php endforeach; ?>
                                  </tbody>
                                  <tfoot>
                                    <tr>
                                     <th>#</th>
                                     <th>Display Name</th>
                                     <th>Username</th>
                                     <th>User Role</th>
                                     <th>Created By</th>
                                     <th>Status</th>
                                     <th>Edit</th>
                                   </tr>
                                 </tfoot>
                            </table>
                        </div>
                    </div>
                </div> <!-- /panel body -->  
            </div>
        </div>
    </div>
    
 </div> <!-- /col-md-12 -->
 <?php
    //on click of Manage User link... activate the link
    echo $this->Js->buffer('
        setTabActive("[href=\"'.DOMAIN_NAME.'/users/index\"]", 1);
    ');
?>
 