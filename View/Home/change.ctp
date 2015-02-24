<?php echo $this->Html->script("../web/js/custom.home.js", FALSE);?>

<!-- Start Content-->
<section id="content">
    <div class="container">
        <!-- Info Boxes -->
        <div class="row">
            <div class="span12">
                <div class="info-box  bg-info  text-white">
                    <div class="info-icon bg-info-dark">
                        <i class="fa fa-lock fa-4x"></i>
                    </div> 
                    <div class="info-details">
                        <h4>Change Your Current Password with a new one </h4>
                    </div> 
                </div>
            </div>
        </div>
        <div class="row">
            <div class="span12">
                <div class="panel-body">
                    <div class="panel panel-default">
                        <div class="panel-body">
                            <?php 
                                //Creates The Form
                                echo $this->Form->create('User', array(
                                        //'action' => 'search',
                                        'class' => 'validateform',
                                        'id' => 'change_pass_form'
                                    )
                                );     
                            ?>
                                <div class="row">
                                    <label for="old_pass" >Old Password</label>
                                    <div class="span4 field">
                                        <input type="password" name="data[User][old_pass]" 
                                        id="old_pass" placeholder="Old Password" required="required">
                                    </div>
                                    <label for="new_pas" >New Password</label>
                                    <div class="span4 field">
                                        <input type="password" name="data[User][new_pass]" 
                                        id="new_pass" placeholder="New Password" required="required">
                                    </div>
                                    <label for="new_pas2">Confirm Password</label>
                                    <div class="span4 field">
                                        <input type="password" name="data[User][new_pass2]" 
                                        id="new_pass2" placeholder="Confirm Password" required="required">
                                    </div>
                                    <div class="span10 margintop10 field">
                                        <button type="submit" class="btn btn-theme margintop10">Change Password </button>
                                        <button type="reset" class="btn btn-warning margintop10">Reset </button>
                                    </div>
                                </div>
                            </form>					
                        </div>
                    </div>
                                    
                </div>
            </div>
        </div>
    </div>	
</section>
<!-- End Content-->