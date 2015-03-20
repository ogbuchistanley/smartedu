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
               Parents Information
                <span class="pull-right">
                    <a href="javascript:void(0)"  title="Refresh"><i class="fa fa-refresh"></i></a>
                    <a href="#" class="panel-minimize"><i class="fa fa-chevron-up"></i></a>
                    <a href="#" class="panel-close"><i class="fa fa-times"></i></a>
                </span>
            </h3>
        </div>
        <div class="col-md-8">
            <div class="panel panel-info">
                <div class="panel-heading panel-title  text-white">Details Table</div>
                <div style="overflow-x: scroll" class="panel-body">
                    <table  class="table table-bordered table-hover table-striped display" id="student_table" >
                        <tbody>
                            <tr>
                                <th>Full Name</th>
                                <td>
                                    <?php
                                    echo h($sponsor['Salutation']['salutation_abbr']), ' ', h($sponsor['Sponsor']['first_name']), ' ', h($sponsor['Sponsor']['other_name']);
                                    $nil = '<span class="label label-danger">nill</span>';
                                    ?>
                                </td>
                            </tr>
                            <tr>
                                <th>Sponsor ID</th>
                                <td><?php echo h($sponsor['Sponsor']['sponsor_no']); ?></td>
                            </tr>
                            <tr>
                                <th>Email</th>
                                <td><?php echo (!empty($sponsor['Sponsor']['email'])) ? h($sponsor['Sponsor']['email']) : $nil; ?></td>
                            </tr>
                            <tr>
                                <th>Mobile Number 1</th>
                                <td><?php echo h($sponsor['Sponsor']['mobile_number1']); ?></td>
                            </tr>
                            <tr>
                                <th>Mobile Number 2</th>
                                <td><?php echo (!empty($sponsor['Sponsor']['mobile_number2'])) ? h($sponsor['Sponsor']['mobile_number2']) : $nil; ?></td>
                            </tr>
                            <tr>
                                <th>Nationality</th>
                                <td><?php echo (!empty($sponsor['Sponsor']['country_id'])) ? h($sponsor['Country']['country_name']) : $nil;?></td>
                            </tr>
                            <tr>
                                <th>State of Origin</th>
                                <td><?php echo (!empty($sponsor['Sponsor']['state_id'])) ? h($sponsor['State']['state_name']).' State' : $nil;?></td>
                            </tr>
                            <tr>
                                <th>Local Govt. Area</th>
                                <td><?php echo (!empty($sponsor['Sponsor']['local_govt_id'])) ? h($sponsor['LocalGovt']['local_govt_name']) : $nil;?></td>
                            </tr>
                            <tr>
                                <th>Contact Address</th>
                                <td><?php echo (!empty($sponsor['Sponsor']['contact_address'])) ? h($sponsor['Sponsor']['contact_address'])  : $nil; ?></td>
                            </tr>
                            <tr>
                                <th>Occupation</th>
                                <td><?php echo h($sponsor['Sponsor']['occupation']);?></td>
                            </tr>
                            <tr>
                                <th>Company Name</th>
                                <td><?php echo (!empty($sponsor['Sponsor']['company_name'])) ? h($sponsor['Sponsor']['company_name'])  : $nil;?></td>
                            </tr>
                            <tr>
                                <th>Office Address</th>
                                <td><?php echo (!empty($sponsor['Sponsor']['company_address'])) ? h($sponsor['Sponsor']['company_address']) : $nil;?></td>
                            </tr>
                        </tbody>
                    </table>
                </div> <!-- /panel body -->
            </div>
        </div>
        <div class="price-list row">
            <div class="price-box col-md-3 col-sm-6 col-xs-12 col-lg-3 featured">
                <div class="price-header">
                    <h3 class="bg-info">Passport</h3>
                </div>
                <ul class="list-group features">
                    <li class="list-group-item">
                        <img class="img-rounded" data-src="holder.js/140x140"  style='width: 140px; height: 140px;'
                             src="<?php echo DOMAIN_NAME ?>/img/uploads/<?php echo ($sponsor['Sponsor']['image_url']) ? $sponsor['Sponsor']['image_url'] : 'avatar.jpg';?>"/>
                    </li>
                    <li class="list-group-item select">
                        <a class="btn btn-block bg-info text-white btn-lg "></a>
                    </li>
                </ul>
            </div>
        </div>
    </div>
</div>
<?php
    //on click of View Parent Record link... activate the link
    echo $this->Js->buffer('
        setTabActive("[href=\"'.DOMAIN_NAME.'/sponsors/\"]", 0);
    ');
?> 