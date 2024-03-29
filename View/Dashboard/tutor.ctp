<?php echo $this->Html->script("../app/js/raphael-min.js", FALSE);?>
<?php echo $this->Html->script("../app/js/morris-0.4.3.min.js", FALSE);?>
<?php echo $this->Html->script("../app/js/morris-custom.js", FALSE);?>

<?php echo $this->Html->script("../app/js/charts/jquery.sparkline.min.js", FALSE);?>
<!-- NVD3 graphs  =============================-->
<?php echo $this->Html->script("../app/js/nvd3/lib/d3.v3.js", FALSE);?>
<?php echo $this->Html->script("../app/js/nvd3/nv.d3.js", FALSE);?>
<?php echo $this->Html->script("../app/js/nvd3/src/models/legend.js", FALSE);?>
<?php echo $this->Html->script("../app/js/nvd3/src/models/pie.js", FALSE);?>
<?php echo $this->Html->script("../app/js/nvd3/src/models/pieChart.js", FALSE);?>
<?php echo $this->Html->script("../app/js/nvd3/src/utils.js", FALSE);?>
<?php //echo $this->Html->script("../app/js/nvd3/sample.nvd3.js", FALSE);?>

<?php echo $this->Html->script("../app/js/bootstrap-tour.js", FALSE);?>
<!-- Core Jquery File  =============================-->
<?php echo $this->Html->script("../app/jquery/custom.dashboard.js", FALSE);?>
<?php echo $this->Html->script("../app/js/dashboard-custom.js", FALSE);?>


<div class="col-md-12">
    <div class="panel">
        <!-- Info Boxes -->
        <div class="row">
            <div class="col-md-4">
                <div class="info-box  bg-info  text-white">
                    <div class="info-icon bg-info-dark">
                        <i class="fa fa-group fa-4x"></i>
                    </div>
                    <div class="info-details">
                        <h4>Students Count<span class="pull-right"><?php echo $students;?></span></h4>
                        <p>Active Students <span class="badge pull-right bg-white text-info"> <?php echo $active_students;?> <i class="fa fa-arrow-up fa-1x"></i> </span> </p>
                    </div>
                </div>
            </div>
            <div class="col-md-4 ">
                <div class="info-box  bg-success  text-white"  id="initial-tour">
                    <div class="info-icon bg-success-dark">
                        <i class="fa fa-user fa-4x"></i>
                    </div>
                    <div class="info-details">
                        <h4>Employees Count<span class="pull-right"><?php echo $employees;?></span></h4>
                        <p>Active Employees <span class="badge pull-right bg-white text-success"> <?php echo $active_employees;?> <i class="fa fa-arrow-up fa-1x"></i></span> </p>
                    </div>
                </div>
            </div>
            <div class="col-md-4">
                <div class="info-box  bg-warning  text-white">
                    <div class="info-icon bg-warning-dark">
                        <i class="fa fa-male fa-4x"></i>
                    </div>
                    <div class="info-details">
                        <h4>Sponsors Count<span class="pull-right"><?php echo $sponsors;?></span></h4>
                    </div>
                </div>
            </div>
        </div>
        <div class="panel-body">
            <!-- Pie Charts -->
            <div class="row">
                <!-- Pie chart -->
                <!--div class="col-md-6 holder">
                    <div class="row">
                        <div class="col-md-6">
                            <div id="students_gender"></div>
                            <p class="text-center text-primary"><b><i class="fa fa-male fa-2x"></i> Students Gender (%) <i class="fa fa-female fa-2x"></i></b></p>
                        </div>
                        <div class="col-md-6">
                            <div id="students_status"></div>
                            <p class="text-center text-primary"><b><i class="fa fa-thumbs-o-up fa-2x"></i> Students Status (%) <i class="fa fa-thumbs-o-down fa-2x"></i></b></p>
                        </div>
                    </div>
                </div-->
            </div>
            <p class="divider"></p>
            <!-- Bar Charts -->
            <div class="row">
                <!-- Discrete Bar Chart -->
                <!--div class="col-md-12">
                    <div id="chart1">
                        <svg></svg>
                    </div>
                </div>
                <p class="text-center divider text-primary">
                    <b><i class="fa fa-building fa-2x"></i>  Students Class Level for :: <span id="current_year_span"></span> :: Current Academic Year  <i class="fa fa-bar-chart-o fa-2x"></i></b>
                </p-->
            </div>
        </div-->
    </div>
</div>
<?php
    //on click of Manage Students link... activate the link
//    echo $this->Js->buffer('
//        setTabActive("[href=\"'.DOMAIN_NAME.'/dashboard/\"]", 1);
//    ');
?> 