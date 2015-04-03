<?php $TermModel = ClassRegistry::init('AcademicTerm'); ?>
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
                top:55px;
                width:750px;
                z-index:1;
                text-align: center;
            }
            #apDiv2 {
                position:absolute;
                left:779px;
                top:10px;
                width:300px;
                z-index:2;
            }

            #apDi1 {
                position:absolute;
                left:0px;
                top:13px;
                width:650px;
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
                    <h5><strong><?php echo $TermModel->getCurrentTermName(), ' ACADEMIC SESSION REPORT' ;?></strong></h5>
                </div>
            </div>
            <div style="position:relative; width:100%">
                <div  style="position:relative">
                    <div id="apDi1">
                        <table class="table table-bordered" width="800">
                            <caption style="font-weight: bolder">Student's Information</caption>
                            <?php if($ClassPosition['ClassPositions']): ?>
                                <tr>
                                    <th width="200" style="background-color: #F2F0F0 !important;">Full Name: </th>
                                    <td width="200"><?php echo h($ClassPosition['ClassPositions']['full_name']);?></td>
                                    <th width="100" style="background-color: #F2F0F0 !important;">Position: </th>
                                    <td width="100"><?php echo $this->Utility->formatPosition($ClassPosition['ClassPositions']['class_position']);?></td>
                                    <th width="100" style="background-color: #F2F0F0 !important;">Total: </th>
                                    <td width="100"><?php echo $ClassPosition['ClassPositions']['student_sum_total'];?></td>
                                </tr>
                                <tr>
                                    <th width="200" style="background-color: #F2F0F0 !important;">Class Name: </th>
                                    <td width="200"><?php echo $ClassPosition['ClassPositions']['class_name'];?></td>
                                    <th width="100" style="background-color: #F2F0F0 !important;">Out of: </th>
                                    <td width="100"><?php echo $ClassPosition['ClassPositions']['clas_size'];?></td>
                                    <th width="100" style="background-color: #F2F0F0 !important;">Average: </th>
                                    <td width="100"><?php echo number_format($TermScores['Average'], 2);?></td>
                                </tr>
                            <?php else:?>
                                <tr>
                                    <th>No Record Found</th>
                                </tr>
                            <?php endif;?>
                        </table>
                    </div>
                    <div id="apDiv1">
                        <table class="table table-bordered" width="750" style="margin-top: 65px;">
                            <caption style="font-weight: bolder">Subject Continuous Assessment (C.A) / Weightage Points (W.A)</caption>
                            <?php if(!empty($TermScores['Scores'])):?>
                                <thead>
                                    <tr style="font-weight:bold; background-color:#CCCCCC;">
                                        <th width="10"></th>
                                        <th width="150"></th>
                                        <th width="300" colspan="3" style="text-align: center">Assessment Scores</th>
                                        <th width="200" colspan="2" style="text-align: center">Total</th>
                                        <th width="200" colspan="2" style="text-align: center">Grade/Remark</th>
                                    </tr>
                                    <tr style="font-weight:bold; background-color:#CCCCCC;">
                                        <th width="10">#</th>
                                        <th width="150">Subject</th>
                                        <th width="100">1st C.A</th>
                                        <th width="100">2nd C.A</th>
                                        <th width="100">Exam</th>
                                        <th width="100">Score</th>
                                        <th width="100">(100%)</th>
                                        <th width="50">Grade</th>
                                        <th width="150">Remark</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <?php $i=1; foreach ($TermScores['Scores'] as $TermScore): ?>
                                        <tr style="background-color: #F2F0F0 !important;" style="font-weight:bold">
                                            <td><?php echo $i++;?></td>
                                            <td><?php echo h($TermScore['subject_name']);?></td>
                                            <td><?php echo h($TermScore['ca1']), ' / ', h($TermScore['weightageCA1']);?></td>
                                            <td><?php echo h($TermScore['ca2']), ' / ', h($TermScore['weightageCA2']);?></td>
                                            <td><?php echo h($TermScore['exam']), ' / ', h($TermScore['weightageExam']);?></td>
                                            <td><?php echo intval(h($TermScore['studentSubjectTotal'])), ' / ', intval(h($TermScore['weightageTotal']));?></td>
                                            <td><?php echo h($TermScore['studentPercentTotal']);?></td>
                                            <td><?php echo h($TermScore['grade_abbr']);?></td>
                                            <td><?php echo h($TermScore['grade']);?></td>
                                        </tr>
                                    <?php endforeach; ?>
                                </tbody>
                                <tfoot>
                                    <tr style="font-weight:bold; background-color:#CCCCCC;">
                                        <th width="10">#</th>
                                        <th width="150">Subject</th>
                                        <th width="100">1st C.A</th>
                                        <th width="100">2nd C.A</th>
                                        <th width="100">Exam</th>
                                        <th width="100">Score</th>
                                        <th width="100">(100%)</th>
                                        <th width="50">Grade</th>
                                        <th width="150">Remark</th>
                                    </tr>
                                </tfoot>
                            <?php else:?>
                                <tr>
                                    <th>No Record Found</th>
                                </tr>
                            <?php endif;?>
                        </table>
                        <table class="table table-bordered">
                            <tr >
                                <td width="370">
                                    <div >
                                        <div>
                                            <b>Class teacher's remarks: </b>
                                            <?php echo ($Remark['Remark']['class_teacher_remark']) ? $Remark['Remark']['class_teacher_remark'] : 'None' ?>
                                        </div>
                                        <div ><strong>Name: <?php echo ($Remark) ? h($Remark['Employee']['full_name']) : '';?> </strong> </div>
                                    </div>
                                </td>
                                <td>
                                    <div >
                                        <div >
                                            <b>House master/house mistress remarks: </b>
                                            <?php echo ($Remark['Remark']['house_master_remark']) ? $Remark['Remark']['house_master_remark'] : 'None' ?>
                                        </div>
                                        <div ><strong>By House Master/Mistress </strong></div>
                                    </div>
                                </td>
                            </tr>
                            <tr >
                                <td colspan="2">
                                    <div >
                                        <div >
                                            <b>Principal's remarks:</b>
                                            <?php echo ($Remark['Remark']['principal_remark']) ? $Remark['Remark']['principal_remark'] : 'None' ?>
                                        </div><br />
                                        <div><b>Name:  </b></div>
                                    </div>
                                </td>
                            </tr>
                        </table>
                        <h6 align="center" style="text-align: center">Powered by SmartEdu ™</h6>
                    </div>
                    <div id="apDiv2">
                        <?php $term = $TermModel->getNextTerm(); if($term): ?>
                            <table class="table table-bordered" style="margin-top: 20px;">
                                <tr>
                                    <th style="background-color: #F2F0F0 !important;"  width="150">Next Term Begins: </th>
                                    <td><?php echo $this->Utility->SQLDateToPHP($term['AcademicTerm']['term_begins']);?></td>
                                </tr>
                                <tr>
                                    <th style="background-color: #F2F0F0 !important;"  width="150">Next Term Ends: </th>
                                    <td><?php echo $this->Utility->SQLDateToPHP($term['AcademicTerm']['term_ends']);?></td>
                                </tr>
                            </table>
                        <?php endif;?>
                        <table class="table table-bordered" style="margin-top: 34px;">
                            <?php if(!empty($SkillsAssess)): ?>
                                <thead>
                                    <tr style="font-weight:bold; background-color:#CCCCCC; !important;">
                                        <th width="133">Skills</th>
                                        <th width="21">5</th>
                                        <th width="18">4</th>
                                        <th width="20">3</th>
                                        <th width="20">2</th>
                                        <th width="24">1</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <?php foreach($SkillsAssess as $skill):?>
                                        <tr>
                                            <td style="background-color: #F2F0F0 !important; font-size: 13px;"><?php echo $skill['Skill']['skill']?>:</td>
                                            <?php echo ($skill['SkillAssessment']['option'] == 5) ? '<td style="background-color:#333 !important;">5</td>' : '<td></td>'; ?>
                                            <?php echo ($skill['SkillAssessment']['option'] == 4) ? '<td style="background-color:#333 !important;">4</td>' : '<td></td>'; ?>
                                            <?php echo ($skill['SkillAssessment']['option'] == 3) ? '<td style="background-color:#333 !important;">3</td>' : '<td></td>'; ?>
                                            <?php echo ($skill['SkillAssessment']['option'] == 2) ? '<td style="background-color:#333 !important;">2</td>' : '<td></td>'; ?>
                                            <?php echo ($skill['SkillAssessment']['option'] == 1) ? '<td style="background-color:#333 !important;">1</td>' : '<td></td>'; ?>
                                        </tr>
                                    <?php endforeach; ?>
                                    <tr>
                                        <td colspan="6"><br />
                                            <div style="font-weight:bold; !important;">
                                                <strong>Keys to Ratings</strong>
                                            </div>
                                            <div style="font-size: 9px;">
                                                <ol>
                                                    <li>HAS NO REGARD FOR OBSERVABLE TRAITS</li>
                                                    <li>SHOWS MINIMAL REGARD FOR OBSERVABLE TRAITS</li>
                                                    <li>ACCEPTABLE LEVEL OF OBSERVABLE TRAITS</li>
                                                    <li>MAINTAINS HIGH LEVEL OF OBSERVABLE TRAITS</li>
                                                    <li>MAINTAINS AN EXCELLENT DEGREE OF OBSERVABLE TRAITS</li>
                                                </ol>
                                            </div>
                                        </td>
                                    </tr>
                                </tbody>
                            <?php else:?>
                                <tr>
                                    <th>Assessment Has Not Been Carried Out</th>
                                </tr>
                            <?php endif;?>
                        </table>
                        <table class="table table-bordered">
                            <?php if(!empty($Grades)):?>
                                <tr>
                                    <th>GRADE</th>
                                    <th>SCORES</th>
                                    <th>REMARKS</th>
                                </tr>
                                <?php foreach ($Grades as $grade): ?>
                                    <tr>
                                        <th><?php echo h($grade['a']['grade_abbr']);?></th>
                                        <th><?php echo h($grade['a']['lower_bound']), '-', h($grade['a']['upper_bound']);?></th>
                                        <th><?php echo h($grade['a']['grade']);?></th>
                                    </tr>
                                <?php endforeach; ?>
                            <?php else:?>
                                <tr>
                                    <th>No Grading System Has Not Been Set</th>
                                </tr>
                            <?php endif;?>
                        </table>
                    </div>
                    <br clear="all" />
                </div>
            </div>
        </div>
    </body>
</html>