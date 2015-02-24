<?php echo $this->Html->script("../app/js/raphael-min.js", FALSE);?>
<?php echo $this->Html->script("../app/js/morris-0.4.3.min.js", FALSE);?>
<?php echo $this->Html->script("../app/js/morris-custom.js", FALSE);?>
<!-- Core Jquery File  =============================-->
<?php //echo $this->Html->script("../app/jquery/custom.dashboard.js", FALSE);?>
<?php echo $this->Html->script("../app/jquery/custom.item.js", FALSE);?>
<?php $term_id = ClassRegistry::init('AcademicTerm'); ?>

<style type="text/css">

    #chart0 svg, #chart01 svg {
      height: 300px;
    }

</style>

<div class="col-md-12">
    <div class="panel">
        <!-- Info Boxes -->
        <div class="row">
            <div class="col-md-12">
                <div class="info-box  bg-info  text-white">
                    <div class="info-icon bg-info-dark">
                        <i class="fa fa-money fa-4x"></i>
                    </div> 
                    <div class="info-details">
                        <h4>Graphical Representation of Students Payment Status in their respective Class Rooms</h4>
                    </div> 
                </div>
            </div>
        </div>
        <!-- / Info Boxes -->
        
        <?php 
            $count = 1;
            foreach ($Classlevels as $Classlevel) : 
        ?>
            <div class="col-md-6">
                <div class="panel text-primary panel-cascade">
                    <div class="panel-heading">
                        <h3 class="panel-title">
                            <i class="fa fa-bar-chart-o"></i>
                            <?php echo $term_id->getCurrentTermName();?>
                            <span class="pull-right text-info">
                                <i class="fa fa-building"></i>
                                <?php echo $Classlevel['Classlevel']['classlevel'];?>
                            </span>
                        </h3>
                    </div>
                    <div class="panel-body nopadding">
                        <div id="payment_status<?php echo $count;?>"></div>			
                        <div class="row visitors-list-summary text-center">
                            <div class="col-md-4 col-sm-4 col-xs-4 visitor-item ">
                                <i class="fa fa-check fa-3x pull-left"></i>
                                Total Paid <br />
                                <label class="label label-success" id="total_paid<?php echo $count;?>"></label>
                            </div>
                            <div class="col-md-4 col-sm-4 col-xs-4 visitor-item">
                                <i class="fa fa-times fa-3x pull-left"></i>
                                Total Not Paid <br />
                                <label class="label label-danger" id="total_Npaid<?php echo $count;?>"></label>
                            </div>
                            <div class="col-md-4 col-sm-4 col-xs-4 visitor-item">
                                <i class="fa fa-user fa-3x pull-left"></i>
                                Total Students <br />
                                <label class="label label-primary" id="total_students<?php echo $count;?>"></label>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="row">
                    <hr><hr>
                </div>
            </div>
        <?php $count++; endforeach;?>
    </div>
</div>