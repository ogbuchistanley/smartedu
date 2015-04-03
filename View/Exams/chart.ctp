<!DOCTYPE html>
<html lang="en">
<head>
    <head>
        <title>Student Analysis Result Sheet</title>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <link href="<?php echo APP_DIR_ROOT; ?>css/bootstrap.css" rel="stylesheet">
        <link href="<?php echo APP_DIR_ROOT; ?>css/font-awesome.css" rel="stylesheet"

        <!-- Loading Custom Stylesheets -->
        <link href="<?php echo APP_DIR_ROOT; ?>css/style.css" rel="stylesheet" type="text/css">
        <link href="<?php echo APP_DIR_ROOT; ?>less/style.less" rel="stylesheet"  title="lessCss" id="lessCss">
        <link href="<?php echo APP_DIR_ROOT; ?>css/custom.css" rel="stylesheet">
        <link href="<?php echo APP_DIR_ROOT; ?>css/print.css" rel="stylesheet" media="print">

        <link href="<?php echo APP_DIR_ROOT; ?>images/icon.png" rel="shortcut icon">
        <style type="text/css">

            #visitors{
                height: 750px;
                margin-bottom: 10px;
                bottom: 40px;
            }
        </style>
    </head>
    <body style="padding-top: 15px; background-color: white" bgcolor="white">
        <?php $TermModel = ClassRegistry::init('AcademicTerm'); ?>
        <div class="container-fluid">
            <div>
                <div align="center" style="width:100%">
                    <div style="color:#666; font-size: 40px; font-weight: bolder; font-family: "verdana", "lucida grande", sans-serif"> THE BELLS</div>
                    <div style="font-size: 14px; font-weight: bold;">Comprehensive Secondary School for Boys and Girls<br>Ota, Ogun State</div>
                    <h6>MOTTO: Learn &nbsp; . &nbsp; Live &nbsp; . &nbsp; Lead </h6>
                    <h6>website: http://www.thebellsschools.org</h6>
                    <input type="hidden" id="encrypt_id" value="<?php echo $encrypt_id?>">
                </div><br><br>
                <div class="row col-md-6" style="width: 1200px; height: auto;">
                    <div class="panel text-primary panel-cascade">
                        <div class="panel-heading">
                            <h3>
                                <i class="fa fa-bar-chart-o"></i>
                                Performance Analytics for: <?php echo ($Student) ? $Student['Student']['full_name'] : '';?>
                            </h3>
                        </div>
                        <div class="panel-body nopadding">
                            <div id="visitors"></div>
                            <h6 style="text-align: center">Subjects Offered By Student in <?php echo ($Class) ? $Class['Classroom']['class_name'] : '';?></h6>
                        </div>
                    </div>
                </div>
                <div class="col-md-12">
                    <div id="chart1">
                        <svg></svg>
                    </div>
                </div>
            </div>
        </div>
                <h6 style="text-align: center">Powered by SmartEdu ™</h6>

        <script src="<?php echo APP_DIR_ROOT?>js/jquery-1.10.2.js"></script>
        <script src="<?php echo APP_DIR_ROOT?>js/jquery-ui-1.10.3.custom.js"></script>

        <script src="<?php echo APP_DIR_ROOT?>js/raphael-min.js"></script>
        <script src="<?php echo APP_DIR_ROOT?>js/morris-0.4.3.min.js"></script>
        <script src="<?php echo APP_DIR_ROOT?>js/morris-custom.js"></script>

        <script src="<?php echo APP_DIR_ROOT?>js/charts/jquery.sparkline.min.js"></script>

        <!-- NVD3 graphs  =============================-->
        <script src="<?php echo APP_DIR_ROOT?>js/nvd3/lib/d3.v3.js"></script>
        <script src="<?php echo APP_DIR_ROOT?>js/nvd3/nv.d3.js"></script>
        <script src="<?php echo APP_DIR_ROOT?>js/nvd3/src/models/legend.js"></script>
        <script src="<?php echo APP_DIR_ROOT?>js/nvd3/src/utils.js"></script>


        <script src="<?php echo APP_DIR_ROOT; ?>jquery/custom.functions.js"></script>

        <script src="<?php echo APP_DIR_ROOT?>jquery/custom.exam.js"></script>

        <?php echo $this->fetch('script'); ?>
        <?php echo $this->Js->writeBuffer(array('cache' => TRUE));?>

    </body>
</html>