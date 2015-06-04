<?php
/**
 *
 *
 * @link          http://cakephp.org CakePHP(tm) Project
 * @package       app.View.Layouts
 * @since         CakePHP(tm) v 0.10.0.1076
 */

$cakeDescription = __d('app_dev', ':: '.APP_NAME.' :');

?>
<!DOCTYPE html>
<html lang="en" class="no-js">
    <head>
        <?php echo $this->Html->charset("utf-8"); ?>

        <title>
            <?php echo $cakeDescription ?>:
            <?php echo $this->fetch('title'); ?>
        </title>
        <!-- start: META -->
        <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=0, minimum-scale=1.0, maximum-scale=1.0" />
        <meta name="apple-mobile-web-app-capable" content="yes" />
        <meta name="apple-mobile-web-app-status-bar-style" content="black" />
        <meta name="description" content="" />
        <meta name="author" content="" />
        <!-- end: META -->

        <!-- start: CSS -->
        <!-- Loading Bootstrap -->
        <?php 
            //echo $this->Html->css('cake.generic');

            //echo $this->fetch('css');
        ?>
        <link href="<?php echo APP_DIR_ROOT; ?>css/bootstrap.css" rel="stylesheet">

        <!-- Loading Stylesheets -->    
        <link href="<?php echo APP_DIR_ROOT; ?>css/style.css" rel="stylesheet">
        <link href="<?php echo APP_DIR_ROOT; ?>css/login.css" rel="stylesheet">

        <!-- Loading Custom Stylesheets -->    
        <link href="<?php echo APP_DIR_ROOT; ?>css/custom.css" rel="stylesheet">
        <link href="<?php echo APP_DIR_ROOT, $SchoolInfo['school_logo'];?>" rel="shortcut icon">
        <!-- HTML5 shim, for IE6-8 support of HTML5 elements. All other JS at the end of file. -->
        <!--[if lt IE 9]>
            <script src="http://html5shim.googlecode.com/svn/trunk/html5.js"></script>
        <![endif]-->

        <!-- end: CSS-->
    </head>

    <body >
          <div class="list-group side-menu ">
            <a class="list-group-item" href="#login">Login</a>
            <a class="list-group-item" href="#forgot-password">Forgot Password?</a>
          </div>
            
            <?php echo $this->fetch('content'); ?>

    <!-- start: MAIN JAVASCRIPTS -->
    <!-- Load JS here for Faster site load =============================-->
    <script src="<?php echo APP_DIR_ROOT; ?>js/jquery-1.10.2.min.js"></script>
    <script src="<?php echo APP_DIR_ROOT; ?>js/jquery-ui-1.10.3.custom.min.js"></script>
    <script src="<?php echo APP_DIR_ROOT; ?>js/jquery.ui.touch-punch.min.js"></script>
    <script src="<?php echo APP_DIR_ROOT; ?>js/bootstrap.min.js"></script>
    <script src="<?php echo APP_DIR_ROOT; ?>js/bootstrap-select.js"></script>
    <script src="<?php echo APP_DIR_ROOT; ?>js/bootstrap-switch.js"></script>
    <script src="<?php echo APP_DIR_ROOT; ?>js/jquery.tagsinput.js"></script>
    <script src="<?php echo APP_DIR_ROOT; ?>js/jquery.placeholder.js"></script>
    <script src="<?php echo APP_DIR_ROOT; ?>js/bootstrap-typeahead.js"></script>
    <script src="<?php echo APP_DIR_ROOT; ?>js/application.js"></script>
    <script src="<?php echo APP_DIR_ROOT; ?>js/moment.min.js"></script>
    <script src="<?php echo APP_DIR_ROOT; ?>js/jquery.dataTables.min.js"></script>
    <script src="<?php echo APP_DIR_ROOT; ?>js/jquery.sortable.js"></script>
    <script src="<?php echo APP_DIR_ROOT; ?>js/jquery.gritter.js" type="text/javascript"></script>
    <script src="<?php echo APP_DIR_ROOT; ?>js/jquery.nicescroll.min.js"></script>
    <script src="<?php echo APP_DIR_ROOT; ?>js/skylo.js"></script>
    <script src="<?php echo APP_DIR_ROOT; ?>js/prettify.min.js"></script>
    <script src="<?php echo APP_DIR_ROOT; ?>js/jquery.noty.js"></script>
    <script src="<?php echo APP_DIR_ROOT; ?>js/scroll.js"></script>
    <script src="<?php echo APP_DIR_ROOT; ?>js/jquery.panelSnap.js"></script>
    <script src="<?php echo APP_DIR_ROOT; ?>js/login.js"></script>
    <script src="<?php echo APP_DIR_ROOT; ?>jquery/custom.functions.js"></script>

    <?php echo $this->fetch('script'); ?>
    <?php echo $this->Js->writeBuffer(array('cache' => TRUE));?>
    
    </body>
</html>