<?php echo $this->Html->script("../web/js/custom.home.js", FALSE);?>
<?php 
    App::uses('Encryption', 'Utility'); 
    $Encryption = new Encryption();
?>

<!-- Start Content-->
<section id="content">
    <div class="container">
        
        <!-- divider -->
        <div class="row">
            <div class="span12">
                <div class="solidline">
                </div>
            </div>
        </div>
        <!-- end divider -->
        <div class="row">
            <div class="span4"><strong>
                <div class="widget-title"><h5 class="widgetheading"><strong>Headings</strong></h5></div>
                <div class="progress-bar"><p>Full Name</p></div>  
                <div class="progress-bar"><p>Student ID</p></div> 
                <div class="progress-bar"><p>Sponsor's Name</p></div> 
                <div class="progress-bar"><p>Relationship Type</p></div> 
                <div class="progress-bar"><p>Gender</p></div> 
                <div class="progress-bar"><p>Current Class</p></div> 
                <div class="progress-bar"><p>Status</p></div> 
                <div class="progress-bar"><p>Date of Birth</p></div> 
                <div class="progress-bar"><p>Religion</p></div> 
                <div class="progress-bar"><p>Nationality</p></div> 
                <div class="progress-bar"><p>State of Origin</p></div> 
                <div class="progress-bar"><p>Local Govt. Area</p></div> 
                <div class="progress-bar"><p>Previous School</p></div> 
                <div class="progress-bar"><p>Previous Class</p></div> </strong>
            </div>
            <div class="span4">
                <div class="widget-title"><h5 class="widgetheading"><strong>Details</strong></h5></div>
                <div class="progress-bar">
                    <p><?php echo h($student['Student']['first_name']), ' ', h($student['Student']['surname']), ' '; echo (!empty($student['Student']['other_name'])) ? h($student['Student']['other_name']) : ''; ?></p>
                </div>  
                <div class="progress-bar"><p><?php echo h($student['Student']['student_no']); ?></p></div>  
                <div class="progress-bar"><p><?php echo h($student['Sponsor']['first_name']), ' ', h($student['Sponsor']['other_name']); ?></p></div>  
                <div class="progress-bar"><p><?php echo h($student['RelationshipType']['relationship_type']); ?></p></div>  
                <div class="progress-bar"><p><?php echo h($student['Student']['gender']); ?></p></div>  
                <div class="progress-bar"><p><?php echo (!empty($student['Student']['class_id'])) ? h($student['Classroom']['class_name']) : '<span class="label label-danger">nill</span>'; ?></p></div>  
                <div class="progress-bar"><p><?php echo h($student['StudentStatus']['student_status']); ?></p></div>  
                <div class="progress-bar"><p><?php echo h($student['Student']['birth_date']); ?></p></div>  
                <div class="progress-bar"><p><?php echo h($student['Student']['religion']); ?></p></div>  
                <div class="progress-bar"><p><?php echo (!empty($student['Student']['country_id'])) ? h($student['Country']['country_name']) : '<span class="label label-danger">nill</span>';?></p></div>  
                <div class="progress-bar"><p><?php echo (!empty($student['Student']['state_id'])) ? h($student['State']['state_name']).' State' : '<span class="label label-danger">nill</span>';?></p></div>  
                <div class="progress-bar"><p><?php echo (!empty($student['Student']['local_govt_id'])) ? h($student['LocalGovt']['local_govt_name']) : '<span class="label label-danger">nill</span>';?></p></div>  
                <div class="progress-bar"><p><?php echo (!empty($student['Student']['previous_school'])) ? h($student['Student']['previous_school']) : '<span class="label label-danger">nill</span>'; ?></p></div>  
                <div class="progress-bar"><p><?php echo (!empty($student['Student']['previousclass'])) ? h($student['Student']['previousclass']) : '<span class="label label-danger">nill</span>'; ?></p></div>  
            </div>
			
            <div class="span4">
                <h4><strong>Passport</strong></h4>
                <figure class="rbTestimonial dark">
                    <div class="row">
                        <div class="span3">
                            <img class="testiman" data-src="holder.js/140x140" src="<?php echo DOMAIN_NAME ?>/img/uploads/<?php echo ($student['Student']['image_url']) ? $student['Student']['image_url'] : '';?>" />
                        </div>

                    </div>
              </figure> 
            </div>			
        </div>
        
        
        
    <!-- divider -->
        <div class="row bottom2">
            <div class="span12">
                <div class="solidline"></div>
            </div>
        </div>
        <!-- end divider -->
    </div>
</section>
<!-- End Content-->