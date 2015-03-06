<?php $TermModel = ClassRegistry::init('AcademicTerm'); ?>
<!DOCTYPE html>
<html lang="en">
<head>
    <head>
        <title>Student Terminal Result Sheet</title>
        <link href="<?php echo APP_DIR_ROOT; ?>css/bootstrap.css" rel="stylesheet">
        <link href="<?php echo APP_DIR_ROOT; ?>css/style.css" rel="stylesheet" type="text/css">
        <link href="<?php echo APP_DIR_ROOT; ?>images/icon.png" rel="shortcut icon">
        <link href="<?php echo APP_DIR_ROOT; ?>css/print.css" rel="stylesheet" media="print">
        <style type="text/css">
            * { margin: 0; padding: 0; }
            html, body {
                /*changing width to 100% causes huge overflow and wrap*/
                height:auto;
                background: #FFF;
                display: block;
                position:absolute;
                width: 100%; margin: 0; float: none;
                font-family: Verdana;
                font-size: 9pt;
                color: #000000;
                text-align: center;
            }
            img {
                  display:block;
                  page-break-after: avoid;
                  page-break-inside: avoid;
            }
            a {
                font-size: 8pt;
                text-decoration: none;
            }
        </style>
    </head>
    <body>
        <div class="col-md-10 col-md-offset-1">
            <div>
                <div>
                    <img src="<?php echo APP_DIR_ROOT; ?>images/bells_logo.png" alt="School Logo"/>
                </div>
                <div style="font-size:36px; color:#666">THE BELLS</div>
                <div>
                    Comprehensive Secondary School for Boys and Girls<br />
                    Ota, Ogun State<br />
                    MOTTO: Learn &nbsp; . &nbsp; Live &nbsp; . &nbsp; Lead <br />
                    <a href="http://www.thebellsschools.org">http://www.thebellsschools.org</a><br>
                    <strong><?php echo $TermModel->getCurrentTermName(), ' ACADEMIC SESSION REPORT' ;?></strong>
                </div>
            </div>
            <div class="row"><br><br>
                <div class="col-md-6 pull-left">
                    <table class="table table-bordered table-striped" style="font-size: 8pt;">
                        <caption style="font-weight: bolder">Student Information</caption>
                        <?php if($ClassPosition['ClassPositions']): ?>
                            <tr>
                                <th>Full Name</th>
                                <td><?php echo h($ClassPosition['ClassPositions']['full_name']);?></td>
                                <th>Class</th>
                                <td><?php echo $ClassPosition['ClassPositions']['class_name'];?></td>
                                <th>Average</th>
                                <td><?php echo number_format($TermScores['Average'], 2);?></td>
                            </tr>
                            <tr>
                                <th>Position:</th>
                                <td><?php echo $ClassPosition['ClassPositions']['class_position'];?></td>
                                <th>Out of:</th>
                                <td><?php echo $ClassPosition['ClassPositions']['clas_size'];?></td>
                                <th>Total Score</th>
                                <td><?php echo $ClassPosition['ClassPositions']['student_sum_total'];?></td>
                            </tr>
                        <?php else:?>
                            <tr>
                                <th>No Record Found</th>
                            </tr>
                        <?php endif;?>
                    </table>
                </div>
                <div class="col-md-3 pull-right">
                    <table class="table table-bordered table-striped" style="width: 200px;">
                        <?php if(!empty($SkillsAssess)): ?>
                            <thead>
                            <tr>
                                <th>Skills</th>
                                <th>5</th>
                                <th>4</th>
                                <th>3</th>
                                <th>2</th>
                                <th>1</th>
                            </tr>
                            </thead>
                            <tbody style="font-size: 8pt; text-align: left;">
                            <?php foreach($SkillsAssess as $skill):?>
                                <tr>
                                    <td style="word-wrap: break-word"><?php echo $skill['Skill']['skill']?>:</td>
                                    <?php echo ($skill['SkillAssessment']['option'] == 5) ? '<td><span class="badge bg-primary-dark">5</span></td>' : '<td></td>'; ?>
                                    <?php echo ($skill['SkillAssessment']['option'] == 4) ? '<td><span class="badge bg-primary-dark">4</span></td>' : '<td></td>'; ?>
                                    <?php echo ($skill['SkillAssessment']['option'] == 3) ? '<td><span class="badge bg-primary-dark">3</span></td>' : '<td></td>'; ?>
                                    <?php echo ($skill['SkillAssessment']['option'] == 2) ? '<td><span class="badge bg-primary-dark">2</span></td>' : '<td></td>'; ?>
                                    <?php echo ($skill['SkillAssessment']['option'] == 1) ? '<td><span class="badge bg-primary-dark">1</span></td>' : '<td></td>'; ?>
                                </tr>
                            <?php endforeach; ?>
                            </tbody>
                        <?php else:?>
                            <tr>
                                <th>Assessment Has Not Been Carried Out</th>
                            </tr>
                        <?php endif;?>
                    </table>
                </div>
                <div class="col-md-8 pull-left">
                    <table  class="table table-bordered table-striped display" style="width: 800px;">
                        <caption style="font-weight: bolder">Subject Continuous Assessment (C.A) / Weightage Points (W.A)</caption>
                        <?php if(!empty($TermScores['Scores'])):?>
                            <thead>
                            <tr>
                                <th>#</th>
                                <th>Subject</th>
                                <th>1st C.A</th>
                                <th>2nd C.A</th>
                                <th>Exam</th>
                                <th>Total</th>
                                <th>Total (100%)</th>
                                <th>Grade</th>
                                <th>Remark</th>
                            </tr>
                            </thead>
                            <tbody style="font-size: 8pt;">
                            <?php $i=1; foreach ($TermScores['Scores'] as $TermScore): ?>
                                <tr class="gradeA">
                                    <td><?php echo $i++;?></td>
                                    <td><?php echo h($TermScore['subject_name']);?></td>
                                    <td><?php echo h($TermScore['ca1']), ' / ', h($TermScore['weightageCA1']);?></td>
                                    <td><?php echo h($TermScore['ca2']), ' / ', h($TermScore['weightageCA2']);?></td>
                                    <td><?php echo h($TermScore['exam']), ' / ', h($TermScore['weightageExam']);?></td>
                                    <td><?php echo h($TermScore['studentSubjectTotal']), ' / ', h($TermScore['weightageTotal']);?></td>
                                    <td><?php echo h($TermScore['studentPercentTotal']);?></td>
                                    <td><?php echo h($TermScore['grade_abbr']);?></td>
                                    <td><?php echo h($TermScore['grade']);?></td>
                                </tr>
                            <?php endforeach; ?>
                            </tbody>
                            <tfoot>
                            <tr>
                                <th>#</th>
                                <th>Subject</th>
                                <th>1st C.A</th>
                                <th>2nd C.A</th>
                                <th>Exam</th>
                                <th>Total</th>
                                <th>Total (100%)</th>
                                <th>Grade</th>
                                <th>Remark</th>
                            </tr>
                            </tfoot>
                        <?php else:?>
                            <tr>
                                <th>No Record Found</th>
                            </tr>
                        <?php endif;?>
                    </table>
                </div>
            </div>
        </div>
    </body>
</html>