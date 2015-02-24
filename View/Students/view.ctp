<?php echo $this->Html->script("../app/jquery/custom.student.js", FALSE);?>
<div class="col-md-12">
    <div class="panel">
        <!-- Info Boxes -->
        <div class="row">
            <div class="col-md-12">
                <div class="info-box  bg-info  text-white">
                    <div class="info-icon bg-info-dark">
                        <i class="fa fa-info-circle fa-4x"></i>
                    </div>
                    <div class="info-details">
                        <h4>Student Complete Information   
                            <span class="badge pull-right bg-white text-info"><?php echo h($student['Student']['first_name']), ' ', $student['Student']['surname'];?>
                            <i class="fa fa-user fa-1x"></i> 
                            </span> 
                        </h4>
                    </div>
                </div>
            </div>
        </div>
        <!-- / Info Boxes -->
        <div class="panel-heading text-primary">
            <h3 class="panel-title">
               <i class="fa fa-info-circle"></i>
               Students Information
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
                    <div class="price-list row">
                        <div class="price-box col-md-4 col-sm-12 col-xs-12 col-lg-4">	
                            <div class="price-header bg-primary">
                                <h3>Headings</h3>
                            </div>
                            <ul class="list-group features">
                                <li class="list-group-item"><strong>Full Name</strong></li>
                                <li class="list-group-item"><strong>Student ID</strong></li>
                                <li class="list-group-item"><strong>Sponsor's Name</strong></li>
                                <li class="list-group-item"><strong>Relationship Type</strong></li>
                                <li class="list-group-item"><strong>Gender</strong></li>
                                <li class="list-group-item"><strong>Current Class</strong></li>
                                <li class="list-group-item"><strong>Status</strong></li>
                                <li class="list-group-item"><strong>Date of Birth</strong></li>
                                <!--li class="list-group-item"><strong>Religion</strong></li-->
                                <li class="list-group-item"><strong>Nationality</strong></li>
                                <li class="list-group-item"><strong>State of Origin</strong></li>
                                <li class="list-group-item"><strong>Local Govt. Area</strong></li>
                                <!--li class="list-group-item"><strong>Previous School</strong></li-->
                                <li class="list-group-item select">                                    
                                    <a class="btn btn-block bg-primary text-white btn-lg "></a>
                                </li>
                            </ul>
                        </div>
                        <div class="price-box col-md-5 col-sm-12 col-xs-12 col-lg-5">	
                            <div class="price-header bg-info">
                                <h3>Details</h3>
                            </div>
                            <ul class="list-group features">
                                <li class="list-group-item">
                                    <?php 
                                        echo h($student['Student']['first_name']), ' ', h($student['Student']['surname']), ' '; echo (!empty($student['Student']['other_name'])) ? h($student['Student']['other_name']) : ''; 
                                    ?>
                                </li>
                                <li class="list-group-item"><?php echo h($student['Student']['student_no']); ?></li>
                                <li class="list-group-item"><?php echo h($student['Sponsor']['first_name']), ' ', h($student['Sponsor']['other_name']); ?></li>
                                <li class="list-group-item"><?php echo h($student['RelationshipType']['relationship_type']); ?></li>
                                <li class="list-group-item"><?php echo h($student['Student']['gender']); ?></li>
                                <li class="list-group-item"><?php echo (!empty($student['Student']['class_id'])) ? h($student['Classroom']['class_name']) : '<span class="label label-danger">nill</span>'; ?></li>
                                <li class="list-group-item"><?php echo h($student['StudentStatus']['student_status']); ?></li>
                                <li class="list-group-item"><?php echo h($student['Student']['birth_date']); ?></li>
                                <!--li class="list-group-item"><?php //echo h($student['Student']['religion']); ?></li-->
                                <li class="list-group-item"><?php echo (!empty($student['Student']['country_id'])) ? h($student['Country']['country_name']) : '<span class="label label-danger">nill</span>';?></li>
                                <li class="list-group-item"><?php echo (!empty($student['Student']['state_id'])) ? h($student['State']['state_name']).' State' : '<span class="label label-danger">nill</span>';?></li>
                                <li class="list-group-item"><?php echo (!empty($student['Student']['local_govt_id'])) ? h($student['LocalGovt']['local_govt_name']) : '<span class="label label-danger">nill</span>';?></li>
                                <!--li class="list-group-item"><?php //echo (!empty($student['Student']['previous_school'])) ? h($student['Student']['previous_school']) : '<span class="label label-danger">nill</span>'; ?></li-->
                                <li class="list-group-item select">
                                    <a class="btn btn-block bg-info text-white btn-lg "></a>
                                </li>
                            </ul>
                        </div>
                        <div class="price-box col-md-3 col-sm-6 col-xs-12 col-lg-3 featured">	
                            <div class="price-header bg-success">
                                <h3>Passport</h3>
                            </div>
                            <ul class="list-group features">
                                <li class="list-group-item">
                                    <img class="img-rounded" data-src="holder.js/140x140"  style='width: 140px; height: 140px;'
                                        src="<?php echo DOMAIN_NAME ?>/img/uploads/<?php echo ($student['Student']['image_url']) ? $student['Student']['image_url'] : 'avatar.jpg';?>"/>
                                </li>
                                <li class="list-group-item select">
                                    <a class="btn btn-block bg-success text-white btn-lg "></a>
                                </li>
                            </ul>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
<?php
    //on click of View Student Record link... activate the link
    echo $this->Js->buffer('
        setTabActive("[href=\"'.DOMAIN_NAME.'/students/\"]", 0);
    ');
?>      