<?php echo $this->Html->script("../app/js/bootstrap-datatables.js", FALSE);?>
<?php echo $this->Html->script("../app/js/dataTables-custom.js", FALSE);?>
<?php echo $this->Html->script("../app/jquery/custom.record.js", FALSE);?>

<?php $term_id = ClassRegistry::init('AcademicTerm'); ?>

<div class="col-md-12">
    <div class="panel">
        <!-- Info Boxes -->
        <!--div class="row">
            <div class="col-md-12">
                <div class="info-box  bg-info  text-white">
                    <div class="info-icon bg-info-dark">
                        <i class="fa fa-4x fa-group"></i>
                    </div>
                    <div class="info-details">
                        <h4>Class Room Master Record</h4>
                    </div>
                </div>
            </div>
        </div>
        <!-- / Info Boxes -->
        <div class="panel-heading text-primary">
            <h3 class="panel-title">
               <i class="fa fa-plus"></i> Add New / <i class="fa fa-edit"></i>  Modify Existing Records
                <span class="label label-primary">Weekly Report Record</span>
                <span class="pull-right">
                    <a href="javascript:void(0)"  title="Refresh"><i class="fa fa-refresh"></i></a>
                    <a href="#" class="panel-minimize"><i class="fa fa-chevron-up"></i></a>
                    <a href="#" class="panel-close"><i class="fa fa-times"></i></a>
                </span>
            </h3>
        </div>
        <div class="panel-body">
            <div class="panel panel-default">
                <div class="panel-body">
                    <div class="row">
                        <div class="col-md-6">
                            <div class="panel panel-cascade">
                                <div class="panel-body">
                                    <div class="panel panel-default">
                                        <div class="panel-heading"><i class="fa fa-search fa-1x"></i> Search Form For Easier Filter </div>                                            
                                        <div class="panel-body">
                                            <?php 
                                                //Creates The Form
                                                echo $this->Form->create('SearchWeeklyReport', array(
                                                        'class' => 'form-horizontal'
                                                    )
                                                );     
                                            ?>
                                                <div class="form-group">
                                                    <label for="academic_year_search_id" class="col-sm-4 control-label">Academic Years</label>
                                                    <div class="col-sm-8">
                                                        <?php
                                                            echo $this->Form->input('academic_year_search_id', array(
                                                                    'div' => false,
                                                                    'label' => false,
                                                                    'class' => 'form-control',
                                                                    'id' => 'academic_year_search_id',
                                                                    'required' => "required",
                                                                    'selected' => $term_id->getCurrentYearID(),
                                                                    'options' => $AcademicYears,
                                                                    'empty' => '(Select Academic Year)'
                                                                )
                                                            );
                                                        ?>
                                                    </div>
                                                </div>
                                                <div class="form-group">
                                                    <label for="academic_term_search_id" class="col-sm-4 control-label">Academic Terms</label>
                                                    <div class="col-sm-8">
                                                        <select class="form-control" name="data[SearchWeeklyReport][academic_term_search_id]" id="academic_term_search_id" required="required">
                                                            <option value="<?php echo $term_id->getCurrentTermID();?>"><?php echo $term_id->getCurrentTermName();?></option>

                                                        </select>
                                                    </div>
                                                </div>
                                                <div class="form-group">
                                                    <div class="col-sm-offset-2 col-sm-10">
                                                        <button type="submit" class="btn btn-info">Search</button>
                                                    </div>
                                                </div>
                                            </form>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="row">
                        <div class="col-md-11">
                           <div class="panel">
                                <div class="panel-body">
                                    <div class="panel panel-info">
                                        <div class="panel-heading panel-title  text-white">Class Rooms Record Table</div>
                                        <div style="overflow-x: scroll" class="panel-body">                                            
                                            <?php 
                                                //Creates The Form
                                                echo $this->Form->create('WeeklyReportSetup', array(
                                                        //'action' => 'term_records',
                                                        'class' => 'form-horizontal'
                                                    )
                                                );     
                                            ?>
                                            <table  class="table table-bordered table-hover table-striped display custom_tables" >
                                                <thead>
                                                 <tr>
                                                     <th>#</th>
                                                     <th>No. of Reports</th>
                                                     <th>Weight Point</th>
                                                     <th>Class Group</th>
                                                     <th>Academic Term</th>
                                                     <th>Action</th>
                                                </tr>
                                              </thead>
                                              <tbody>
                                                  <?php if(!empty($WeeklyReports)):?>
                                                      <?php $i=1; foreach ($WeeklyReports as $WeeklyReport): ?>
                                                        <tr class="gradeA">
                                                           <td><?php echo $i++;?></td>
                                                           <td>
                                                               <select class="form-control form-cascade-control" name="data[WeeklyReportSetup][weekly_report][]" required="required"/>
                                                                   <option value="">  (Select No.)  </option>
                                                                   <?php
                                                                        for($j=1; $j <= 15; $j++) {
                                                                            $temp = ($WeeklyReport['WeeklyReportSetup']['weekly_report'] == $j) ? 'selected="selected"' : '';
                                                                            echo '<option '.$temp.'  value="'.$j.'">'.$j.'</option>';
                                                                        }
                                                                    ?>
                                                               </select>
                                                               <input type="hidden" name="data[WeeklyReportSetup][weekly_report_setup_id][]" value="<?php echo h($WeeklyReport['WeeklyReportSetup']['weekly_report_setup_id']);?>">
                                                           </td>
                                                            <td>
                                                                <select class="form-control form-cascade-control" name="data[WeeklyReportSetup][weekly_weight_point][]" required="required"/>
                                                                    <option value="">  (Select W.P)  </option>
                                                                    <?php
                                                                    for($j=5; $j <= 100; $j+=5) {
                                                                        $temp = ($WeeklyReport['WeeklyReportSetup']['weekly_weight_point'] == $j) ? 'selected="selected"' : '';
                                                                        echo '<option '.$temp.'  value="'.$j.'">'.$j.'</option>';
                                                                    }
                                                                    ?>
                                                                </select>
                                                            </td>
                                                           <td>
                                                              <?php 
                                                                  echo $this->Form->input('classgroup_id', array(
                                                                          'div' => false,
                                                                          'label' => false,
                                                                          'class' => 'form-control',
                                                                          'name' => 'data[WeeklyReportSetup][classgroup_id][]',
                                                                          'required' => "required",
                                                                          'selected' => $WeeklyReport['WeeklyReportSetup']['classgroup_id'],
                                                                          'options' => $Classgroups,
                                                                          'empty' => '(Select Class Group)'
                                                                      )
                                                                  ); 
                                                              ?>
                                                           </td>
                                                            <td>
                                                                <?php
                                                                    echo $this->Form->input('academic_term_id', array(
                                                                            'div' => false,
                                                                            'label' => false,
                                                                            'class' => 'form-control',
                                                                            'name' => 'data[WeeklyReportSetup][academic_term_id][]',
                                                                            'required' => "required",
                                                                            'selected' => $WeeklyReport['WeeklyReportSetup']['academic_term_id'],
                                                                            'options' => $Terms,
                                                                            'empty' => '(Select Academic Term)'
                                                                        )
                                                                    );
                                                                ?>
                                                            </td>
                                                           <td>
                                                               <input type="checkbox" class="polaris-input delete_ids" value="<?php echo h($WeeklyReport['WeeklyReportSetup']['weekly_report_setup_id']);?>">&nbsp;Delete
                                                           </td>
                                                        </tr>
                                                        
                                                       <?php endforeach; ?>
                                                        
                                                    <?php else:?>
                                                        <tr class="gradeA">
                                                           <td>1</td>
                                                           <td>
                                                               <select class="form-control form-cascade-control" name="data[WeeklyReportSetup][weekly_report][]" required="required"/>
                                                                   <option value="">  (Select No.)  </option>
                                                                    <?php for($i=1; $i <= 15; $i++): ?>
                                                                        <option value="<?php echo $i; ?>"><?php echo $i; ?></option>
                                                                    <?php endfor; ?>
                                                               </select>
                                                               <input type="hidden" name="data[WeeklyReportSetup][weekly_report_setup_id][]" value="">
                                                           </td>
                                                            <td>
                                                                <select class="form-control form-cascade-control" name="data[WeeklyReportSetup][weekly_weight_point][]" required="required"/>
                                                                    <option value="">  (Select W.P)  </option>
                                                                    <?php for($j=5; $j <= 100; $j+=5): ?>
                                                                        <option value="<?php echo $j; ?>"><?php echo $j; ?></option>
                                                                    <?php endfor; ?>
                                                                </select>
                                                            </td>
                                                           <td>
                                                               <?php
                                                                   echo $this->Form->input('classgroup_id', array(
                                                                           'div' => false,
                                                                           'label' => false,
                                                                           'class' => 'form-control',
                                                                           'name' => 'data[WeeklyReportSetup][classgroup_id][]',
                                                                           'required' => "required",
                                                                           'options' => $Classgroups,
                                                                           'empty' => '(Select Class Group)'
                                                                       )
                                                                   );
                                                               ?>
                                                           </td>
                                                            <td>
                                                                <?php
                                                                    echo $this->Form->input('academic_term_id', array(
                                                                            'div' => false,
                                                                            'label' => false,
                                                                            'class' => 'form-control',
                                                                            'name' => 'data[WeeklyReportSetup][academic_term_id][]',
                                                                            'required' => "required",
                                                                            'options' => $Terms,
                                                                            'empty' => '(Select Academic Term)'
                                                                        )
                                                                    );
                                                                ?>
                                                            </td>
                                                           <td></td>
                                                        </tr>
                                                    <?php endif;?>
                                                    <div class="col-sm-offset-5 col-sm-10">
                                                        <button type="button" class="add_new_record_btn btn btn-success">Add New Record</button>
                                                    </div>
                                                </tbody>
                                                <tfoot>
                                                 <tr>
                                                    <th>#</th>
                                                    <th>No. of Reports</th>
                                                    <th>Weight Point</th>
                                                    <th>Class Group</th>
                                                    <th>Academic Term</th>
                                                    <th>Action</th>
                                                </tr>
                                              </tfoot>                                              
                                            </table> 
                                                <div class="form-group">
                                                    <div class="col-sm-offset-2 col-sm-10">
                                                        <button type="button" class="add_new_record_btn btn btn-success">Add New Record</button>
                                                        <button type="submit" id="save_weekly_report_btn" class="btn btn-info">Save Records</button><span></span>
                                                        <input type="hidden" name="data[WeeklyReportSetup][deleted_term]" id="deleted_term">
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
            </div>
        </div>
    </div>
    
 </div> <!-- /col-md-12 -->
<?php
    //on click of Manage Sponsors Record link... activate the link
    echo $this->Js->buffer('
        setTabActive("[href=\"'.DOMAIN_NAME.'/records/weekly_report\"]", 1);
    ');