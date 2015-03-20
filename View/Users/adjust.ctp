<?php echo $this->Html->script("../app/jquery/custom.user.js", FALSE);?>

<div class="col-md-12">
    <div class="panel">
        <!-- Info Boxes -->
        <!--div class="row">
            <div class="col-md-12">
                <div class="info-box  bg-info  text-white">
                    <div class="info-icon bg-info-dark">
                        <i class="fa fa-user fa-4x"></i>
                    </div>
                    <div class="info-details">
                        <h4>Please fill the form properly and modify accurately...</h4>
                    </div>
                </div>
            </div>
        </div>
        <!-- / Info Boxes -->
        <div class="panel-heading">
            <h3 class="panel-title">
                <i class="fa fa-user"></i>
               Adjust User's Access Level
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
            <div class="col-md-10">
                <div class="panel panel-cascade">
                    <div class="panel-body">
                        <div class="panel panel-default">
                            <div class="panel-heading">Change User Access Level or Disable the user from Accessing the Application by expiring the access status</div>
                            <div class="panel-body">
                                <?php 
                                    //Creates The Form
                                    echo $this->Form->create('User', array(
                                            //'url' => '/users/adjust/'.base64_encode($user['User']['user_id']),
                                            'class' => 'form-horizontal',
                                            'novalidate' => 'novalidate',
                                            'id' => 'user_form'
                                        )
                                    );     
                                ?>

                                <!--form class="form-horizontal" action="register" role="form" method="post"-->
                                    <?php 
                                        $user_category = 'User';
                                        if($user['User']['user_role_id'] == 1){
                                            $user_category = 'Parent';
                                        }else if($user['User']['user_role_id'] == 2){
                                            $user_category = 'Students';
                                        }else if($user['User']['user_role_id'] > 2){
                                            $user_category = 'Staff';
                                        }
                                    ?>
                                    <div class="form-group">
                                        <label class="col-sm-3 control-label">User Category</label>
                                        <div class="col-sm-8 text-success">
                                            <label class="col-sm-6 " style="font-size: 15px;"><b><?php echo $user_category;?></b></label>
                                        </div>
                                    </div>
                                    <div class="form-group">
                                        <label for="username" class="col-sm-3 control-label">Username</label>
                                        <div class="col-sm-8 text-success">
                                            <label class="col-sm-6" style="font-size: 15px;"><b><?php echo $user['User']['username']?></b></label>
                                        </div>
                                    </div>
                                    <div class="form-group">
                                        <label for="display_name" class="col-sm-3 control-label">Display Name</label>
                                        <div class="col-sm-8 text-success">
                                            <label class="col-sm-6" style="font-size: 15px;"><b><?php echo $user['User']['display_name']?></b></label>
                                        </div>
                                    </div>
                                    <div class="form-group">
                                        <label for="user_role_id" class="col-sm-3  control-label">User Role</label>
                                        <div class="col-sm-8">
                                            <?php 
                                                echo $this->Form->input('user_role_id', array(
                                                        'div' => false,
                                                        'label' => false,
                                                        'class' => 'form-control form-cascade-control',
                                                        'id' => 'user_role_id',
                                                        'options' => $UserRoles,
                                                        'empty' => '(Select User Role)'
                                                    )
                                                ); 
                                            ?>
                                        </div>
                                    </div>
                                    <div class="form-group">
                                        <label for="status_id" class="col-sm-3 control-label">User Access Status</label>
                                        <div class="col-sm-8">
                                            <?php 
                                                echo $this->Form->input('status_id', array(
                                                        'div' => false,
                                                        'label' => false,
                                                        'class' => 'form-control form-cascade-control',
                                                        'id' => 'status_id',
                                                        'options' => $Statuss,
                                                        'empty' => '(Select User\'s Status)'
                                                    )
                                                );  
                                            ?>
                                        </div>
                                     </div>
                                    <div class="form-group">
                                        <div class="col-sm-offset-4 col-sm-10">
                                            <button type="submit" class="btn btn-primary">Update User</button>
                                        </div>
                                    </div>
                                </form>	
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>	
</div>
<?php
    //on click of Edit User Record link... activate the link
    echo $this->Js->buffer('
        setTabActive("[href=\"'.DOMAIN_NAME.'/users/index\"]", 0);
    ');
?>