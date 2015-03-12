<?php echo $this->Html->script("../app/js/bootstrap-datatables.js", FALSE);?>
<?php echo $this->Html->script("../app/js/dataTables-custom.js", FALSE);?>
<?php echo $this->Html->script("../app/jquery/custom.sponsor.js", FALSE);?>
<?php 
    App::uses('Encryption', 'Utility'); 
    $Encryption = new Encryption();
    
    $sponsor_delete = Configure::read('sponsor_delete');
    
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
                        <h4>Mange List of Sponsors by Editing, Viewing or Deleting </h4>
                    </div>
                </div>
            </div>
        </div>
        <!-- / Info Boxes -->
        <div class="panel-heading text-primary">
            <h3 class="panel-title">
                <i class="fa fa-list"></i>
               Manage Sponsors Information<label class="label label-primary">Mange List of Sponsors by Editing, Viewing or Deleting</label>
                <span class="pull-right">
                    <a href="javascript:void(0)"  title="Refresh"><i class="fa fa-refresh"></i></a>
                    <a href="#" class="panel-minimize"><i class="fa fa-chevron-up"></i></a>
                    <a href="#" class="panel-close"><i class="fa fa-times"></i></a>
                </span>
            </h3>
        </div>
        <div class="row">
            <div class="col-md-11">
                <div class="panel-body">
                    <div class="panel panel-info">
                        <div class="panel-heading panel-title  text-white">Sponsor's Table</div>
                        <div style="overflow-x: scroll" class="panel-body">
                            <table  class="table table-bordered table-hover table-striped display" id="sponsor_table" >
                                <thead>
                                   <tr>
                                    <th>ID.</th>
                                    <th>Title</th>
                                    <th>Full Names</th>
                                    <th>Email</th>
                                    <th>Phone No.</th>
                                    <!--th>Sponsorship</th-->
                                    <th>View</th>
                                    <th>Edit</th>
                                    <?php if($sponsor_delete):?>
                                      <th>Delete</th>
                                    <?php endif;?>
                                  </tr>
                                </thead>
                                <tbody>
                                   <?php foreach ($sponsors as $sponsor): ?>
                                   <tr class="gradeA">
                                       <?php 
                                            $encrypted_sponsor_id = $Encryption->encode($sponsor['Sponsor']['sponsor_id']);
                                        ?>
                                       <td><?php echo h($sponsor['Sponsor']['sponsor_no']); ?>&nbsp;</td>
                                       <td><?php echo h($sponsor['Salutation']['salutation_abbr']); ?>&nbsp;</td>
                                       <td><?php echo h($sponsor['Sponsor']['first_name']), ' ', (empty($sponsor['Sponsor']['other_name'])) ? '' : $sponsor['Sponsor']['other_name']; ?>&nbsp;</td>
                                       <td><?php echo (empty($sponsor['Sponsor']['email'])) ? '<span class="label label-danger">nill</span>' : $sponsor['Sponsor']['email']; ?>&nbsp;</td>
                                       <td><?php echo h($sponsor['Sponsor']['mobile_number1']); ?>&nbsp;</td>
                                       <!--td><?php //echo h($sponsor['SponsorshipType']['sponsorship_type']); ?>&nbsp;</td-->
                                       <td><a target="__blank" href="<?php echo DOMAIN_NAME; ?>/sponsors/view/<?php echo $encrypted_sponsor_id; ?>" class="btn btn-info btn-xs"><i class="fa fa-eye"></i> View</a></td>
                                       <td><a href="<?php echo DOMAIN_NAME ?>/sponsors/adjust/<?php echo $encrypted_sponsor_id; ?>" class="btn btn-warning btn-xs"><i class="fa fa-edit"></i> Edit</a></td>
                                       <?php if($sponsor_delete):?>
                                        <td><button class="demo btn pull-right btn-danger btn-xs btn-delete delete_sponsor" value="<?php echo $encrypted_sponsor_id; ?>" data-toggle="modal" href="#sponsor_delete_modal"><i class="fa fa-trash-o"></i> Delete</button></td>
                                       <?php endif;?>
                                   </tr>
                                   <?php endforeach; ?>
                                  </tbody>
                                  <tfoot>
                                   <tr>
                                   <th>ID.</th>
                                    <th>Title</th>
                                    <th>Full Names</th>
                                    <th>Email</th>
                                    <th>Phone No.</th>
                                    <!--th>Sponsorship</th-->
                                    <th>View</th>
                                    <th>Edit</th>
                                    <?php if($sponsor_delete):?>
                                      <th>Delete</th>
                                    <?php endif;?>
                                  </tr>
                                </tfoot>
                            </table>
                        </div> <!-- /panel body -->
                    </div>
                </div> <!-- /panel body -->    
            </div>
        </div>
    </div>
 
    <div id="sponsor_delete_modal" class="modal fade" tabindex="-1" data-width="400" style="display: none;">
       <div class="modal-header">
           <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
           <h4 class="modal-title">Deleting A Sponsor Record</h4>
       </div>
        <form action="#" id="sponsor_delete_form" method="post">
            <div class="modal-body">
                <div class="row">
                    <div class="col-md-12">
                        <p>Are You Sure You Want To Delete This Record</p>
                    </div>
                </div>
            </div>
            <div class="modal-footer">
                <input type="hidden" name="hidden_sponsor_id" id="hidden_sponsor_id" value="">                                    
                <button type="button" data-dismiss="modal" class="btn btn-default">Close</button>
                <button type="submit" class="btn btn-primary">Yes Delete</button>
            </div>
        </form>
   </div>
 </div> <!-- /col-md-12 -->
 <?php
    //on click of Manage Sponsors Record link... activate the link
    echo $this->Js->buffer('
        setTabActive("[href=\"'.DOMAIN_NAME.'/sponsors/\"]", 1);
    ');
?>