<!-- Page Scripts =============================-->
<?php echo $this->Html->script("../app/js/bootstrap-datatables.js", FALSE);?>
<?php echo $this->Html->script("../app/js/dataTables-custom.js", FALSE);?>

<?php $term_id = ClassRegistry::init('AcademicTerm'); ?>
<?php $AssessmentModel = ClassRegistry::init('Assessment'); ?>

<div class="col-md-12">
    <div class="panel">
        <!-- Info Boxes -->
        <!--div class="row">
            <div class="col-md-12">
                <div class="info-box  bg-info  text-white">
                    <div class="info-icon bg-info-dark">
                        <i class="fa fa-group fa-4x"></i>
                    </div>
                    <div class="info-details">
                        <h4>List of  Students Assigned To The Class</h4>
                    </div>
                </div>
            </div>
        </div>
        <!-- / Info Boxes -->
        <div class="panel-heading text-primary">
            <h3 class="panel-title">
                <i class="fa fa-male"></i>
                Students Assigned
                <span class="pull-right">
                    <a href="javascript:void(0)"  title="Refresh"><i class="fa fa-refresh"></i></a>
                    <a href="#" class="panel-minimize"><i class="fa fa-chevron-up"></i></a>
                    <a href="#" class="panel-close"><i class="fa fa-times"></i></a>
                </span>
            </h3>
        </div>
        <div class="col-md-12">
            <div class="panel-body">
                <div class="panel panel-info">
                    <div class="panel-heading panel-title  text-white">Table Displaying List of Students in <?php echo $term_id->getCurrentTermName();?></div>
                    <div style="overflow-x: scroll" class="panel-body">
                        <?php
                            //Creates The Form
                            echo $this->Form->create('Remark', array(
                                    //'action' => 'saveRemark',
                                    'class' => 'form-horizontal',
                                )
                            );
                        ?>
                            <?php if(!empty($Students['StudentsClass'])):?>
                                <table  class="table table-bordered table-hover table-striped display">
                                    <thead>
                                    <tr>
                                        <th>#</th>
                                        <th>No.</th>
                                        <th>Full Name</th>
                                        <th>Gender</th>
                                        <th>Class</th>
                                        <th>Principal Remark</th>
                                        <th>House Master Remark</th>
                                    </tr>
                                    </thead>
                                    <tbody>
                                    <?php $i=1; foreach ($Students['StudentsClass'] as $Student): ?>
                                        <?php
                                        $option = array('conditions' => array('Assessment.student_id' => $Student['student_id'], 'Assessment.academic_term_id' => $term_id->getCurrentTermID()));
                                        $assess = $AssessmentModel->find('first', $option);
                                        ?>
                                        <tr class="gradeA">
                                            <td><?php echo $i++; ?></td>
                                            <td><?php echo h($Student['student_no']); ?>&nbsp;</td>
                                            <td><?php echo h($Student['first_name']), ' ', h($Student['surname']), ' ', h($Student['other_name']); ?>&nbsp;</td>
                                            <td><?php echo h($Student['gender']); ?>&nbsp;</td>
                                            <td><?php echo h($Student['class_name']); ?>&nbsp;</td>
                                            <td>
                                                <input type="hidden" name="data[Remark][remark_id][]" value="<?php echo h($Student['remark_id']);?>">
                                                <input type="hidden" name="data[Remark][student_id][]" id="student_d" value="<?php echo  h($Student['student_id']); ?>">
                                                <textarea class="form-control form-cascade-control input-small" name="data[Remark][principal_remark][]"
                                                  id="remark" placeholder="Student's Exam Remark" required><?php echo  h($Student['principal_remark']); ?></textarea>
                                            </td>
                                            <td>
                                                <textarea class="form-control form-cascade-control input-small" name="data[Remark][house_master_remark][]"
                                                  id="remark" placeholder="Student's Exam Remark" required><?php echo  h($Student['house_master_remark']); ?></textarea>
                                            </td>
                                        </tr>
                                    <?php endforeach; ?>
                                    </tbody>
                                    <tfoot>
                                    <tr>
                                        <th>#</th>
                                        <th>No.</th>
                                        <th>Full Name</th>
                                        <th>Gender</th>
                                        <th>Class</th>
                                        <th>Principal Remark</th>
                                        <th>House Master Remark</th>
                                    </tr>
                                    </tfoot>
                                </table><br>
                                <div class="form-group">
                                    <div class="col-sm-offset-2 col-sm-10">
                                        <button type="submit" class="btn btn-success">Submit</button><span></span>
                                    </div>
                                </div>
                            <?php else :?>
                                <tr><th>No Student Has Been Assign To The Class Yet</th></tr>
                            <?php endif;?>
                        </form>
                    </div> <!-- /panel body -->
                </div>
            </div> <!-- /panel body -->
        </div>
    </div>
</div>
<?php
//on click of Manage Students link... activate the link
echo $this->Js->buffer('
        setTabActive("[href=\"'.DOMAIN_NAME.'/classrooms/myclass\"]", 1);
    ');
?> 
 