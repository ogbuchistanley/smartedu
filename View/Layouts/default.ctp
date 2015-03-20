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
<?php 
    
    $employee_index = Configure::read('employee_index');
    $employee_register = Configure::read('employee_register');
    $employee_adjust = Configure::read('employee_adjust');
    
    $exam_index = Configure::read('exam_index');
    //$exam_setup_exam = Configure::read('exam_setup_exam');
    
    $student_index = Configure::read('student_index');
    $student_register = Configure::read('student_register');
    
    $sponsor_index = Configure::read('sponsor_index');
    $sponsor_register = Configure::read('sponsor_register');
    
    $item_index = Configure::read('item_index');
    $item_process_fees = Configure::read('item_process_fees');
    
    $classroom_index = Configure::read('classroom_index');
    $classroom_myclass = Configure::read('classroom_myclass');
    
    $subject_add2class = Configure::read('subject_add2class');
    $record_index = Configure::read('record_index');
    $msg_index = Configure::read('msg_index');
    $attend_index = Configure::read('attend_index');
    $user_index = Configure::read('user_index');
    
    //Disable The Links For Parents if user role > 2
    $user_role = Configure::read('user_role');

    //Master Record Setup status
    $master_record_id = Configure::read('master_record_id');
    //Master Record Count
    $master_record_count = Configure::read('master_record_count');
?>

<?php 
    App::uses('Encryption', 'Utility'); 
    $Encryption = new Encryption();
    
    //$term_id = ClassRegistry::init('AcademicTerm');
?>
<!DOCTYPE html>
<html lang="en" ng-app="">
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
    <link href="<?php echo APP_DIR_ROOT; ?>css/bootstrap.css" rel="stylesheet">
    <link href="<?php echo APP_DIR_ROOT; ?>css/bootstrap-modal-bs3fix.css" rel="stylesheet">    

    <!-- Loading Stylesheets -->    
    <link href="<?php echo APP_DIR_ROOT; ?>css/jquery-ui.css" rel="stylesheet">
    <link href="<?php echo APP_DIR_ROOT; ?>css/font-awesome.css" rel="stylesheet">
    <link href="<?php echo APP_DIR_ROOT; ?>css/style.css" rel="stylesheet" type="text/css"> 
    <link href="<?php echo APP_DIR_ROOT; ?>less/style.less" rel="stylesheet"  title="lessCss" id="lessCss">
    
    <!-- Loading Custom Stylesheets -->   
    <link href="<?php echo APP_DIR_ROOT; ?>css/jquery.autocomplete.css" rel="stylesheet">
    <link href="<?php echo APP_DIR_ROOT; ?>css/custom.css" rel="stylesheet">
    <link href="<?php echo APP_DIR_ROOT; ?>images/icon.png" rel="shortcut icon">
    <!-- HTML5 shim, for IE6-8 support of HTML5 elements. All other JS at the end of file. -->
    <!--[if lt IE 9]>
        <script src="http://html5shim.googlecode.com/svn/trunk/html5.js"></script>
    <![endif]-->
    	
    <!-- end: CSS-->
     <style type="text/css">
        .ui-datepicker {
           background: #495b79;
           border: 2px solid #29a2d7;
           color: #ffffff;
         }
         
        .ui-datepicker-header{
            background: #29a2d7;
            border: 1px solid #ffffff;
            color: #dddddd;
         }
         
        .ui-datepicker .ui-datepicker-next-hover,
        .ui-datepicker .ui-datepicker-prev-hover,
        .ui-datepicker .ui-corner-all{
            background: #495b79;
        }
    </style>
</head>

<body onload="javascript:showTime();">
    <!-- .site-holder -->
    <div class="site-holder">
        <!-- .navbar -->
        <nav class="navbar show" role="navigation">
            
            <!-- Brand and toggle get grouped for better mobile display -->
            <div class="navbar-header">
                <a class="navbar-brand" href="#">
                    <i class="fa fa-list btn-nav-toggle-responsive text-white"></i>
                </a>
                <a class="navbar-brand" href="<?php echo DOMAIN_NAME ?>/dashboard">
                    <span class="logo small"><?php echo substr(APP_NAME, 0, 5)?><img style="width: 55px; height: 57px;" src="<?php echo APP_DIR_ROOT; ?>images/icon.png" /><?php echo substr(APP_NAME, 5); ?></span>
                </a>
            </div>

            <!-- Collect the nav links, forms, and other content for toggling -->
            <div class="collapse navbar-collapse">
                <ul class="nav navbar-nav user-menu navbar-right ">
                    <li>
                        <a href="javascript:void(0);" class="user dropdown-toggle" data-toggle="dropdown">
                            <span class="username">
                                <?php 
                                    $fullnames = explode(' ', AuthComponent::user('display_name'));
                                    $temp = (isset($fullnames[1])) ? $fullnames[1] : '';
                                    $name = $fullnames[0] . ', ' . strtoupper(substr($temp, 0, 1)) . '.';
                                ?>
                                <img src="<?php echo DOMAIN_NAME ?>/img/uploads/<?php echo (AuthComponent::user('image_url')) ? AuthComponent::user('image_url') : 'avatar.jpg';?>" class="user-avatar" alt="">
                                <?php echo $name;?>
                            </span>
                        </a>
                        <ul class="dropdown-menu" id="user_profile">
                            <li class="divider"></li>
                            <li><a href="<?php echo DOMAIN_NAME ?>/users/change" rel="inbox" class="text-primary"><i class="fa fa-exchange"></i> Change Password</a></li>
                            <li class="divider"></li>
                            <li><a href="<?php echo DOMAIN_NAME ?>/logout" class="text-danger"><i class="fa fa-lock"></i> Logout</a></li>
                        </ul>
                    </li>
                    <!--li>
                        <a href="javascript:void()" class=" dropdown-toggle" >
                            <span  class="username"> 
                                <i class="fa fa-calendar fa-1x"></i> <?php echo '  ',date("D, jS M, Y");  ?> 
                                <!--span id="timer"></span-->
                            </span>
                        </a>
                    </li-->
                </ul>
            </div><!-- /.navbar-collapse -->
        </nav> <!-- /.navbar -->

        <!-- .box-holder -->
        <div class="box-holder">
            <!-- .left-sidebar -->
            <div class="left-sidebar">
                <div class="sidebar-holder">
                    <ul class="nav  nav-list" id="nav_menu">
                        <!-- sidebar to mini Sidebar toggle -->
                        <li class="nav-toggle">
                            <button class="btn  btn-nav-toggle text-primary"><i class="fa fa-angle-double-left toggle-left"></i> </button>
                        </li>
                        <!--- Enable Links for Admin Users-->
                        <?php if($user_role > 2): ?>
                            <?php if($master_record_id > ($master_record_count) - 1): ?>
                                <li class="active"><a href="<?php echo DOMAIN_NAME ?>/dashboard/" data-original-title="Dashboard"><i class="fa fa-dashboard"></i><span class="hidden-minibar"> Dashboard</span></a></li>
                                <?php if($student_index || $student_register): ?>
                                <li class="submenu">
                                    <a class="dropdown" href="javascript:void(0)" data-original-title="Students"><i class="fa fa-group"></i><span class="hidden-minibar">  Students <span class="badge bg-primary pull-right" id="student_count"></span></span></a>
                                    <ul>
                                    <?php if($student_index): ?>
                                        <li><a href="<?php echo DOMAIN_NAME ?>/students/" data-original-title="Manage Students"><i class="fa fa-gear"></i><span> Manage Students</span></a></li>
                                    <?php endif;?>
                                    <?php if($student_register): ?>
                                        <li><a href="<?php echo DOMAIN_NAME ?>/students/register" data-original-title="Register New"><i class="fa fa-plus-square"></i><span> Register New</span></a></li>
                                    <?php endif;?>
                                    </ul>
                                </li>
                                <?php endif;?>
                                <?php if($sponsor_index || $sponsor_register): ?>
                                <li class="submenu">
                                    <a class="dropdown" href="javascript:void(0)" data-original-title="Parents"><i class="fa fa-male"></i><span class="hidden-minibar">  Parents <span class="badge bg-primary pull-right" id="sponsor_count"></span></span></a>
                                    <ul>
                                    <?php if($sponsor_index): ?>
                                        <li><a href="<?php echo DOMAIN_NAME ?>/sponsors/" data-original-title="Manage Parents"><i class="fa fa-gear"></i><span> Manage Parents</span></a></li>
                                    <?php endif;?>
                                    <?php if($sponsor_register): ?>
                                        <li><a href="<?php echo DOMAIN_NAME ?>/sponsors/register" data-original-title="Register New"><i class="fa fa-plus-circle"></i><span> Register New</span></a></li>
                                    <?php endif;?>
                                    </ul>
                                </li>
                                <?php endif;?>
                                <?php if($employee_index || $employee_register || $employee_adjust): ?>
                                <li class="submenu">
                                    <a class="dropdown" href="javascript:void(0)" data-original-title="Staffs"><i class="fa fa-user"></i><span class="hidden-minibar">  Staffs <span class="badge bg-primary pull-right" id="employee_count"></span></span></a>
                                    <ul>
                                    <?php if($employee_index): ?>
                                        <li><a href="<?php echo DOMAIN_NAME ?>/employees/" data-original-title="505"><i class="fa fa-gear"></i><span> Manage Staffs</span></a></li>
                                    <?php endif;?>
                                    <?php if($employee_register): ?>
                                        <li><a href="<?php echo DOMAIN_NAME ?>/employees/register" data-original-title="404"><i class="fa fa-plus-circle"></i><span> Register New</span></a></li>
                                    <?php endif;?>
                                    <?php if($employee_adjust): ?>
                                        <li><a href="<?php echo DOMAIN_NAME ?>/employees/adjust/<?php echo $Encryption->encode(AuthComponent::user('type_id')) ?>" data-original-title="404"><i class="fa fa-plus-circle"></i><span> Update Record</span></a></li>
                                    <?php endif;?>
                                    </ul>
                                </li>
                                <?php endif;?>
                                <?php if($subject_add2class): ?>
                                <li class="submenu">
                                    <a class="dropdown" href="javascript:void(0)" data-original-title="Subjects"><i class="fa fa-book"></i><span class="hidden-minibar">  Subjects <span class="badge bg-primary pull-right" id="subject_count"></span></span></a>
                                    <ul>
                                        <li><a href="<?php echo DOMAIN_NAME ?>/subjects/add2class#assign2class" data-original-title="404"><i class="fa fa-plus-square"></i><span> Assign To Classes</span></a></li>
                                        <li><a href="<?php echo DOMAIN_NAME ?>/subjects/add2class#assign2teachers" data-original-title="404"><i class="fa fa-plus-circle"></i><span>  Assign Tutor</span></a></li>
                                        <li><a href="<?php echo DOMAIN_NAME ?>/subjects/add2class#adjust_subjects_assign" data-original-title="404"><i class="fa fa-edit"></i><span> Modify/Manage Students</span></a></li>
                                        <li><a href="<?php echo DOMAIN_NAME ?>/subjects/index" data-original-title="404"><i class="fa fa-eye-slash"></i><span> View Scores</span></a></li>
                                    </ul>
                                </li>
                                <?php endif;?>
                                <?php if($attend_index === 'hide'): ?>
                                    <li  class="submenu">
                                        <a class="dropdown" href="javascript:void(0)" data-original-title="Class Room"><i class="fa fa-check-square"></i><span class="hidden-minibar"> Attendance <span class="badge bg-primary pull-right" id="attend_count"></span></span></a>
                                        <ul>
                                            <li><a href="<?php echo DOMAIN_NAME ?>/attends/index#take_attend"><i class="fa fa-check-square-o"></i><span> Take / Mark</span></a></li>
                                            <li><a href="<?php echo DOMAIN_NAME ?>/attends/index#edit_attend"><i class="fa fa-search-plus"></i><span> View / Edit</span></a></li>
                                            <li><a href="<?php echo DOMAIN_NAME ?>/attends/index#summary"><i class="fa fa-plus-square"></i><span> Summary</span></a></li>
                                        </ul>
                                    </li>
                                <?php endif;?>
                                <?php if($classroom_index || $classroom_myclass): ?>
                                <li  class="submenu">
                                    <a class="dropdown" href="javascript:void(0)" data-original-title="Class Room"><i class="fa fa-building"></i><span class="hidden-minibar"> Class Room <span class="badge bg-primary pull-right" id="class_count"></span></span></a>
                                    <ul>
                                        <?php if($classroom_index): ?>
                                            <li><a href="<?php echo DOMAIN_NAME ?>/classrooms/index#assign_students"><i class="fa fa-plus-circle"></i><span> Add Students </span></a></li>
                                            <li><a href="<?php echo DOMAIN_NAME ?>/classrooms/index#search_students"><i class="fa fa-search-plus"></i><span> Search For Students</span></a></li>
                                            <li><a href="<?php echo DOMAIN_NAME ?>/classrooms/index#assign_head_tutor"><i class="fa fa-plus-square"></i><span> Assign Class Teacher</span></a></li>
                                        <?php endif;?>
                                        <li><a href="<?php echo DOMAIN_NAME ?>/classrooms/myclass"><i class="fa fa-building"></i><span> My Classroom(s)</span></a></li>
                                    </ul>
                                </li>
                                <?php endif;?>
                                <?php if($exam_index): ?>
                                <li class="submenu">
                                    <a class="dropdown" href="javascript:void(0)" data-original-title="Assessments"><i class="fa fa-bookmark"></i><span class="hidden-minibar"> Assessments <span class="badge bg-primary pull-right" id="exams_count"></span></span></a>
                                    <ul>
                                        <?php //if($exam_setup_exam): ?>
                                        <li><a href="<?php echo DOMAIN_NAME ?>/exams/index#setupExam" data-original-title="Setup / Adjust Exams"><i class="fa fa-gear"></i><span> Setup / Adjust Exams</span></a></li>
                                        <?php //endif;?>
                                        <li><a href="<?php echo DOMAIN_NAME ?>/exams/index#subjectScores" data-original-title="Input / Edit Scores"><i class="fa fa-th"></i><span> Input / Edit Scores</span></a></li>
                                        <li><a href="<?php echo DOMAIN_NAME ?>/exams/index#viewTAScores" data-original-title="Adjust Exams"><i class="fa fa-eye"></i><span> Terminal / Annual Scores</span></a></li>
                                        <li><a href="<?php echo DOMAIN_NAME ?>/assessments" data-original-title="Skills Assessment"><i class="fa fa-magic"></i><span> Skills Assessment</span></a></li>
                                    </ul>
                                </li>
                                <?php endif;?>
                                <?php if($item_index === 'hide'): ?>
                                <li class="submenu">
                                    <a href="javascript:void(0)" data-original-title="Bills / Fees"><i class="fa fa-money"></i><span class="hidden-minibar"> Item Bills / Fees <span class="badge bg-primary pull-right" id="fees_count"></span></span></a>
                                    <ul>
                                        <li><a href="<?php echo DOMAIN_NAME ?>/items/summary" data-original-title="Current Term Summary"><i class="fa fa-dashboard"></i><span> Current Term Summary</span></a></li>
                                        <?php if($item_process_fees):?>
                                        <li><a href="<?php echo DOMAIN_NAME ?>/items/index#process_fees" data-original-title="Process Fees"><i class="fa fa-gear"></i><span> Process Fees</span></a></li>
                                        <?php endif;?>
                                        <li><a href="<?php echo DOMAIN_NAME ?>/items/index#bill_student" data-original-title="Bill Student / Class"><i class="fa fa-money"></i><span> Bill Student / Class</span></a></li>
                                        <!--li><a href="<?php //echo DOMAIN_NAME ?>/items/index#search" data-original-title="Search History"><i class="fa fa-search"></i><span> Search History</span></a></li-->
                                    </ul>
                                </li>
                                <?php endif;?>
                                <?php if($msg_index === 'hide'): ?>
                                    <li class="submenu">
                                        <a href="javascript:void(0)" data-original-title="Message Center"><i class="fa fa-envelope"></i><span class="hidden-minibar"> Message Center <span class="badge bg-primary pull-right" id="message_count"></span></span></a>
                                        <ul>
                                            <li><a href="<?php echo DOMAIN_NAME ?>/messages/index#sponsors" data-original-title="Parents"><i class="fa fa-user"></i><span> Parents</span></a></li>
                                            <li><a href="<?php echo DOMAIN_NAME ?>/messages/index#employees" data-original-title="Staffs"><i class="fa fa-male"></i><span> Staffs</span></a></li>
                                            <li><a href="<?php echo DOMAIN_NAME ?>/messages/recipient" data-original-title="Recipient"><i class="fa fa-group"></i><span> Recipients</span></a></li>
                                        </ul>
                                    </li>
                                <?php endif;?>
                                <!--li class="submenu">
                                    <a class="dropdown" href="javascript:void(0)" data-original-title="Pages"><i class="fa fa-book"></i><span class="hidden-minibar">  Reports </span>
                                    </a>
                                    <ul>
                                        <li><a href="javascript:void(0)" data-original-title="Calendar"><i class="fa fa-calendar"></i><span> Calendar</span></a></li>
                                        <li><a href="javascript:void(0)" data-original-title="Chat"><i class="fa fa-comment"></i><span> Chat</span></a></li>
                                        <li><a href="javascript:void(0)" data-original-title="Profile Activity"><i class="fa fa-th"></i><span> Profile Activity</span></a></li>

                                        <li><a href="javascript:void(0)" data-original-title="Gallery"><i class="fa fa-th"></i><span> Gallery</span></a></li>
                                        <li><a href="javascript:void(0)" data-original-title="Grids"><i class="fa fa-th-large"></i><span> Grids</span></a></li>
                                    </ul>
                                </li-->
                                <?php if($record_index): ?>
                                <li class="submenu">
                                    <a class="dropdown" href="javascript:void(0)" data-original-title="Master Records">
                                        <i class="fa fa-sitemap"></i><span class="hidden-minibar"> Master Records <span class="badge bg-primary pull-right" id="record_count"></span></span>
                                    </a>
                                    <ul>
                                        <li><a href="<?php echo DOMAIN_NAME ?>/records/academic_year" data-original-title="Academic Years"><i class="fa fa-outdent"></i><span> Academic Years</span></a></li>
                                        <li><a href="<?php echo DOMAIN_NAME ?>/records/index" data-original-title="Academic Terms"><i class="fa fa-ticket"></i><span> Academic Terms</span></a></li>
                                        <li><a href="<?php echo DOMAIN_NAME ?>/records/class_group" data-original-title="Class Group"><i class="fa fa-xing"></i><span> Class Group</span></a></li>
                                        <li><a href="<?php echo DOMAIN_NAME ?>/records/class_level" data-original-title="Class Level"><i class="fa fa-trello"></i><span> Class Level</span></a></li>
                                        <li><a href="<?php echo DOMAIN_NAME ?>/records/class_room" data-original-title="Class Rooms"><i class="fa fa-group"></i><span> Class Rooms</span></a></li>
                                        <li><a href="<?php echo DOMAIN_NAME ?>/records/subject_group" data-original-title="Subject Group"><i class="fa fa-align-left"></i><span> Subject Groups</span></a></li>
                                        <li><a href="<?php echo DOMAIN_NAME ?>/records/subject" data-original-title="Subject"><i class="fa fa-file-text"></i><span> Subjects</span></a></li>
                                        <li><a href="<?php echo DOMAIN_NAME ?>/records/grade" data-original-title="Grade Grouping"><i class="fa fa-renren"></i><span> Grade Grouping</span></a></li>
                                        <!--li><a href="<?php echo DOMAIN_NAME ?>/records/item" data-original-title="Items"><i class="fa fa-compass"></i><span> Items</span></a></li>
                                        <li><a href="<?php echo DOMAIN_NAME ?>/records/item_bill" data-original-title="Item Bills"><i class="fa fa-money"></i><span> Item Bills</span></a></li-->
                                    </ul>
                                </li>
                                <?php endif;?>
                                <?php if($user_index): ?>
                                    <li><a href="<?php echo DOMAIN_NAME ?>/users/index" data-original-title="Users"><i class="fa fa-user"></i><span> Manage Users</span></a></li>
                                    <!--li><a href="<?php echo DOMAIN_NAME ?>/users/register" data-original-title="Users"><i class="fa fa-exclamation-circle"></i><span> Register New</span></a></li-->
                                <?php endif;?>
                            <?php else:?>
                                <?php if($record_index): ?>
                                    <li class="submenu">
                                        <a class="dropdown" href="javascript:void(0)" data-original-title="Master Records">
                                            <i class="fa fa-sitemap"></i><span class="hidden-minibar"> Master Records <span class="badge bg-primary pull-right" id="record_count"></span></span>
                                        </a>
                                        <ul>
                                            <li><a href="<?php echo DOMAIN_NAME ?>/records/academic_year" data-original-title="Academic Years"><i class="fa fa-outdent"></i><span> Academic Years</span></a></li>
                                            <?php if($master_record_id > 0): ?>
                                                <li><a href="<?php echo DOMAIN_NAME ?>/records/index" data-original-title="Academic Terms"><i class="fa fa-ticket"></i><span> Academic Terms</span></a></li>
                                            <?php endif;?>
                                            <?php if($master_record_id > 1): ?>
                                                <li><a href="<?php echo DOMAIN_NAME ?>/records/class_group" data-original-title="Class Group"><i class="fa fa-xing"></i><span> Class Group</span></a></li>
                                            <?php endif;?>
                                            <?php if($master_record_id > 2): ?>
                                                <li><a href="<?php echo DOMAIN_NAME ?>/records/class_level" data-original-title="Class Level"><i class="fa fa-trello"></i><span> Class Level</span></a></li>
                                            <?php endif;?>
                                            <?php if($master_record_id > 3): ?>
                                                <li><a href="<?php echo DOMAIN_NAME ?>/records/class_room" data-original-title="Class Rooms"><i class="fa fa-group"></i><span> Class Rooms</span></a></li>
                                            <?php endif;?>
                                            <?php if($master_record_id > 4): ?>
                                                <li><a href="<?php echo DOMAIN_NAME ?>/records/subject_group" data-original-title="Subject Group"><i class="fa fa-align-left"></i><span> Subject Groups</span></a></li>
                                            <?php endif;?>
                                            <?php if($master_record_id > 5): ?>
                                                <li><a href="<?php echo DOMAIN_NAME ?>/records/subject" data-original-title="Subject"><i class="fa fa-file-text"></i><span> Subjects</span></a></li>
                                            <?php endif;?>
                                            <?php if($master_record_id > 6): ?>
                                                <li><a href="<?php echo DOMAIN_NAME ?>/records/grade" data-original-title="Grade Grouping"><i class="fa fa-renren"></i><span> Grade Grouping</span></a></li>
                                            <?php endif;?>
                                            <?php if($master_record_id > 7): ?>
                                                <li><a href="<?php echo DOMAIN_NAME ?>/records/item_bill" data-original-title="Item Bills"><i class="fa fa-money"></i><span> Item Bills</span></a></li>
                                            <?php endif;?>
                                            <?php if($master_record_id > 8): ?>
                                                <li><a href="<?php echo DOMAIN_NAME ?>/records/item" data-original-title="Items"><i class="fa fa-compass"></i><span> Items</span></a></li>
                                            <?php endif;?>
                                        </ul>
                                    </li>
                                <?php endif;?>
                            <?php endif;?>
                        <?php else:?>
                            <!--- Enable Links for Parent Users-->
                            <?php
                                $encrypted_sponsor_id = $Encryption->encode(AuthComponent::user('type_id'));
                            ?>
                            <li><a href="<?php echo DOMAIN_NAME ?>/home" data-original-title="Class"><i class="fa fa-dashboard"></i> <span class="hidden-minibar"> Home</span></a></li>
                            <li class="submenu">
                                <a class="dropdown" href="javascript:void(0)" data-original-title="Parent"><i class="fa fa-male"></i><span class="hidden-minibar">  Parent <span class="badge bg-primary pull-right" id="sponsor_count"></span></span></a>
                                <ul>
                                    <li><a href="<?php echo DOMAIN_NAME; ?>/sponsors/view/<?php echo $encrypted_sponsor_id; ?>" data-original-title="My Record"><i class="fa fa-eye"></i><span> My Record</span></a></li>
                                    <li><a href="<?php echo DOMAIN_NAME ?>/sponsors/adjust/<?php echo $encrypted_sponsor_id; ?>" data-original-title="Adjust Record"><i class="fa fa-edit"></i><span> Adjust Record</span></a></li>
                                </ul>
                            </li>
                            <li class="submenu">
                                <a class="dropdown" href="javascript:void(0)" data-original-title="Student"><i class="fa fa-group"></i><span class="hidden-minibar">  Student <span class="badge bg-primary pull-right" id="student_count"></span></span></a>
                                <ul>
                                    <li><a href="<?php echo DOMAIN_NAME; ?>/home/students" data-original-title="My Student"><i class="fa fa-eye"></i><span> My Student(s)</span></a></li>
                                    <li><a href="<?php echo DOMAIN_NAME ?>/home/exam" data-original-title="Exam Record"><i class="fa fa-bookmark"></i><span> Exam Record</span></a></li>
                                </ul>
                            </li>
                        <?php endif;?>
                        <li><a href="<?php echo DOMAIN_NAME ?>/users/change" data-original-title="Class"><i class="fa fa-exchange"></i> <span class="hidden-minibar"> Change Password</span></a></li>
                        <li><a href="<?php echo DOMAIN_NAME ?>/logout" data-original-title="Class"><i class="fa fa-lock"></i><span class="hidden-minibar"> Logout</span></a></li>
                    </ul>
                </div>
            </div> 
            <!-- /.left-sidebar -->

            <!-- .content -->
            <div class="content" id="main_content">
                <div class="row">
                    <div class="col-mod-12">
                        <ul class="breadcrumb">
                             <?php if($user_role > 2){ ?>
                                <li class="active"><a href="<?php echo DOMAIN_NAME ?>/dashboard/"><i class="fa fa-dashboard"></i> Dashboard</a></li>
                             <?php }else{ ?>
                                <li class="active"><a href="<?php echo DOMAIN_NAME ?>/home/"><i class="fa fa-dashboard"></i> Home</a></li>
                            <?php };?>
                            <li><a href="<?php echo DOMAIN_NAME ?>/logout" class="text-danger"><i class="fa fa-lock"></i> Logout</a></li>
                            <li>
                                    <span  class="username">
                                        <i class="fa fa-calendar fa-1x"></i> <?php echo '  ',date("D, jS M, Y");  ?>
                                        <span id="timer"></span>
                                    </span>
                            </li>
                        </ul>
                    </div>
                </div>

                <div class="row">
                    <div id="msg_box1" class="alert alert-info hide">
                        <?php echo  $this->Html->image('loader.gif', array('id' => 'msg_box1')); ?>
                        <span style='color:green; margin:15px; font-size: 18px;'> Loading...</span>
                    </div>
                </div>
                <div class="row">
                    <noscript>
                        <div style="margin:0 0 35px 0; text-align:center" class="alert alert-danger">
                          <h4> <strong><i class="icon-warning-sign"></i> Attention!!!</strong></h4>
                           Javascript is not enabled on this browser. To enjoy this application, turn on Javascript or use another
                          <i>Javascript enabled browser.</i>
                        </div>  
                    </noscript>
                </div>
                <div class="row">                    
                    <?php
                        $errors = $this->Form->validationErrors;
                        $flatErrors = Set::flatten($errors);
                        $flatErrors2 = $flatErrors;
                        $test = array();
                        foreach($flatErrors as $key => $value){
                            $test[] = $value;
                        }
                        if(!empty($test[count($test) - 1])) {
                            echo '<div class="alert alert-danger">';
                            echo '<ul>';
                            foreach($flatErrors2 as $key => $value) {
                                echo (!empty($value)) ? '<li>'.$value.'</li>' : false;
                            }
                            echo '</ul>';
                            echo '</div>';
                        }
                    ?>
                </div>     
                
                <div class="row">
                    <?php echo $this->Session->flash(); ?>                    
                </div>
                
                <div class="row">
                    <?php echo $this->fetch('content'); ?>                    
                </div>

                <div class="footer">
                    Copyright &copy; <a target="__blank" href="<?php echo DEVELOPER_SITE_ADDRESS;?>" class="text-info"><?php echo DEVELOPER_SITE_NAME;?></a> <?php echo date("Y") ?> 
                    <a href="#" class="scrollup col-sm-offset-3"><i class="fa fa-chevron-up"></i></a>
                </div>
            </div> 
            <!-- /.content -->
        </div>
        <!-- /.box-holder -->
    </div>
    <!-- /.site-holder -->         
		
    <!-- start: MAIN JAVASCRIPTS -->
    <!-- Load JS here for Faster site load =============================-->
    <script src="<?php echo APP_DIR_ROOT; ?>js/jquery-1.10.2.js"></script>
    <script src="<?php echo APP_DIR_ROOT; ?>js/jquery-ui-1.10.3.custom.js"></script>
    <script src="<?php echo APP_DIR_ROOT; ?>js/less-1.5.0.min.js"></script>
    <script src="<?php echo APP_DIR_ROOT; ?>js/jquery.ui.touch-punch.min.js"></script>
    <script src="<?php echo APP_DIR_ROOT; ?>js/bootstrap.min.js"></script>
    <script src="<?php echo APP_DIR_ROOT; ?>js/bootstrap-select.js"></script>
    <script src="<?php echo APP_DIR_ROOT; ?>js/bootstrap-switch.js"></script>
    <script src="<?php echo APP_DIR_ROOT; ?>js/jquery.tagsinput.js"></script>
    <script src="<?php echo APP_DIR_ROOT; ?>js/jquery.placeholder.js"></script>
    <script src="<?php echo APP_DIR_ROOT; ?>js/bootstrap-typeahead.js"></script>
    <script src="<?php echo APP_DIR_ROOT; ?>js/bootstrap-datepicker.js"></script>
    <script src="<?php echo APP_DIR_ROOT; ?>js/application.js"></script>
    <script src="<?php echo APP_DIR_ROOT; ?>js/moment.min.js"></script>
    <script src="<?php echo APP_DIR_ROOT; ?>js/jquery.dataTables.min.js"></script>
    <script src="<?php echo APP_DIR_ROOT; ?>js/jquery.sortable.js"></script>
    <script src="<?php echo APP_DIR_ROOT; ?>js/jquery.gritter.js" type="text/javascript" ></script>
    <script src="<?php echo APP_DIR_ROOT; ?>js/jquery.nicescroll.min.js"></script>
    <script src="<?php echo APP_DIR_ROOT; ?>js/prettify.min.js"></script>
    <script src="<?php echo APP_DIR_ROOT; ?>js/jquery.noty.js"></script>
    <script src="<?php echo APP_DIR_ROOT; ?>js/bic_calendar.js"></script>
    <script src="<?php echo APP_DIR_ROOT; ?>js/jquery.accordion.js"></script>
    <script src="<?php echo APP_DIR_ROOT; ?>js/skylo.js"></script>

    <script src="<?php echo APP_DIR_ROOT; ?>js/bootstrap-progressbar.js"></script>
    <script src="<?php echo APP_DIR_ROOT; ?>js/bootstrap-progressbar-custom.js"></script>
    <script src="<?php echo APP_DIR_ROOT; ?>js/bootstrap-colorpicker.min.js"></script>
    <script src="<?php echo APP_DIR_ROOT; ?>js/bootstrap-colorpicker-custom.js"></script>
    
    <!-- Angular-->
    <script src="<?php echo APP_DIR_ROOT; ?>js/angular.min.js"></script>
    
    <script src="<?php echo APP_DIR_ROOT; ?>js/jquery.smartWizard.js"></script>
    <script src="<?php echo APP_DIR_ROOT; ?>js/smartWizard-custom.js"></script>
    <script src="<?php echo APP_DIR_ROOT; ?>js/validate.js"></script>
    <script src="<?php echo APP_DIR_ROOT; ?>js/validation-custom.js"></script>
    
    <!-- Modal-->
    <script src="<?php echo APP_DIR_ROOT; ?>js/bootstrap-modalmanager.js"></script>
    <script src="<?php echo APP_DIR_ROOT; ?>js/bootstrap-modal.js"></script>

    <!-- jQuery UI-->
    <script src="<?php echo APP_DIR_ROOT; ?>js/ui/jquery.ui.autocomplete.min.js"></script>
    <!-- jQuery Pulsate-->
    <script src="<?php echo APP_DIR_ROOT; ?>js/jquery.pulsate.min.js"></script>
    
    <!-- Core Jquery File  =============================-->
    <script src="<?php echo APP_DIR_ROOT; ?>js/core.js"></script>
    <script src="<?php echo APP_DIR_ROOT; ?>jquery/custom.functions.js"></script>

    <!--script src="<?php //echo APP_DIR_ROOT; ?>js/icheck/icheck.js"></script-->
    <?php //echo $scripts_for_layout; ?>
    
    <?php echo $this->fetch('script'); ?>
    <?php echo $this->Js->writeBuffer(array('cache' => TRUE));?>
    
    <script type="text/javascript">
        $('document').ready(function(){
//            $('.square-input').iCheck({
//                checkboxClass: 'icheckbox_square-orange',
//                radioClass: ' iradio_square-orange',
//                increaseArea: '20%' // optional
//            });
        });
    </script>
</body>
</html>