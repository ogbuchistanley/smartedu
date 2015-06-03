<?php echo $this->Html->script("../app/js/jquery-ui.js", FALSE);?>
<?php echo $this->Html->script("../app/jquery/custom.record.js", FALSE);?>
<?php //print_r($DetailSetups);?>
<?php $AcademicTerm = ClassRegistry::init('AcademicTerm'); ?>
<?php $WeeklyReportSetup = ClassRegistry::init('WeeklyReportSetup'); ?>
<?php $WeeklyDetailSetup = ClassRegistry::init('WeeklyDetailSetup'); ?>

    <div class="col-md-12">
        <div class="panel">
            <div class="panel-heading text-primary">
                <h3 class="panel-title">
                    <i class="fa fa-edit"></i>  Modify Existing Records
                    <span class="label label-primary">Weekly Report Details Setup</span>
                <span class="pull-right">
                    <a href="javascript:void(0)"  title="Refresh"><i class="fa fa-refresh"></i></a>
                    <a href="#" class="panel-minimize"><i class="fa fa-chevron-up"></i></a>
                    <a href="#" class="panel-close"><i class="fa fa-times"></i></a>
                </span>
                </h3>
            </div>
            <div class="row">
                <div class="col-md-12">
                    <div class="panel">
                        <div class="panel-body">
                            <div class="panel panel-info">
                                <div class="panel-heading panel-title  text-white">Weekly Report Details Setup Table</div>
                                <div style="overflow-x: scroll" class="panel-body">
                                    <?php
                                        //Creates The Form
                                        echo $this->Form->create('WeeklyDetailSetup', array(
                                                'class' => 'form-horizontal',
                                            )
                                        );
                                    ?>
                                        <table  class="table table-bordered table-hover table-striped display">
                                            <thead>
                                            <tr>
                                                <th>#</th>
                                                <th>Weight Point</th>
                                                <th>Report No.</th>
                                                <th>C.A Percentage</th>
                                                <th>Description</th>
                                                <th colspan="2">Submission Date</th>
                                            </tr>
                                            </thead>
                                            <tbody>
                                            <?php
                                                $first = $second = $number = 0;
                                                foreach ($Classgroups as $Classgroup):
                                                    $number++;
                                                    $option = array('conditions' => array(
                                                        'WeeklyReportSetup.classgroup_id' => $Classgroup['Classgroup']['classgroup_id']),
                                                        'WeeklyReportSetup.academic_term_id' => $AcademicTerm->getCurrentTermID()
                                                    );
                                                    $report = $WeeklyReportSetup->find('first', $option);

                                                    if(!empty($report)) :
                                                        $option2 = array('conditions' => array('WeeklyDetailSetup.weekly_report_setup_id' => $report['WeeklyReportSetup']['weekly_report_setup_id']));
                                                        $DetailSetups = $WeeklyDetailSetup->find('all', $option2);
                                                        $no = $report['WeeklyReportSetup']['weekly_report'];
                                                        $count = count($DetailSetups);
                                                        $diff = $no - $count;
                                                        if($number == 1) $first = $count;
                                                        if($number == 2) $second = $count;
                                            ?>
                                                        <tr>
                                                            <th colspan="4" style="text-align: center"><b><?php echo $Classgroup['Classgroup']['classgroup']; ?></b></th>
                                                            <th colspan="3" style="text-align: center"><b><?php echo $AcademicTerm->getCurrentTermName(); ?></b></th>
                                                        </tr>
                                                        <?php if(!empty($DetailSetups)): $i=1;
                                                            foreach($DetailSetups as $detail): ?>
                                                                <tr>
                                                                    <td><?php echo $i++; ?></td>
                                                                    <td>
                                                                        <select class="form-control form-cascade-control" name="data[WeeklyDetailSetup][weekly_weight_point][]" required="required"/>
                                                                        <option value="">  (Select W.P)  </option>
                                                                        <?php
                                                                        for($j=5; $j <= 100; $j+=5) {
                                                                            $temp = ($detail['WeeklyDetailSetup']['weekly_weight_point'] == $j) ? 'selected="selected"' : '';
                                                                            echo '<option '.$temp.' value="'.$j.'">'.$j.'</option>';
                                                                        }
                                                                        ?>
                                                                        </select>
                                                                        <?php //echo $report['WeeklyReportSetup']['weekly_weight_point']; ?>
                                                                    </td>
                                                                    <td>
                                                                        <input style="width: 100px;" class="form-control form-cascade-control" readonly type="text" name="data[WeeklyDetailSetup][weekly_report_no][]"
                                                                               value="<?php echo $detail['WeeklyDetailSetup']['weekly_report_no']; ?>">
                                                                    </td>
                                                                    <td>
                                                                        <select class="form-control form-cascade-control ca_percent" name="data[WeeklyDetailSetup][weekly_weight_percent][]" required="required"/>
                                                                        <option value="">  (Select C.A %)  </option>
                                                                        <?php
                                                                        for($j=5; $j <= 100; $j+=5) {
                                                                            $temp = ($detail['WeeklyDetailSetup']['weekly_weight_percent'] == $j) ? 'selected="selected"' : '';
                                                                            echo '<option '.$temp.'  value="'.$j.'">'.$j.' %</option>';
                                                                        }
                                                                        ?>
                                                                        </select>
                                                                    </td>
                                                                    <td>
                                                                                            <textarea class="form-control form-cascade-control input-medium" name="data[WeeklyDetailSetup][report_description][]" placeholder="Report Description"
                                                                                                      required><?php echo h($detail['WeeklyDetailSetup']['report_description']);?></textarea>
                                                                    </td>
                                                                    <td>
                                                                        <input style="width: 130px;" class="form-control form-cascade-control date_picker" name="data[WeeklyDetailSetup][submission_date][]"
                                                                               required value="<?php echo $this->Utility->formatDate($detail['WeeklyDetailSetup']['submission_date']);?>">
                                                                        <input type="hidden" name="data[WeeklyDetailSetup][weekly_report_setup_id][]"
                                                                               value="<?php echo h($detail['WeeklyDetailSetup']['weekly_report_setup_id']);?>">
                                                                        <input type="hidden" name="data[WeeklyDetailSetup][weekly_detail_setup_id][]"
                                                                               value="<?php echo h($detail['WeeklyDetailSetup']['weekly_detail_setup_id']);?>">
                                                                    </td>
                                                                    <td>
                                                                        <?php if($count == ($i - 1)): ?>
                                                                            <input type="checkbox" class="polaris-input delete_ids" value="<?php echo h($detail['WeeklyDetailSetup']['weekly_detail_setup_id']);?>">&nbsp;Delete
                                                                        <?php endif; ?>
                                                                    </td>
                                                                </tr>
                                                            <?php   endforeach;
                                                            if($diff > 0):
                                                                for($j=0; $j < $diff; $j++):
                                                                    if($number == 1) $first++;
                                                                    if($number == 2) $second ++;
                                                                ?>
                                                                    <tr>
                                                                        <td><?php echo $i + $j; ?></td>
                                                                        <td>
                                                                            <select class="form-control form-cascade-control" name="data[WeeklyDetailSetup][weekly_weight_point][]" required="required"/>
                                                                            <option value="">  (Select W.P)  </option>
                                                                            <?php for($k=5; $k <= 100; $k+=5): ?>
                                                                                <option value="<?php echo $k; ?>"><?php echo $k; ?></option>
                                                                            <?php endfor; ?>
                                                                            </select>
                                                                        </td>
                                                                        <td><input style="width: 100px;" class="form-control form-cascade-control" readonly type="text" name="data[WeeklyDetailSetup][weekly_report_no][]" value="<?php echo $i + $j; ?>"></td>
                                                                        <td>
                                                                            <select class="form-control form-cascade-control ca_percent" name="data[WeeklyDetailSetup][weekly_weight_percent][]" required="required"/>
                                                                            <option value="">  (Select C.A %)  </option>
                                                                            <?php for($k=5; $k <= 100; $k+=5): ?>
                                                                                <option value="<?php echo $k; ?>"><?php echo $k,' %'; ?></option>
                                                                            <?php endfor; ?>
                                                                            </select>
                                                                        </td>
                                                                        <td><textarea class="form-control form-cascade-control input-medium" name="data[WeeklyDetailSetup][report_description][]" placeholder="Report Description" required></textarea></td>
                                                                        <td><input style="width: 130px;" class="form-control form-cascade-control date_picker" required name="data[WeeklyDetailSetup][submission_date][]"></td>
                                                                        <td>
                                                                            <button type="button" class="btn btn-xs btn-danger remove_report_btn">Remove</button>
                                                                            <input type="hidden" name="data[WeeklyDetailSetup][weekly_report_setup_id][]" value="<?php echo $report['WeeklyReportSetup']['weekly_report_setup_id'];?>">
                                                                            <input type="hidden" name="data[WeeklyDetailSetup][weekly_detail_setup_id][]">
                                                                        </td>
                                                                    </tr>
                                                                <?php endfor;
                                                            endif;
                                                        else:
                                                            for($i=1; $i <= $no; $i++):
                                                                if($number == 1) $first++;
                                                                if($number == 2) $second++;
                                                            ?>
                                                                <tr>
                                                                    <td><?php echo $i; ?></td>
                                                                    <td>
                                                                        <select class="form-control form-cascade-control" name="data[WeeklyDetailSetup][weekly_weight_point][]" required="required"/>
                                                                        <option value="">  (Select W.P)  </option>
                                                                        <?php for($j=5; $j <= 100; $j+=5): ?>
                                                                            <option value="<?php echo $j; ?>"><?php echo $j; ?></option>
                                                                        <?php endfor; ?>
                                                                        </select>
                                                                    </td>
                                                                    <td><input style="width: 100px;" class="form-control form-cascade-control" readonly type="text" name="data[WeeklyDetailSetup][weekly_report_no][]" value="<?php echo $i; ?>"></td>
                                                                    <td>
                                                                        <select class="form-control form-cascade-control ca_percent" name="data[WeeklyDetailSetup][weekly_weight_percent][]" required="required"/>
                                                                        <option value="">  (Select C.A %)  </option>
                                                                        <?php for($k=5; $k <= 100; $k+=5): ?>
                                                                            <option value="<?php echo $k; ?>"><?php echo $k,' %'; ?></option>
                                                                        <?php endfor; ?>
                                                                        </select>

                                                                    </td>
                                                                    <td><textarea class="form-control form-cascade-control input-medium" name="data[WeeklyDetailSetup][report_description][]" placeholder="Report Description" required></textarea></td>
                                                                    <td><input style="width: 130px;" class="form-control form-cascade-control date_picker" required name="data[WeeklyDetailSetup][submission_date][]"></td>
                                                                    <td>
                                                                        <button type="button" class="btn btn-xs btn-danger remove_report_btn">Remove</button>
                                                                        <input type="hidden" name="data[WeeklyDetailSetup][weekly_report_setup_id][]" value="<?php echo $report['WeeklyReportSetup']['weekly_report_setup_id'];?>">
                                                                        <input type="hidden" name="data[WeeklyDetailSetup][weekly_detail_setup_id][]">
                                                                    </td>
                                                                </tr>
                                                            <?php endfor; ?>
                                                        <?php endif; ?>
                                                    <?php endif; ?>
                                                <?php endforeach; ?>
                                            </tbody>
                                            <tfoot>
                                            <tr>
                                                <th>#</th>
                                                <th>Weight Point</th>
                                                <th>Report No.</th>
                                                <th>C.A Percentage</th>
                                                <th>Description</th>
                                                <th colspan="2">Submission Date</th>
                                            </tr>
                                            </tfoot>
                                        </table>
                                        <div class="form-group">
                                            <div class="col-sm-offset-2 col-sm-10">
                                                <input type="hidden" name="data[WeeklyDetailSetup][deleted_term]" id="deleted_term">
                                                <button type="submit" id="save_weekly_detail_btn" value="<?php echo $first,'_',$second;?>" class="btn btn-info">Save Records</button><span></span>
                                            </div>
                                        </div>
                                    </form>
                                </div>
                            </div>
                        </div> <!-- /panel body -->
                    </div> <!-- /panel -->
                </div>
            </div>
        </div>

    </div> <!-- /col-md-12 -->
<?php
//on click of Manage Sponsors Record link... activate the link
echo $this->Js->buffer('
        setTabActive("[href=\"'.DOMAIN_NAME.'/records/weeklyrep_detail\"]", 1);
    ');