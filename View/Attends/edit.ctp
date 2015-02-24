<?php echo $this->Html->script("../app/jquery/custom.attend.js", FALSE);?>
<div class="col-md-12">
    <div class="panel">
        <!-- Info Boxes -->
        <div class="row">
            <div class="col-md-12">
                <div class="info-box  bg-info  text-white">
                    <div class="info-icon bg-info-dark">
                        <i class="fa fa-edit fa-4x"></i>
                    </div>
                    <div class="info-details">
                        <h4>Modify Students Attendance </h4>
                    </div>
                </div>
            </div>
        </div>
        <!-- / Info Boxes -->
        <div class="panel-heading text-primary">
            <h3 class="panel-title">
               <i class="fa fa-edit"></i> Modify / Edit Students That are Present and Those Absent
                <span class="pull-right">
                    <a href="javascript:void(0)"  title="Refresh"><i class="fa fa-refresh"></i></a>
                    <a href="#" class="panel-minimize"><i class="fa fa-chevron-up"></i></a>
                    <a href="#" class="panel-close"><i class="fa fa-times"></i></a>
                </span>
            </h3>
        </div>
        <div class="row">
            <div class="col-md-10 col-md-offset-1">
                <div class="panel">
                    <div class="panel-body">
                        <div class="panel panel-info">
                            <div class="panel-heading panel-title  text-white">Students Attendance Form</div>
                            <?php 
                                //Creates The Form
                                echo $this->Form->create('AttendDetails', array(
                                        'class' => 'form-horizontal cascde-forms',
                                        'id' => 'attendance_edit_form'
                                    )
                                );     
                            ?>
                                <table class="table table-bordered table-hover table-striped">
                                    <tr>
                                        <th style="text-align: center" colspan="3">
                                            <label class="text-center">
                                                Class Room Attendance For <?php echo $Attend['Classroom']['class_name'].' '.$Attend['AcademicTerm']['academic_term'].' on '.$Attend['Attend']['attend_date'];?>
                                            </label>
                                        </th>
                                    </tr>
                                    <tr>
                                        <td><label>Marked Students Count || <span id="mark_span"></span></label></td>
                                        <td align="center">
                                            <div class="checkbox col-md-6 col-md-offset-3"><label class="label label-primary"><input id="check_all" type="checkbox">Check / Un-Check All</label></div>
                                        </td>
                                        <td><label>Unmarked Students Count || <span id="unmark_span"></span></label></td>
                                    </tr>
                                    <tr>
                                        <td align="center">
                                            <div id="AvailableLB">
                                                <?php if(!empty($Absents)): ?>
                                                    <?php foreach ($Absents as $Student):  ?>
                                                        <div class="checkbox">
                                                            <label>
                                                                <input class="check_student" type="checkbox" value="<?php echo $Student['a']['student_id'];?>">
                                                                <?php echo strtoupper($Student['a']['student_no']), ': ', $Student['a']['student_name'];?>
                                                            </label>
                                                        </div>
                                                    <?php endforeach; ?>
                                                <?php endif; ?>
                                            </div>
                                        </td> 
                                        <td align="center"><br><br><br><br><br><br>
                                            <div class="form-group aligncenter">
                                                <div class="col-md-8 col-md-offset-2">
                                                    <button type="submit" class="btn btn-sm btn-success">Submit Attendance</button>
                                                    <input type="hidden" name="data[AttendDetails][student_ids]" id="student_ids">
                                                </div>
                                            </div>
                                        </td> 
                                        <td align="center">
                                            <div id="LinkedLB">
                                                <?php if(!empty($Presents)): ?>
                                                    <?php foreach ($Presents as $Student):  ?>
                                                        <div class="checkbox">
                                                            <label>
                                                                <input class="check_student" type="checkbox" checked="checked" value="<?php echo $Student['a']['student_id'];?>">
                                                                <?php echo strtoupper($Student['a']['student_no']), ': ', $Student['a']['student_name'];?>
                                                            </label>
                                                        </div>
                                                    <?php endforeach; ?>
                                                <?php endif; ?>
                                            </div>
                                        </td>
                                    </tr>
                                </table>
                            </form>
                        </div>
                    </div>
                </div>
            </div> 
        </div>
    </div>
 </div> <!-- /col-md-12 -->
 <?php
    //on click of Manage Students link... activate the link
    echo $this->Js->buffer('
        setTabActive("[href=\"'.DOMAIN_NAME.'/attends/index#take_attend\"]", 0);
    ');
?> 
 