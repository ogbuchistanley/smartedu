<?php echo $this->Html->script("../app/js/bootstrap-datatables.js", FALSE);?>
<?php echo $this->Html->script("../app/js/dataTables-custom.js", FALSE);?>
<?php echo $this->Html->script("../app/jquery/custom.subject.js", FALSE);?>
<?php //print_r($AnalysisScore);?>
<div class="col-md-12">
    <div class="panel">
        <!-- Info Boxes -->
        <!--div class="row">
            <div class="col-md-12">
                <div class="info-box  bg-info  text-white">
                    <div class="info-icon bg-info-dark">
                        <i class="fa fa-book fa-4x"></i>
                    </div>
                    <div class="info-details">
                        <h4>View Students Terminal Subjects Scores (CA's and Exams) </h4>
                    </div>
                </div>
            </div>
        </div>
        <!-- / Info Boxes -->
        <div class="panel-heading text-primary">
            <h3 class="panel-title">
               <i class="fa fa-bookmark-o"></i> View Student Terminal Exam Subjects Scores (CA's and Exams)
                <span class="pull-right">
                    <a href="#"  title="Print"><i class="fa fa-print"></i></a>
                    <a href="#" class="panel-minimize"><i class="fa fa-chevron-up"></i></a>
                    <a href="#" class="panel-close"><i class="fa fa-times"></i></a>
                </span>
            </h3>
        </div>        
        <div class="row">
            <!-- Panel with Tables -->
            <div class="col-md-5">
                <div class="panel">
                    <div class="panel-body">
                        <div class="panel panel-primary">
                        <div class="panel-heading panel-title  text-white">
                            Student Subject Information
                        </div>
                            <table class="table table-bordered table-hover table-striped">
                                <?php if($StudentScore['a']): ?>
                                    <tr>
                                        <th>Student Full Name</th>
                                        <td>
                                            <?php echo h($StudentScore['a']['student_fullname']); ?>
                                        </td>
                                    </tr>
                                    <tr>
                                        <th>Class Room</th>
                                        <td><?php echo $StudentScore['a']['class_name'];?></td>
                                    </tr>
                                    <tr>
                                        <th>Academic Term</th>
                                        <td><?php echo $StudentScore['a']['academic_term'];?></td>
                                    </tr>
                                    <tr>
                                        <th>Subject</th>
                                        <td><?php echo $StudentScore['a']['subject_name'];?></td>
                                    </tr>
                                    <tr>
                                        <th>1st C.A / (W.A)</th>
                                        <td><?php echo $StudentScore['a']['ca1'];?> / <?php echo $StudentScore['a']['weightageCA1'];?></td>
                                    </tr>
                                    <tr>
                                        <th>2nd C.A / (W.A)</th>
                                        <td><?php echo $StudentScore['a']['ca2'];?> / <?php echo $StudentScore['a']['weightageCA2'];?></td>
                                    </tr>
                                    <tr>
                                        <th>Exam / (W.A)</th>
                                        <td><?php echo $StudentScore['a']['exam'];?> / <?php echo $StudentScore['a']['weightageExam'];?></td>
                                    </tr>
                                    <tr>
                                        <th>Total / (W.A)</th>
                                        <td><?php echo $StudentScore[0]['sum_total'], ' / ', $StudentScore[0]['wa_total']; ?></td>
                                    </tr>
                                    <tr>
                                        <th>Total (100%) </th>
                                        <td><?php echo number_format(($StudentScore[0]['sum_total'] * 100) / $StudentScore[0]['wa_total'], 2); ?></td>
                                    </tr>
                                <?php else:?>
                                    <tr>
                                        <th>No Record Found</th>
                                    </tr>
                                <?php endif;?>
                            </table>
                        </div>
                    </div>
                </div>
            </div><!-- /Panel with Tables -->
            <!-- Panel with Tables -->
            <div class="col-md-4 col-md-offset-1">
                <div class="panel">
                    <div class="panel-body">
                        <div class="panel panel-primary">
                            <div class="panel-heading panel-title  text-white">
                                Subject Analysis
                            </div>
                            <table class="table table-bordered table-hover table-striped">
                                <?php if($AnalysisScore[0]): ?>
                                    <tr>
                                        <th>Position</th>
                                        <td>
                                            <?php
                                                $pos = $AnalysisScore['Position'];
                                                if ($pos === '1') {
                                                    echo '<span class="label label-success" style="font-size: medium">'.$this->Utility->formatPosition($pos).'</span>';
                                                }else if ($pos === '2') {
                                                    echo '<span class="label label-info" style="font-size: medium">'.$this->Utility->formatPosition($pos).'</span>';
                                                }else if ($pos=== '3') {
                                                    echo '<span class="label label-warning" style="font-size: medium">'.$this->Utility->formatPosition($pos).'</span>';
                                                }else if ($pos === $AnalysisScore[0]['count_total']) {
                                                    echo '<span class="label label-danger" style="font-size: medium">'.$this->Utility->formatPosition($pos).'</span>';
                                                }else{
                                                    echo $this->Utility->formatPosition($pos);
                                                }
                                            ?>
                                        </td>
                                    </tr>
                                    <tr>
                                        <th>Out Of</th>
                                        <td><?php echo $AnalysisScore[0]['count_total'];?></td>
                                    </tr>
                                    <tr>
                                        <th>Grade</th>
                                        <td><?php echo $StudentScore['b']['grade_abbr'];?></td>
                                    </tr>
                                    <tr>
                                        <th>Highest Score</th>
                                        <td><?php echo number_format($AnalysisScore[0]['max_total'], 2);?></td>
                                    </tr>
                                    <tr>
                                        <th>Lowest Score</th>
                                        <td><?php echo number_format($AnalysisScore[0]['min_total'], 2);?></td>
                                    </tr>
                                    <tr>
                                        <th>Class Average</th>
                                        <td><?php echo number_format($AnalysisScore[0]['avg_total'], 2);?></td>
                                    </tr>
                                <?php else:?>
                                    <tr>
                                        <th>No Record Found</th>
                                    </tr>
                                <?php endif;?>
                            </table>
                        </div>
                    </div>
                </div>
            </div><!-- /Panel with Tables -->
        </div>
    </div>
 </div> <!-- /col-md-12 -->
 <?php
    //on click of Manage Students link... activate the link
    echo $this->Js->buffer('
        setTabActive("[href=\"'.DOMAIN_NAME.'/subjects/index\"]", 0);
    ');
?> 
 