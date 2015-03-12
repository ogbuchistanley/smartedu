<?php echo $this->Html->script("../app/js/bootstrap-datatables.js", FALSE);?>
<?php echo $this->Html->script("../app/js/dataTables-custom.js", FALSE);?>
<?php echo $this->Html->script("../app/js/icheck/icheck.js", FALSE);?>
<?php echo $this->Html->script("../app/jquery/custom.record.js", FALSE);?>

<?php //$term_id = ClassRegistry::init('AcademicTerm'); ?>

<div class="col-md-12">
    <div class="panel">
        <!-- Info Boxes -->
        <!--div class="row">
            <div class="col-md-12">
                <div class="info-box  bg-info  text-white">
                    <div class="info-icon bg-info-dark">
                        <i class="fa fa-4x fa-outdent"></i>
                    </div>
                    <div class="info-details">
                        <h4>Academic Year Master Record <span class="label label-warning">Note: Only One Academic Year Status Can Be Set To Active</span></h4>
                    </div>
                </div>
            </div>
        </div>
        <!-- / Info Boxes -->
        <div class="panel-heading text-primary">
            <h3 class="panel-title">
               <i class="fa fa-plus"></i> Add New / <i class="fa fa-edit"></i>  Modify Existing Records
                <span class="label label-warning">Note: Only One Academic Year Status Can Be Set To Active</span>
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
                                        <div class="panel-heading">Search Form For Easier Filter </div>                                            
                                        <div class="panel-body">
                                            <?php 
                                                //Creates The Form
                                                echo $this->Form->create('SearchAcademicYear', array(
                                                        'class' => 'form-horizontal'
                                                    )
                                                );     
                                            ?>       
                                                
                                                <div class="form-group">
                                                    <label for="year_status_id" class="col-sm-4 control-label">Academic Years</label>
                                                    <div class="col-sm-8">
                                                        <?php 
                                                            echo $this->Form->input('year_status_id', array(
                                                                    'div' => false,
                                                                    'label' => false,
                                                                    'class' => 'form-control',
                                                                    'required' => "required",
                                                                    'options' => array('1' => 'Active Academic Year', '2' => 'Not Active'),
                                                                    'empty' => '(Select Year Status)'
                                                                )
                                                            ); 
                                                        ?>
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
                        <div class="col-md-8">
                           <div class="panel">
                                <div class="panel-body">
                                    <div class="panel panel-info">
                                        <div class="panel-heading panel-title  text-white">Academic Years Record Table</div>
                                        <div style="overflow-x: scroll" class="panel-body">                                            
                                            <?php 
                                                //Creates The Form
                                                echo $this->Form->create('AcademicYear', array(
                                                        //'action' => 'term_records',
                                                        'class' => 'form-horizontal'
                                                    )
                                                );     
                                            ?>
                                            <table  class="table table-bordered table-hover table-striped display custom_tables" >
                                                <thead>
                                                 <tr>
                                                  <th>#</th>
                                                  <th>Academic Year</th>
                                                  <th>Academic Year Status</th>
                                                  <th>Action</th>
                                                </tr>
                                              </thead>
                                              <tbody>
                                                  <?php if(!empty($AcademicYears)):?>
                                                      <?php $i=1; foreach ($AcademicYears as $AcademicYear): ?>
                                                        <tr class="gradeA">
                                                           <td><?php echo $i++;?></td>
                                                           <td>
                                                               <input class="form-control form-cascade-control" required name="data[AcademicYear][academic_year][]" value="<?php echo h($AcademicYear['AcademicYear']['academic_year']);?>">
                                                               <input type="hidden" name="data[AcademicYear][academic_year_id][]" value="<?php echo h($AcademicYear['AcademicYear']['academic_year_id']);?>">
                                                           </td>
                                                           <td>
                                                              <?php 
                                                                  echo $this->Form->input('year_status_id', array(
                                                                          'div' => false,
                                                                          'label' => false,
                                                                          'class' => 'form-control year_status_id',
                                                                          'name' => 'data[AcademicYear][year_status_id][]',
                                                                          'required' => "required",
                                                                          'selected' => $AcademicYear['AcademicYear']['year_status_id'],
                                                                          'options' => array('1' => 'Active Academic Year', '2' => 'Not Active'),
                                                                          'empty' => '(Select Status)'
                                                                      )
                                                                  ); 
                                                              ?>
                                                           </td>
                                                           <td>
                                                               <input type="checkbox" class="polaris-input delete_ids" value="<?php echo h($AcademicYear['AcademicYear']['academic_year_id']);?>">&nbsp;Delete
                                                           </td>
                                                        </tr>
                                                        
                                                       <?php endforeach; ?>
                                                        
                                                    <?php else:?>
                                                        <tr class="gradeA">
                                                           <td>1</td>
                                                           <td>
                                                               <input class="form-control form-cascade-control" required name="data[AcademicYear][academic_year][]" value="">
                                                               <input type="hidden" name="data[AcademicYear][academic_year_id][]" value="">
                                                           </td>
                                                           <td>
                                                              <?php 
                                                                  echo $this->Form->input('year_status_id', array(
                                                                          'div' => false,
                                                                          'label' => false,
                                                                          'class' => 'form-control year_status_id',
                                                                          'name' => 'data[AcademicYear][year_status_id][]',
                                                                          'required' => "required",
                                                                          'options' => array('1' => 'Active Academic Year', '2' => 'Not Active'),
                                                                          'empty' => '(Select Status)'
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
                                                  <th>Academic Year</th>
                                                  <th>Academic Year Status</th>
                                                  <th>Action</th>
                                                </tr>
                                              </tfoot>                                              
                                            </table> 
                                                <div class="form-group">
                                                    <div class="col-sm-offset-2 col-sm-10">
                                                        <button type="button" class="add_new_record_btn btn btn-success">Add New Record</button>
                                                        <button type="submit" id="save_year_btn" class="btn btn-info">Save Records</button><span></span>
                                                        <input type="hidden" name="data[AcademicYear][deleted_term]" id="deleted_term">
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
        setTabActive("[href=\"'.DOMAIN_NAME.'/records/academic_year\"]", 1);
    ');
?>