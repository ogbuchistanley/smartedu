<?php echo $this->Html->script("../app/jquery/custom.sponsor.js", FALSE);?>
<div class="col-md-12">
    <div class="panel">
        <!-- Info Boxes -->
        <!--div class="row">
            <div class="col-md-12">
                <div class="info-box  bg-info  text-white">
                    <div class="info-icon bg-info-dark">
                        <i class="fa fa-info-circle fa-4x"></i>
                    </div>
                    <div class="info-details">
                        <h4>Sponsors Complete Information   
                            <span class="badge pull-right bg-white text-info"><?php //echo $sponsor['Sponsor']['first_name'] . ' ' . $sponsor['Sponsor']['other_name'];?>
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
               Sponsors Information
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
                                <li class="list-group-item"><strong>Sponsor ID</strong></li>
                                <li class="list-group-item"><strong>Email</strong></li>
                                <li class="list-group-item"><strong>Mobile Number 1</strong></li>
                                <li class="list-group-item"><strong>Mobile Number 2</strong></li>
                                <li class="list-group-item"><strong>Nationality</strong></li>
                                <li class="list-group-item"><strong>State of Origin</strong></li>
                                <li class="list-group-item"><strong>Local Govt. Area</strong></li>
                                <li class="list-group-item"><strong>Contact Address</strong></li>
                                <!--li class="list-group-item"><strong>Sponsorship Type</strong></li-->
                                <li class="list-group-item"><strong>Occupation</strong></li>
                                <!--li class="list-group-item"><strong>Company Name</strong></li-->
                                <li class="list-group-item"><strong>Office Address</strong></li>
                                <li class="list-group-item select">
                                    <a class="btn btn-block bg-primary text-white btn-lg "></a>
                                </li>
                            </ul>
                        </div>
                        <div class="price-box col-md-8 col-sm-12 col-xs-12 col-lg-8">	
                            <div class="price-header bg-info">
                                <h3>Details</h3>
                            </div>
                            <ul class="list-group features">
                                <li class="list-group-item">
                                    <?php 
                                        echo h($sponsor['Salutation']['salutation_abbr']), ' ', h($sponsor['Sponsor']['first_name']), ' ', h($sponsor['Sponsor']['other_name']); 
                                    ?>
                                </li>
                                <li class="list-group-item"><?php echo h($sponsor['Sponsor']['sponsor_no']); ?></li>
                                <li class="list-group-item"><?php echo (empty($sponsor['Sponsor']['email'])) ? '<span class="label label-danger">nill</span>' : $sponsor['Sponsor']['email']; ?></li>
                                <li class="list-group-item"><?php echo h($sponsor['Sponsor']['mobile_number1']); ?></li>
                                <li class="list-group-item"><?php echo (!empty($sponsor['Sponsor']['mobile_number2'])) ? h($sponsor['Sponsor']['mobile_number2']) : '<span class="label label-danger">nill</span>'; ?></li>
                                <li class="list-group-item"><?php echo (!empty($sponsor['Sponsor']['country_id'])) ? h($sponsor['Country']['country_name']) : '<span class="label label-danger">nill</span>';?></li>
                                <li class="list-group-item"><?php echo (!empty($sponsor['Sponsor']['state_id'])) ? h($sponsor['State']['state_name']).' State' : '<span class="label label-danger">nill</span>';?></li>
                                <li class="list-group-item"><?php echo (!empty($sponsor['Sponsor']['local_govt_id'])) ? h($sponsor['LocalGovt']['local_govt_name']) : '<span class="label label-danger">nill</span>';?></li>
                                <li class="list-group-item"><?php echo (!empty($sponsor['Sponsor']['contact_address'])) ? h($sponsor['Sponsor']['contact_address']) : '<span class="label label-danger">nill</span>'; ?></li>
                                <!--li class="list-group-item"><?php //echo h($sponsor['SponsorshipType']['sponsorship_type']); ?></li-->
                                <li class="list-group-item"><?php echo h($sponsor['Sponsor']['occupation']); ?></li>
                                <li class="list-group-item"><?php echo (!empty($sponsor['Sponsor']['company_name'])) ? h($sponsor['Sponsor']['company_name']) : '<span class="label label-danger">nill</span>'; ?></li>
                                <li class="list-group-item"><?php echo (!empty($sponsor['Sponsor']['company_address'])) ? h($sponsor['Sponsor']['company_address']) : '<span class="label label-danger">nill</span>'; ?></li>
                                <li class="list-group-item select">
                                    <a class="btn btn-block bg-info text-white btn-lg "></a>
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
    //on click of View Sponsor Record link... activate the link
    echo $this->Js->buffer('
        setTabActive("[href=\"'.DOMAIN_NAME.'/sponsors/\"]", 0);
    ');
?> 