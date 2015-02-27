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
                        <h4>Start Your Free Trial Today </h4>
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
                                echo $this->Form->create('Setup', array(
                                        'action' => 'setup',
                                        'class' => 'validateform',
                                        'id' => 'setup_form'
                                    )
                                );     
                            ?>
                                <div class="row">
                                    <div class="form-group">
                                        <label for="school_name" >Your school's name:</label>
                                        <div class="field">
                                            <input type="text" name="data[Setup][school_name]"
                                            id="school_name" placeholder="Example: My School" required="required">
                                        </div>
                                    </div>
                                    <div class="form-group">
                                        <label for="full_name" >Your Name:</label>
                                        <div class="field">
                                            <input type="text" name="data[Setup][full_name]"
                                                   id="full_name" placeholder="Example John Doe" required="required">
                                        </div>
                                    </div>
                                    <div class="form-group">
                                        <label for="email" >Email address:</label>
                                        <span>This will be your username</span>
                                        <div class="field">
                                            <input type="text" name="data[Setup][email]"
                                                   id="email" placeholder="Example johndoe@yahoo.com" required="required">
                                        </div>
                                    </div>
                                    <div class="form-group">
                                        <label for="phone_number" >Phone number:</label>
                                        <div class="field">
                                            <input type="text" name="data[Setup][phone_number]"
                                                   id="phone_number" placeholder="Example xxxx xxxx xxx" required="required">
                                        </div>
                                    </div>
                                </div>
                                <div class="row">
                                    <div class="form-control">
                                        <label for="password" >Password:</label>
                                        <div class="field">
                                            <input type="password" name="data[Setup][password]" id="password" required="required">
                                        </div>
                                    </div>
                                    <div class="form-control">
                                        <label for="conform_password" >Confirm password:</label>
                                        <div class="field">
                                            <input type="password" name="data[Setup][conform_password]" id="conform_password" required="required">
                                        </div>
                                    </div>
                                    <div class="form-control">
                                        <label for="subdomain" >Please enter your school's name or an abbreviation. We'll use this to create a QuickSchools site for you:</label>
                                        <div class="field">
                                            http://<input type="text" name="data[Setup][subdomain]" placeholder="bells" id="subdomain" required="required">.smartedu.com
                                        </div>
                                        <span>If you’d like bells.smartedu.com, then enter "bells" in the field above. Letters and numbers only.</span>
                                    </div>

                                    <div class="span10 margintop10 field">
                                        <button type="submit" class="btn btn-theme margintop10">Set Up </button>
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