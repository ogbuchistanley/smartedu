<?php //echo $this->Html->script("../app/jquery/jquery.textareaCounter.plugin.js", FALSE);?>
<?php echo $this->Html->script("../app/jquery/custom.message.js", FALSE);?>
<?php echo $this->Html->script("../app/js/bootstrap-datatables.js", FALSE);?>
<?php echo $this->Html->script("../app/js/dataTables-custom.js", FALSE);?>
<?php 
    App::uses('Encryption', 'Utility'); 
    $Encryption = new Encryption();
    
    $recipient_delete = Configure::read('employee_delete');  
?>

<?php //echo $this->Html->script("../app/js/prettify.js", FALSE);?>


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
                        <h4>Manage List of Message Recipients by Adding, Editing or Deleting </h4>
                    </div>
                </div>
            </div>
        </div>
        <!-- / Info Boxes -->
        <div class="panel-heading text-primary">
            <h3 class="panel-title">
               <i class="fa fa-user"></i> Manage Message Recipients' Information
                <span class="pull-right">
                    <a href="javascript:void(0)"  title="Refresh"><i class="fa fa-refresh"></i></a>
                    <a href="#" class="panel-minimize"><i class="fa fa-chevron-up"></i></a>
                    <a href="#" class="panel-close"><i class="fa fa-times"></i></a>
                </span>
            </h3>
        </div>
        <div class="row">
            <div class="col-md-8 col-md-offset-2">
                <div class="panel-body">
                    <div class="panel panel-default">
                        <div class="panel-heading bg-primary-dark text-white"><i class="fa fa-plus fa-1x"></i> Add New Recipient / <i class="fa fa-edit fa-1x"></i> Edit Existing Recipient</div>                                            
                        <div class="panel-body">
                            <?php 
                                //Creates The Form
                                echo $this->Form->create('MessageRecipient', array(
                                        'class' => 'form-horizontal'
                                    )
                                );     
                            ?>
                            <?php if(!empty($Recipient)) :?>
                                <div class="form-group">
                                    <label for="recipient_name" class="col-lg-3 col-md-3 control-label">Recipient Name</label>
                                    <div class="col-lg-7 col-md-9">
                                        <input type="text" class="form-control form-cascade-control input-small" name="data[MessageRecipient][recipient_name]" 
                                            id="recipient_name" value="<?php echo $Recipient['MessageRecipient']['recipient_name']?>" placeholder="Recipient Name" required="required">
                                    </div>
                                </div>
                                <div class="form-group">
                                    <label for="mobile_number" class="col-lg-3 col-md-3 control-label">Mobile Number</label>
                                    <div class="col-lg-7 col-md-9">
                                        <input type="text" class="form-control form-cascade-control input-small" name="data[MessageRecipient][mobile_number]" 
                                            id="mobile_number" value="<?php echo $Recipient['MessageRecipient']['mobile_number']?>" placeholder="Mobile Number" required="required">
                                    </div>
                                </div>
                                <div class="form-group">
                                    <label for="email" class="col-lg-3 col-md-3 control-label">Recipient Email</label>
                                    <div class="col-lg-7 col-md-9">
                                        <input type="email" class="form-control form-cascade-control input-small" name="data[MessageRecipient][email]" 
                                            id="email" value="<?php echo $Recipient['MessageRecipient']['email']?>" placeholder="Recipient Email if Any">
                                    </div>
                                </div>
                            <?php else :?>
                                <div class="form-group">
                                    <label for="recipient_name" class="col-lg-3 col-md-3 control-label">Recipient Name</label>
                                    <div class="col-lg-7 col-md-9">
                                        <input type="text" class="form-control form-cascade-control input-small" name="data[MessageRecipient][recipient_name]" 
                                            id="recipient_name" placeholder="Recipient Name" required="required">
                                    </div>
                                </div>
                                <div class="form-group">
                                    <label for="mobile_number" class="col-lg-3 col-md-3 control-label">Mobile Number</label>
                                    <div class="col-lg-7 col-md-9">
                                        <input type="text" class="form-control form-cascade-control input-small" name="data[MessageRecipient][mobile_number]" 
                                            id="mobile_number" placeholder="Mobile Number" required="required">
                                    </div>
                                </div>
                                <div class="form-group">
                                    <label for="email" class="col-lg-3 col-md-3 control-label">Recipient Email</label>
                                    <div class="col-lg-7 col-md-9">
                                        <input type="email" class="form-control form-cascade-control input-small" name="data[MessageRecipient][email]" 
                                            id="email" placeholder="Recipient Email if Any">
                                    </div>
                                </div>
                            <?php endif;?>
                                <div class="form-group"><br>
                                    <div class="col-sm-offset-2 col-sm-9">
                                        <button type="submit" class="btn btn-success">Save Record</button>
                                    </div>
                                </div>
                            </form>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        <div class="col-md-12">
            <div class="panel-body">
                <div class="panel panel-info">
                    <div class="panel-heading panel-title  text-white">Recipient's Table</div>
                       <table  class="table table-bordered table-hover table-striped display" >
                           <?php if(!empty($MessageRecipients)) :?>
                                <div class="col-sm-offset-4 col-sm-10"><br>
                                   <button type="button" class="mark_btn_rcp btn btn-success">Mark All</button>
                                   <button type="button" class="msg_all_mark_rcp btn btn-primary" value="RCP">Message Marked Recipients</button>
                                   <span style="font-size: medium" class="label label-danger err"></span><br>
                               </div>
                              <thead>
                               <tr>
                                <th>#</th>
                                <th>ID.</th>
                                <th>Recipient Name</th>
                                <th>Mobile Number</th>
                                <th>Email</th>
                                <th>Mark</th>
                                <th>Send</th>
                                <th>Edit</th>
                                <th>Delete</th>
                              </tr>
                            </thead>
                            <tbody>
                                <?php $i=1; foreach ($MessageRecipients as $recipient): ?>
                               <tr class="gradeA">
                                   <?php 
                                     $encrypted_recipient_id = $Encryption->encode($recipient['MessageRecipient']['message_recipient_id'] . '/RCP');
                                   ?>
                                   <td><?php echo $i++;?></td>
                                   <td><?php echo 'RCP' . str_pad($recipient['MessageRecipient']['message_recipient_id'], 4, '0', STR_PAD_LEFT); ?>&nbsp;</td>
                                   <td><?php echo h($recipient['MessageRecipient']['recipient_name']); ?>&nbsp;</td>
                                   <td><?php echo h($recipient['MessageRecipient']['mobile_number']); ?>&nbsp;</td>
                                   <td><?php echo (empty($recipient['MessageRecipient']['email'])) ? '<span class="label label-danger">nill</span>' : $recipient['MessageRecipient']['email']; ?>&nbsp;</td>
                                   <td><input type="checkbox" value="<?php echo $recipient['MessageRecipient']['message_recipient_id']?>" class="message_check_rcp"></td>
                                   <td>
                                       <button class="btn btn-success btn-xs send_message_recipient" value="<?php echo $recipient['MessageRecipient']['message_recipient_id']; ?>" data-toggle="modal" href="#recipient_message_modal">
                                           <i class="fa fa-envelope"></i> Send
                                       </button>
                                   </td>
                                   <td><a href="<?php echo DOMAIN_NAME ?>/messages/recipient/<?php echo $encrypted_recipient_id; ?>" class="btn btn-warning btn-xs"><i class="fa fa-edit"></i> Edit</a></td>
                                   <td>
                                       <button class="btn btn-danger btn-xs btn-delete delete_recipient" value="<?php echo $encrypted_recipient_id; ?>" data-toggle="modal" href="#recipient_delete_modal">
                                           <i class="fa fa-trash-o"></i> Delete
                                       </button>
                                   </td>
                               </tr>
                               <?php endforeach; ?>

                              </tbody>
                              <tfoot>
                               <tr>
                                 <th>#</th>
                                <th>ID.</th>
                                <th>Recipient Name</th>
                                <th>Mobile Number</th>
                                <th>Email</th>
                                <th>Mark</th>
                                <th>Send</th>
                                <th>Edit</th>
                                <th>Delete</th>
                              </tr>
                            </tfoot>
                          <?php else: ?> 
                            <div class="form-group">
                                <div class="col-sm-offset-2 col-sm-10">
                                    <span style="font-size: larger" class="text-info">No Recipient Found</span>
                                </div>
                            </div>
                          <?php endif; ?>  
                       </table>
                    <?php if(!empty($MessageRecipients)) :?>
                        <div class="form-group">
                            <div class="col-sm-offset-2 col-sm-10"><br><br><br>
                                <button type="button" class="mark_btn_rcp btn btn-success">Mark All</button>
                                <button type="button" class="msg_all_mark_rcp btn btn-primary" value="RCP">Message Marked Recipients</button>
                                <span style="font-size: medium" class="label label-danger err"></span>
                            </div>
                        </div>
                    <?php endif; ?>  
                </div>
            </div> <!-- /panel body -->  
        </div>
    </div> <!-- /panel-->
    <!-- Modal Definitions (tabbed over for <pre>) -->
    <div id="recipient_delete_modal" class="modal fade" tabindex="-1" data-width="400" style="display: none;">
       <div class="modal-header">
           <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
           <h4 class="modal-title">Deleting An Recipient Record</h4>
       </div>
        <form action="#" id="recipient_delete_form" method="post">
            <div class="modal-body">
                <div class="row">
                    <div class="col-md-12">
                        <p>Are You Sure You Want To Delete This Record</p>
                    </div>
                </div>
            </div>
            <div class="modal-footer">
                <input type="hidden" name="hidden_recipient_id" id="hidden_recipient_id" value="">                                    
                <button type="button" data-dismiss="modal" class="btn btn-default">Close</button>
                <button type="submit" class="btn btn-primary">Yes Delete</button>
            </div>
        </form>
   </div>
    <!-- Modal Definitions (tabbed over for <pre>) -->
    <div id="recipient_message_modal" class="modal fade" tabindex="-1" data-width="600" style="display: none;">
       <div class="modal-header">
           <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
           <h4 class="modal-title">Sending Message To Recipient</h4>
       </div>
        <div class="panel panel-default">
            <div class="panel-heading bg-primary-dark text-white"><i class="fa fa-envelope-o fa-1x"></i> S.M.S / e-mail Message Form for Recipient</div>                                            
            <div class="panel-body">
                <?php 
                    //Creates The Form
                    echo $this->Form->create('Send', array(
                            'class' => 'form-horizontal',
                            'id' => 'recipient_message_form'
                        )
                    );     
                ?>

                    <div class="form-group">
                        <label for="subject" class="col-lg-3 col-md-3 control-label">Message Subject</label>
                        <div class="col-lg-7 col-md-9">
                            <input type="text" class="form-control form-cascade-control input-small" name="data[Send][subject]" 
                                   id="subject" maxlength="11" placeholder="Message Subject" required="required">
                        </div>
                    </div>
                    <div class="form-group">
                        <label for="subject" class="col-lg-3 col-md-3 control-label">Sending Options</label>
                        <div class="col-lg-7 col-md-9">
                            <div class="radio">
                                <label><input type="radio" name="data[Send][option]" id="sms" value="1">S.M.S Only</label>
                            </div>
                            <div class="radio">
                                <label><input type="radio" name="data[Send][option]" id="sms_email" value="2" checked="checked">S.M.S and e-mail</label>
                            </div>
                        </div>
                    </div>
                    <div class="form-group">
                        <label for="message" class="col-lg-3 col-md-3 control-label">Message Body</label>
                        <div class="col-lg-7 col-md-9">
                            <textarea rows="7" class="form-control form-cascade-control input-small" name="data[Send][message]" 
                            id="message" placeholder="Message Body" required="required"></textarea>
                        </div>
                    </div>
                <div id="msg_box"></div>
                    <div class="form-group">
                        <div class="col-sm-offset-2 col-sm-9">
                            <input type="hidden" name="data[Send][hidden_id]" id="hidden_id" value=""> 
                            <input type="hidden" name="data[Send][type]" id="type" value="RCP">
                            <button type="submit" class="btn btn-success">Send Message</button>
                        </div>
                    </div>
                </form>
            </div>
        </div>
   </div>
</div>