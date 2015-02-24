<!-- Basic Form-->
<div class="row">
    <div class="col-md-2"></div>
    <div class="col-md-8">
        <div class="panel panel-cascade">
            <div class="panel-heading">
                <h3 class="panel-title">
                    New User  Form
                    <span class="pull-right">
                        <a  href="#" class="panel-minimize"><i class="fa fa-chevron-up"></i></a>
                        <a  href="#"  class="panel-close"><i class="fa fa-times"></i></a>
                    </span>
                </h3>
            </div>
            <div class="panel-body">
                <?php 
                    //Creates The Form
                    echo $this->Form->create('User', array(
                            'action' => 'register',
                            'class' => 'form-horizontal',
                            'id' => 'user_form'
                        )
                    );     
                ?>
                <!--form class="form-horizontal" action="register" role="form" method="post"-->
                    <div class="form-group">
                        <label for="username" class="col-sm-3 control-label">Username</label>
                        <div class="col-sm-8">
                            <input type="text" name="data[User][username]" class="form-control form-cascade-control" id="username" placeholder="Username">
                        </div>
                    </div>
                    <div class="form-group">
                        <label for="password" class="col-sm-3 control-label">Password</label>
                        <div class="col-sm-8">
                            <input type="password" name="data[User][password]" class="form-control form-cascade-control" id="password" placeholder="Password">
                        </div>
                    </div>
                    <div class="form-group">
                        <label for="display_name" class="col-sm-3 control-label">Display Name</label>
                        <div class="col-sm-8">
                            <input type="text" name="data[User][display_name]" class="form-control form-cascade-control" id="display_name" placeholder="Display Name">
                        </div>
                    </div>
                    <div class="form-group">
                        <label for="user_role_id" class="col-sm-3  control-label">User Role</label>
                        <div class="col-sm-8">
                            <?php 
                                echo $this->Form->input('user_role_id', array(
                                        'div' => false,
                                        'label' => false,
                                        'class' => 'form-control',
                                        'id' => 'user_role_id',
                                        'options' => $UserRoles,
                                        'empty' => '(choose one)'
                                    )
                                ); 
                            ?>
                        </div>
                    </div>
                    <div class="form-group">
                        <div class="col-sm-offset-4 col-sm-10">
                            <button type="submit" class="btn btn-success">Create User</button>
                            <button type="reset" class="btn btn-primary">Reset</button>
                        </div>
                    </div>
                </form>					
            </div>
        </div>
    </div>
</div>