<?php
/**
 *
 *
 * @link          http://cakephp.org CakePHP(tm) Project
 * @package       app.View.Layouts
 * @since         CakePHP(tm) v 0.10.0.1076
 */

$cakeDescription = __d('web_dev', ':: '.APP_NAME.' :');
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
    <?php //echo $this->Html->css('cake.generic'); ?>
    <link href="<?php echo WEB_DIR_ROOT; ?>css/bootstrap.css" rel="stylesheet" />
    <link href="<?php echo WEB_DIR_ROOT; ?>css/bootstrap-responsive940.css" rel="stylesheet" />
    <link href="<?php echo WEB_DIR_ROOT; ?>css/fancybox/jquery.fancybox.css" rel="stylesheet">

    <link href="<?php echo WEB_DIR_ROOT; ?>css/flexslider.css" rel="stylesheet" />
    <link href="<?php echo WEB_DIR_ROOT; ?>css/style.css" rel="stylesheet" />
    <link href="<?php echo WEB_DIR_ROOT; ?>css/style-responsive.css" rel="stylesheet" />
    <link href="<?php echo WEB_DIR_ROOT; ?>css/flexisel.css" rel="stylesheet" />
    <link href="<?php echo WEB_DIR_ROOT; ?>css/carousel.css" rel="stylesheet" />
    <link href="<?php echo WEB_DIR_ROOT; ?>css/jquery.easy-pie-chart.css" rel="stylesheet" type="text/css" media="screen">
    <link href="<?php echo WEB_DIR_ROOT; ?>css/chart.css" rel="stylesheet" type="text/css" media="screen">
    <link href="<?php echo WEB_DIR_ROOT; ?>colorpicker/css/colorpicker.css" rel="stylesheet" type="text/css">
    <!-- Theme skin -->
    <link href="<?php echo WEB_DIR_ROOT; ?>skins/blue.css" id="t-colors" rel="stylesheet" />
    <link href="<?php echo WEB_DIR_ROOT; ?>skins/silver.css" rel="stylesheet" />
    <!-- boxed bg -->
    <link href="<?php echo WEB_DIR_ROOT; ?>bodybg/bg1.css" id="bodybg" rel="stylesheet" type="text/css" />
    <link href="<?php echo WEB_DIR_ROOT; ?>img/favicon.png" rel="icon" type="image/x-icon" />
    <!-- HTML5 shim, for IE6-8 support of HTML5 elements -->
    <!--[if lt IE 9]>
          <script src="http://html5shim.googlecode.com/svn/trunk/html5.js"></script>
        <![endif]-->	
    <!-- end: CSS -->
</head>

<body class="footer-fixed">
    <!-- start wrapper -->
    <div id="wrapper" class="boxed">
	<!-- toggle top area -->
	<div class="hidden-top">
            <div class="hidden-top-inner container">
                <div class="row bottom2">
                    <div class="span12">
                        <ul>
                            <li><strong>Smart School, Smart Results:</strong></li><li>Call us <i class="icon-phone"></i> (321) 236-4890 - (321) 333-4890</li>
                        </ul>
                    </div>
                </div>
            </div>
	</div>
	<!-- end toggle top area -->
        <!-- start header -->
	<header>
	<!-- Top opener -->
            <div id="customizer">
                <span class="corner plus">
                    <span class="cog">
                        <a href="javascript:void(0);" class="toggle-link" title="Click for info." data-target=".hidden-top">
                        <span class="opener font-icon-plus-sign"></span></a>
                    </span>                        
                </span>
            </div>
            <div class="container">
		<!-- hidden top area toggle link -->
		<div id="header-hidden-link" style="display: none">
            <a href="javascript:void(0);" class="toggle-link" title="Click for info." data-target=".hidden-top"><i></i>Open</a>
		</div>
		<!-- end toggle link -->
		
		
		<div class="row bottom2">
		    <!-- Logo -->
            <div class="span3 logo-span">
                <div class="logo">
                    <a href="<?php echo DOMAIN_NAME ?>/home/"><img src="<?php echo WEB_DIR_ROOT; ?>img/logo.png" width="220" alt="logo" class="logo" title="SmartSchool" /></a>
                </div>
            </div>
            <!-- End Logo -->

            <div class="span9 navbar-span">

                <div class="navbar navbar-static-top">
                    <a class="btn btn-navbar collapsed" data-toggle="collapse" data-target=".nav-collapse">
                        <span class="icon-bar"></span>
                        <span class="icon-bar"></span>
                        <span class="icon-bar"></span>
                    </a><!-- /nav-collapse --> 

                    <!-- Navigation -->
                   <div class="nav-collapse collapse" style="height: 0px;">      
                        <div class="navigation">
                            <nav>
                                <ul class="nav topnav">
                                    <li class="active">
                                        <a href="<?php echo DOMAIN_NAME; ?>/home/" >Home <i class="icon-angle-down"></i></a>
                                    </li>
                                    <li><a href="<?php echo DOMAIN_NAME; ?>/home/students">Students<i class="icon-angle-down"></i></a></li>
                                    <li><a href="<?php echo DOMAIN_NAME; ?>/home/exam">Exams / Fees <i class="icon-angle-down"></i></a></li>
                                    <li><a href="<?php echo DOMAIN_NAME; ?>/home/change">Change Password <i class="icon-angle-down"></i></a></li>
                                    <li><a href="<?php echo DOMAIN_NAME; ?>/home/setup"> Sign Up </a></li>
                                    <li><a href="<?php echo DOMAIN_NAME; ?>/logout"><i class="fa fa-lock"></i><span class="hidden-minibar"> Logout</span> <i class="icon-angle-down"></i></a></li>
                                </ul>
                            </nav>
                         </div>
                    </div>
                    <!-- end navigation -->
                </div>
            </div>
		</div>
            </div>
	</header>
	<!-- End header -->
     
	<!-- Start fixed menu -->
	<div class="fixed-menu">
            <header>
                <div class="container">
                    <div class="row nomargin">
                    </div>

                    <div class="row bottom2">
                        <!-- Logo -->
                        <div class="span3">
                            <div class="logo">
                                <a href="<?php echo DOMAIN_NAME; ?>/home/"><img src="<?php echo WEB_DIR_ROOT; ?>img/logo.png" width="220" alt="logo" class="logo" title="SmartSchool" /></a>
                            </div>
                        </div>
                        <!-- End logo -->

                        <div class="span9">
                            <!-- Start navigation -->
                            <div class="navbar navbar-static-top">
                                <div class="navigation">
                                    <nav>
                                        <ul class="nav topnav">
                                            <li class="active">
                                                <a href="<?php echo DOMAIN_NAME; ?>/home/" >Home <i class="icon-angle-down"></i></a>
                                            </li>
                                            <li><a href="<?php echo DOMAIN_NAME; ?>/home/students">Students<i class="icon-angle-down"></i></a></li>
                                            <li><a href="<?php echo DOMAIN_NAME; ?>/home/exam">Exams / Fees <i class="icon-angle-down"></i></a></li>
                                            <li><a href="<?php echo DOMAIN_NAME; ?>/home/change">Change Password <i class="icon-angle-down"></i></a></li>
                                            <li><a href="<?php echo DOMAIN_NAME; ?>/home/setup"> Sign Up </a></li>
                                            <li><a href="<?php echo DOMAIN_NAME; ?>/logout"><i class="fa fa-lock"></i><span class="hidden-minibar"> Logout</span> <i class="icon-angle-down"></i></a></li>
                                        </ul>
                                    </nav>
                                 </div>
                            <!-- end navigation -->
                            </div>
                        </div>
                    </div>
                </div>
            </header>
        </div>
        <!-- End fixed menu -->
        
        <?php echo $this->Session->flash(); ?>

        <?php echo $this->fetch('content'); ?>
       
        
    <!-- Start Footer-->
	<footer>
            <div class="container">
                <div class="row bottom3">
                    <div class="span7">
                        <div class="copyright">
                            <p><span class="first">Copyright &copy; SmartSchool <?php echo date("Y"); ?> </span>|<span><a href="javascript:void(0);">SUPPORT/HELP</a></span>|<span><a href="avascript:void(0);" rel="nofollow">FAQ</a></span></p>
                        </div>
                    </div>
                    <div class="span5">
                        <a href="" class="logof"><img src="<?php echo WEB_DIR_ROOT; ?>img/logof.png" alt="logo" width="103" class="logo" /></a>
                        <ul class="social-network">
                            <li><a href="#" data-placement="bottom" title="Facebook"><i class="icon-facebook iconf"></i></a></li>
                            <li><a href="#" data-placement="bottom" title="Twitter"><i class="icon-twitter iconf"></i></a></li>
                            <li><a href="#" data-placement="bottom" title="Google plus"><i class="icon-google-plus iconf"></i></a></li>
                        </ul>
                    </div>
                </div>
            </div>
	</footer>
	<!-- End Footer-->	
    </div>
    <!-- End Wrapper-->
    
    <!-- Scrollup -->
    <a href="#" class="scrollup"><i class="icon-chevron-up icon-square icon-32 active"></i></a>
		
    <!-- start: MAIN JAVASCRIPTS -->
    <!-- Placed at the end of the document so the pages load faster -->
    <script src="<?php echo WEB_DIR_ROOT; ?>js/jquery-1.10.2.min.js"></script>
    <!--script src="<?php //echo WEB_DIR_ROOT; ?>ajax.googleapis.com/ajax/libs/jquery/1.8/jquery.min.js"></script-->
    <script src="<?php echo WEB_DIR_ROOT; ?>js/jquery.easing.1.3.js"></script>
    <script src="<?php echo WEB_DIR_ROOT; ?>js/bootstrap.js"></script>
    <script src="<?php echo WEB_DIR_ROOT; ?>js/jquery.fancybox.pack.js"></script>
    <script src="<?php echo WEB_DIR_ROOT; ?>js/jquery.fancybox-media.js"></script>
    <script src="<?php echo WEB_DIR_ROOT; ?>js/google-code-prettify/prettify.js"></script>

    <script src="<?php echo WEB_DIR_ROOT; ?>js/jquery.flexslider.js"></script>
    <script src="<?php echo WEB_DIR_ROOT; ?>js/jquery.nivo.slider.js"></script>
    <script src="<?php echo WEB_DIR_ROOT; ?>js/modernizr.custom.79639.js"></script>
    <script src="<?php echo WEB_DIR_ROOT; ?>js/jquery.ba-cond.min.js"></script>
    <script src="<?php echo WEB_DIR_ROOT; ?>js/animate.js"></script>
    <script src="<?php echo WEB_DIR_ROOT; ?>js/waypoints.js"></script>
    <script src="<?php echo WEB_DIR_ROOT; ?>js/waypoints-sticky.js"></script>
    <script src="<?php echo WEB_DIR_ROOT; ?>js/jQuery.appear.js"></script>
    <script src="<?php echo WEB_DIR_ROOT; ?>js/custom.js"></script>
    <script src="<?php echo WEB_DIR_ROOT; ?>js/jquery.flexisel.js" type="text/javascript"></script>
    <script src="<?php echo WEB_DIR_ROOT; ?>js/jquery.carouFredSel-6.1.0-packed.js" type="text/javascript"></script>
    
    <script src="<?php echo APP_DIR_ROOT; ?>jquery/custom.functions.js"></script>
    
    <?php echo $this->fetch('script'); ?>
    <?php echo $this->Js->writeBuffer(array('cache' => TRUE));?>
    
    <script type="text/javascript">
        function prevTimers() {
            return allTimers().slice( 0, $('.sliderindex5pager li.selected').index() );
        }
        function allTimers() {
            return $('.sliderindex5pager li span');
        }

        $(function() {
            $('#sliderindex5').carouFredSel({
                items: 1,
                responsive : true,
                auto: {
                    pauseOnHover: 'resume',
                    progress: {
                        bar: '.sliderindex5pager li:first span'
                    }
                },
                scroll: {
                    fx: 'crossfade',
                    duration: 500,
                    timeoutDuration: 4000,
                    onAfter: function() {
                        allTimers().stop().width( 0 );
                //	prevTimers().width(  );
                        $(this).trigger('configuration', [ 'auto.progress.bar', '.sliderindex5pager li.selected span' ]);
                    }
                },
                pagination: {
                    container: '.sliderindex5pager',
                    anchorBuilder: false
                }
            });
        });
    </script>
</body>
</html>
