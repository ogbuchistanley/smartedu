<?php
    $TermModel = ClassRegistry::init('AcademicTerm');  //print_r($test);
    $WeeklyReportModel = ClassRegistry::init('WeeklyReport');  //print_r($test);
    $temp = $Subjects;
    $temp = array_shift($temp);
    $marked_report = $marked_report['marked_report'];
    //print_r($temp);

?>
<!DOCTYPE html>
<html lang="en">
<head>
    <head>
        <title>Student Terminal Result Sheet</title>
        <link href="<?php echo APP_DIR_ROOT; ?>css/bootstrap.css" rel="stylesheet">
        <link href="<?php //echo APP_DIR_ROOT; ?>css/style.css" rel="stylesheet" type="text/css">
        <link href="<?php echo APP_DIR_ROOT; ?>images/icon.png" rel="shortcut icon">
        <link href="<?php echo APP_DIR_ROOT; ?>css/print.css" rel="stylesheet" media="print">
        <style type="text/css">
            .table th,
            .table td {
                padding: 6px;
                line-height: 13px;
                text-align: left;
                vertical-align: top;
                border-top: 1px solid #dddddd;
            }
            #apDiv1 {
                position:absolute;
                left:0px;
                top:105px;
                width:850px;
                z-index:1;
                text-align: center;
            }
            #apDiv2 {
                position:absolute;
                left:700px;
                top:33px;
                width:300px;
                z-index:2;
            }

            #apDi1 {
                position:absolute;
                left:0px;
                top:33px;
                bottom: 50px;
                width:670px;
                z-index:3;
            }
            .style1 {font-size: x-small;}
        </style>
    </head>
    <body style="padding-top: 15px; background-color: white" bgcolor="white">
    <div class="container-fluid">
        <div class="you">
            <div align="center" style="width:100%">
                <div align="center"><img style="width: 80px; height: 80px;;" src="<?php echo APP_DIR_ROOT; ?>images/bells_logo.png" alt="School Logo"/></div>

                <div style="color:#666; font-size: 40px; font-weight: bolder; font-family: "verdana", "lucida grande", sans-serif"> THE BELLS</div>
                <div style="font-size: 14px; font-weight: bold;">Comprehensive Secondary School for Boys and Girls<br>Ota, Ogun State</div>
                <h5>MOTTO: Learn &nbsp; . &nbsp; Live &nbsp; . &nbsp; Lead </h5>
                <h6>website: http://www.thebellsschools.org</h6>
                <div align="center">
                    <h5><strong><?php echo h($temp['academic_term']), ' ACADEMIC SESSION REPORT' ;?></strong></h5>
                </div>
            </div>
            <div style="position:relative; width:100%">
                <div  style="position:relative">
                    <div id="apDi1">
                        <table class="table table-bordered" width="850">
                            <caption style="font-weight: bolder">Student's Information</caption>
                            <?php if($temp): ?>
                                <tr>
                                    <th width="120" style="background-color: #F2F0F0 !important;">Full Name: </th>
                                    <td width="200"><?php echo h($temp['student_name']);?></td>
                                    <th width="100" style="background-color: #F2F0F0 !important;">Student ID: </th>
                                    <td width="100"><?php echo h($temp['student_no']);?></td>
                                    <th width="100" style="background-color: #F2F0F0 !important;">Gender: </th>
                                    <td width="100"><?php echo h($temp['gender']);?></td>
                                </tr>
                                <tr>
                                    <th width="120" style="background-color: #F2F0F0 !important;">Parent Name: </th>
                                    <td width="200"><?php echo $temp['sponsor_name'];?></td>
                                    <th width="100" style="background-color: #F2F0F0 !important;">Parent ID: </th>
                                    <td width="100"><?php echo h($temp['sponsor_no']);?></td>
                                    <th width="100" style="background-color: #F2F0F0 !important;">Class: </th>
                                    <td width="100"><?php echo h($temp['class_name']);?></td>
                                </tr>
                            <?php else:?>
                                <tr>
                                    <th>No Record Found</th>
                                </tr>
                            <?php endif;?>
                        </table>
                    </div>
                    <div id="apDiv2">
                        <div class="price-box col-md-3 col-sm-6 col-xs-12 col-lg-3 featured">
                            <img class="img-rounded" data-src="holder.js/140x140"  style='width: 140px; height: 140px;'
                                 src="<?php echo DOMAIN_NAME ?>/img/uploads/<?php echo ($temp['image_url']) ? $temp['image_url'] : 'avatar.jpg';?>"/>
                        </div>
                    </div>
                    <div id="apDiv1">
                        <table class="table table-bordered" width="750" style="margin-top: 65px;">
                            <caption style="font-weight: bolder">Weekly Subject Continuous Assessment (C.A) / Weight Points (W.A)</caption>
                            <?php if(!empty($Subjects)):?>
                                <thead>
                                    <tr style="font-weight:bold; background-color:#CCCCCC;">
                                        <th width="8"></th>
                                        <th width="800" colspan="<?php echo $marked_report + 1;?>" style="text-align: center">Weekly Report Assessment Scores</th>
                                    </tr>
                                    <?php
                                        $WPs = $WeeklyReportModel->query('SELECT a.* FROM weeklyreport_studentdetailsviews a WHERE a.academic_term_id="'.$temp['academic_term_id'].'" AND a.marked_status=1
                                        AND a.class_id="'.$temp['class_id'].'" AND a.student_id="'.$temp['student_id'].'" AND a.subject_id=(SELECT subject_id FROM
                                        (SELECT COUNT(subject_id) AS weight_point, subject_id FROM weeklyreport_studentdetailsviews WHERE academic_term_id="'.$temp['academic_term_id'].'" AND marked_status=1
                                        AND class_id="'.$temp['class_id'].'" AND student_id="'.$temp['student_id'].'" GROUP BY subject_id ORDER BY weight_point DESC) AS subject_id LIMIT 1) ORDER BY a.weekly_report_no');
                                    ?>
                                    <tr style="font-weight:bold; background-color:#CCCCCC;">
                                        <th width="8">#</th>
                                        <th width="232">Subject</th>
                                        <?php
                                            for($k=0; $k<count($WPs); $k++)
                                                echo '<td>' . $this->Utility->formatPosition(($k+1)) . '  (' . intval($WPs[$k]['a']['weekly_weight_point']) . ')</td>';
                                        ?>
                                    </tr>
                                </thead>
                                <tbody>
                                    <?php $i=1; foreach ($Subjects as $Subject): ?>
                                        <tr style="background-color: #F2F0F0 !important;" style="font-weight:bold">
                                            <td><?php echo $i++;?></td>
                                            <td><?php echo h($Subject['subject_name']);?></td>
                                            <?php
                                                $MidTermScores = $WeeklyReportModel->query('SELECT a.* FROM weeklyreport_studentdetailsviews a WHERE a.academic_term_id="'.$Subject['academic_term_id'].'" AND a.marked_status=1
		                                        AND a.class_id="'.$Subject['class_id'].'" AND a.student_id="'.$Subject['student_id'].'" AND a.subject_id="'.$Subject['subject_id'].'" ORDER BY a.subject_name, a.weekly_report_no');
                                                $j=1;
                                                for ($h = 1; $h <= $marked_report; $h++) {
                                                    if(!empty($MidTermScores[$h-1])){
                                                        $TermScore = $MidTermScores[$h-1];
                                                        if($j < $TermScore['a']['weekly_report_no']){
                                                            $diff = $TermScore['a']['weekly_report_no'] - $j;
                                                            if($diff > 0) {
                                                                for ($m = 0; $m < $diff; $m++) {
                                                                    echo '<td><span class="label label-danger">nill</span></td>';
                                                                }
                                                            }
                                                            $j = $TermScore['a']['weekly_report_no'];
                                                        }
                                                        if($j == $TermScore['a']['weekly_report_no']) {
                                                            echo '<td>' . $TermScore['a']['weekly_ca'] . '</td>';
                                                            $j++;
                                                        }
                                                    }
                                                    elseif($j < $h + 1){
                                                        echo '<td><span class="label label-danger">nill</span></td>';
                                                    }
                                                }
                                            ?>
                                        </tr>
                                    <?php endforeach; ?>
                                </tbody>
                                <tfoot>
                                    <tr style="font-weight:bold; background-color:#CCCCCC;">
                                        <th width="8">#</th>
                                        <th width="232">Subject</th>
                                        <?php
                                            for($k=0; $k<count($WPs); $k++)
                                                echo '<td>' . $this->Utility->formatPosition(($k+1)) . '  (' . intval($WPs[$k]['a']['weekly_weight_point']) . ')</td>';
                                        ?>
                                    </tr>
                                </tfoot>
                            <?php else:?>
                                <tr>
                                    <th>No Record Found</th>
                                </tr>
                            <?php endif;?>
                        </table>
                        <h6 align="center" style="text-align: center">Powered by SmartEdu ™</h6>
                    </div>
                </div>
            </div>
        </div>
    </body>
</html>