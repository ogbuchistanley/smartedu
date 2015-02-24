<!DOCTYPE html>
<html>
    <head>
        <title><?php echo $this->fetch('title'); ?></title>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <!-- Bootstrap -->
        <link href="<?php echo MAIL_DIR_ROOT; ?>css/bootstrap.min.css" rel="stylesheet">
        <link href="<?php echo MAIL_DIR_ROOT; ?>css/font-awesome.css" rel="stylesheet">
        <link href="<?php echo MAIL_DIR_ROOT; ?>css/template-three.css" rel="stylesheet">
        <?php echo $this->fetch('css');?>
    </head>
    <body>

        <div class="header">	
            <div class="container">
                <h1>SmartSchool</h1>	
                <ul class="social">
                    <li><a href="#"><i class="fa fa-facebook-square"></i></a></li>
                    <li><a href="#"><i class="fa fa-twitter-square"></i></a></li>
                    <li><a href="#"><i class="fa fa-google-plus-square"></i></a></li>
                    <li><a href="#"><i class="fa fa-linkedin-square"></i></a></li>
                </ul>			
            </div><!--end of container-->
        </div><!--end of header-->

        <div class="body">
            <div class="container box-container">
                <div class="box">
                    <h2>Smart<img src="<?php echo APP_DIR_ROOT; ?>images/icon.png" />School Application Mails</h2>
                    <div class="cover">
                        <img src="<?php echo MAIL_DIR_ROOT; ?>images/cover.jpg" alt="">
                    </div><!--end of cover-->
                    <div class="row description">
                        <?php echo $this->fetch('content'); ?> 
                        
                        <div class="col-md-4 col-md-offset-1">
                            <h3>
                                <a href="<?php echo DOMAIN_URL ?>/dashboard">
                                    Smart<img src="<?php echo APP_DIR_ROOT; ?>images/icon.png" />School
                                </a>
                            </h3>
                            <p>
                                <br>Date and Time: <?php echo date("l, jS F, Y");?>
                                <br>if you did not initiate this action, we recommend that you contact us at 
                                <a href="<?php echo DEVELOPER_SITE_ADDRESS;?>">
                                    <?php echo DEVELOPER_SITE_NAME;?> 
                                </a> for further assistance.
                            </p>
                            <p> <a href="<?php echo DOMAIN_URL ?>/dashboard">Click Here To Access The Application</a> </p>
                        </div>
                        
                            
                    </div><!--end of row-->
                </div><!--end of box-->
            </div><!--end of container-->
        </div><!--end of body-->

        <div class="footer">
            <br><br><p>&copy; <?php echo date("Y"); ?> <a href="<?php echo DEVELOPER_SITE_ADDRESS;?>"><?php echo DEVELOPER_SITE_NAME;?></a> All rights reserved</p>
        </div>

        <!-- Load JS here for Faster site load =============================-->
        <script src="<?php echo APP_DIR_ROOT; ?>js/jquery-1.10.2.js"></script>
        <!-- jQuery (necessary for Bootstrap's JavaScript plugins) -->
        <!--script src="https://code.jquery.com/jquery.js"></script-->
        <!-- Include all compiled plugins (below), or include individual files as needed -->
        <script src="<?php echo MAIL_DIR_ROOT; ?>js/bootstrap.min.js"></script>
        <?php echo $this->fetch('script'); ?>
        <?php echo $this->Js->writeBuffer(array('cache' => TRUE));?>
    </body>
</html>