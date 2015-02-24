<?php echo $this->Html->script("../app/jquery/custom.user.js", FALSE);?>
<?php //echo $new;?>
<div class="col-md-12">
    <div class="panel">
        <!-- Info Boxes -->
        <div class="row">
            <div class="col-md-12">
                <div class="info-box  bg-info  text-white">
                    <div class="info-icon bg-info-dark">
                        <i class="fa fa-lock fa-4x"></i>
                    </div> 
                    <div class="info-details">
                        <h4>Password Management </h4>
                    </div> 
                </div>
            </div>
        </div>
        <!-- / Info Boxes -->
        <div class="panel-heading text-primary">
            <h3 class="panel-title">                
               <i class="fa fa-unlock"></i>
               Change Your Current Password
                <span class="pull-right">
                        <a href="javascript:void(0)"  title="Refresh"><i class="fa fa-refresh"></i></a>
                        <a href="#" class="panel-minimize"><i class="fa fa-chevron-up"></i></a>
                        <a href="#" class="panel-close"><i class="fa fa-times"></i></a>
                </span>
            </h3>
        </div>
        <div class="panel-body">
            <div class="panel panel-default">
                <div class="panel-body">
                    <div class="tab-pane fade in active"><br>
                        <div class="col-md-6">
                            <div class="panel panel-cascade">
                                <div class="panel panel-default">
                                    <div class="panel-heading">Change Your Current Password with a new one</div> 
                                    <div class="panel-body">
                                        <?php 
                                            //Creates The Form
                                            echo $this->Form->create('User', array(
                                                    'action' => 'search',
                                                    'class' => 'form-horizontal',
                                                    'id' => 'change_pass_form'
                                                )
                                            );     
                                        ?>
                                            <div class="form-group">
                                                <label for="old_pass" class="col-sm-5 control-label">Old Password</label>
                                                <div class="col-sm-7">
                                                    <input type="password" class="form-control form-cascade-control input-small" name="data[User][old_pass]" 
                                                    id="old_pass" placeholder="Old Password" required="required">
                                                </div>
                                            </div>
                                            <div class="form-group">
                                                <label for="new_pas" class="col-sm-5 control-label">New Password</label>
                                                <div class="col-sm-7">
                                                    <input type="password" class="form-control form-cascade-control input-small" name="data[User][new_pass]" 
                                                    id="new_pass" placeholder="New Password" required="required">
                                                </div>
                                            </div>
                                            <div class="form-group">
                                                <label for="new_pas2" class="col-sm-5 control-label">Confirm Password</label>
                                                <div class="col-sm-7">
                                                    <input type="password" class="form-control form-cascade-control input-small" name="data[User][new_pass2]" 
                                                    id="new_pass2" placeholder="Confirm Password" required="required">
                                                </div>
                                            </div>
                                            <div class="form-group">
                                                <div class="col-sm-offset-2 col-sm-10">
                                                    <button type="submit" class="btn btn-info" id="pass_change_btn">Change Password </button>
                                                    <button type="reset" class="btn btn-warning">Reset </button>
                                                </div>
                                            </div>
                                        </form>					
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div class="col-md-6" id="msg_box3">   </div>
                    </div>
                </div>
            </div>
        </div>
    </div>	
</div>

<?php
    //on click of Change Password link... activate the link
    echo $this->Js->buffer('
        setTabActive("[href=\"'.DOMAIN_NAME.'/users/change\"]", 1);
    ');
?>