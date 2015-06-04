<?php echo $this->Html->script("../app/js/bootstrap-datatables.js", FALSE);?>
<?php echo $this->Html->script("../app/js/dataTables-custom.js", FALSE);?>
<?php echo $this->Html->script("../app/js/icheck/icheck.js", FALSE);?>
<?php echo $this->Html->script("../app/js/jquery-ui.js", FALSE);?>
<?php echo $this->Html->script("../app/jquery/custom.record.js", FALSE);?>

<?php //$term_id = ClassRegistry::init('AcademicTerm'); ?>

<div class="col-md-12">
    <div class="panel">
        <!-- Info Boxes -->
        <!--div class="row">
            <div class="col-md-12">
                <div class="info-box  bg-info  text-white">
                    <div class="info-icon bg-info-dark">
                        <i class="fa fa-4x fa-ticket"></i>
                    </div>
                    <div class="info-details">
                        <h4>Academic Term Master Record <span class="label label-warning">Note: Only One Academic Term Status Can Be Set To Active</span></h4>
                    </div>
                </div>
            </div>
        </div>
        <!-- / Info Boxes -->
        <div class="panel-heading text-primary">
            <h3 class="panel-title">
               <i class="fa fa-plus"></i> Add New / <i class="fa fa-edit"></i>  Modify Existing Records
                <span class="label label-warning">Note: Only One Academic Term Status Can Be Set To Active</span>
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
                                                echo $this->Form->create('SearchAcademicTerm', array(
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
                                                                    'options' => $AcademicYears,
                                                                    'empty' => '(Select Academic Year)'
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
                        <div class="col-md-12">
                           <div class="panel">
                                <div class="panel-body">
                                    <div class="panel panel-info">
                                        <div class="panel-heading panel-title  text-white">Academic Terms Record Table </div>
                                        <div style="overflow-x: scroll" class="panel-body">                                            
                                            <?php 
                                                //Creates The Form
                                                echo $this->Form->create('AcademicTerm', array(
                                                        //'action' => 'term_records',
                                                        'class' => 'form-horizontal',
                                                        'id' => 'term_record_form'
                                                    )
                                                );     
                                            ?>
                                            <table  class="table table-bordered table-hover table-striped display custom_tables" >
                                                <thead>
                                                 <tr>
                                                  <th>#</th>
                                                  <th>Academic Term</th>
                                                  <th>Academic Year</th>
                                                  <th>Term Status</th>
                                                  <th>Term Type</th>
                                                  <th>Term Begins</th>
                                                  <th>Term Ends</th>
                                                  <th>Action</th>
                                                </tr>
                                              </thead>
                                              <tbody>
                                                  <?php if(!empty($AcademicTerms)):?>
                                                      <?php $i=1; foreach ($AcademicTerms as $AcademicTerm): ?>
                                                        <tr class="gradeA">
                                                           <td><?php echo $i++;?></td>
                                                           <td>
                                                               <input class="form-control form-cascade-control" required name="data[AcademicTerm][academic_term][]" value="<?php echo h($AcademicTerm['AcademicTerm']['academic_term']);?>">
                                                               <input type="hidden" name="data[AcademicTerm][academic_term_id][]" value="<?php echo h($AcademicTerm['AcademicTerm']['academic_term_id']);?>">
                                                           </td>
                                                           <td>
                                                              <?php 
                                                                  echo $this->Form->input('academic_year_id', array(
                                                                          'div' => false,
                                                                          'label' => false,
                                                                          'class' => 'form-control',
                                                                          'name' => 'data[AcademicTerm][academic_year_id][]',
                                                                          'required' => "required",
                                                                          'selected' => $AcademicTerm['AcademicTerm']['academic_year_id'],
                                                                          'options' => $AcademicYears,
                                                                          'empty' => '(Select Year)'
                                                                      )
                                                                  ); 
                                                              ?>
                                                           </td>
                                                           <td>
                                                              <?php 
                                                                  echo $this->Form->input('term_status_id', array(
                                                                          'div' => false,
                                                                          'label' => false,
                                                                          'class' => 'form-control term_status_id',
                                                                          'name' => 'data[AcademicTerm][term_status_id][]',
                                                                          'required' => "required",
                                                                          'selected' => $AcademicTerm['AcademicTerm']['term_status_id'],
                                                                          'options' => array('1' => 'Active Academic Term', '2' => 'Not Active'),
                                                                          'empty' => '(Select Status)'
                                                                      )
                                                                  ); 
                                                              ?>
                                                           </td>
                                                           <td>                                                                 
                                                              <?php 
                                                                  echo $this->Form->input('term_type_id', array(
                                                                          'div' => false,
                                                                          'label' => false,
                                                                          'class' => 'form-control',
                                                                          'name' => 'data[AcademicTerm][term_type_id][]',
                                                                          'required' => "required",
                                                                          'selected' => $AcademicTerm['AcademicTerm']['term_type_id'],
                                                                          'options' => array('1' => 'First Term', '2' => 'Second Term', '3' => 'Third Term'),
                                                                          'empty' => '(Select Type)'
                                                                      )
                                                                  ); 
                                                              ?>
                                                           </td>
                                                            <td style="width: 112px;">
                                                                <input class="form-control form-cascade-control date_picker" name="data[AcademicTerm][term_begins][]"
                                                                       value="<?php echo $this->Utility->formatDate($AcademicTerm['AcademicTerm']['term_begins']);?>">
                                                            </td>
                                                            <td style="width: 112px;">
                                                                <input class="form-control form-cascade-control date_picker" name="data[AcademicTerm][term_ends][]"
                                                                       value="<?php echo $this->Utility->formatDate($AcademicTerm['AcademicTerm']['term_ends']);?>">
                                                            </td>
                                                           <td>
                                                               <input type="checkbox" class="polaris-input delete_ids" value="<?php echo h($AcademicTerm['AcademicTerm']['academic_term_id']);?>">&nbsp;Delete
                                                           </td>
                                                        </tr>
                                                        
                                                       <?php endforeach; ?>
                                                        
                                                    <?php else:?>
                                                        <tr class="gradeA">
                                                           <td>1</td>
                                                           <td>
                                                               <input class="form-control form-cascade-control" required name="data[AcademicTerm][academic_term][]" value="">
                                                               <input type="hidden" name="data[AcademicTerm][academic_term_id][]" value="">
                                                           </td>
                                                           <td>
                                                              <?php 
                                                                  echo $this->Form->input('academic_year_id', array(
                                                                          'div' => false,
                                                                          'label' => false,
                                                                          'class' => 'form-control',
                                                                          'name' => 'data[AcademicTerm][academic_year_id][]',
                                                                          'required' => "required",
                                                                          'options' => $AcademicYears,
                                                                          'empty' => '(Select Year)'
                                                                      )
                                                                  ); 
                                                              ?>
                                                           </td>
                                                           <td>
                                                              <?php 
                                                                  echo $this->Form->input('term_status_id', array(
                                                                          'div' => false,
                                                                          'label' => false,
                                                                          'class' => 'form-control term_status_id',
                                                                          'name' => 'data[AcademicTerm][term_status_id][]',
                                                                          'required' => "required",
                                                                          'options' => array('1' => 'Active Academic Term', '2' => 'Not Active'),
                                                                          'empty' => '(Select Status)'
                                                                      )
                                                                  ); 
                                                              ?>
                                                           </td>
                                                           <td>                                                                 
                                                              <?php 
                                                                  echo $this->Form->input('term_type_id', array(
                                                                          'div' => false,
                                                                          'label' => false,
                                                                          'class' => 'form-control',
                                                                          'name' => 'data[AcademicTerm][term_type_id][]',
                                                                          'required' => "required",
                                                                          'options' => array('1' => 'First Term', '2' => 'Second Term', '3' => 'Third Term'),
                                                                          'empty' => '(Select Type)'
                                                                      )
                                                                  ); 
                                                              ?>
                                                           </td>
                                                           <td style="width: 112px;">
                                                               <input class="form-control form-cascade-control date_picker" placeholder="mm/dd/yyyy" name="data[AcademicTerm][term_begins][]">
                                                           </td>
                                                            <td style="width: 112px;">
                                                               <input class="form-control form-cascade-control date_picker" placeholder="mm/dd/yyyy" name="data[AcademicTerm][term_ends][]">
                                                           </td>
                                                           <td></td>
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
                                                     <th>Academic Term</th>
                                                     <th>Academic Year</th>
                                                     <th>Term Status</th>
                                                     <th>Term Type</th>
                                                     <th>Term Begins</th>
                                                     <th>Term Ends</th>
                                                     <th>Action</th>
                                                </tr>
                                              </tfoot>                                              
                                            </table> 
                                                <div class="form-group">
                                                    <div class="col-sm-offset-2 col-sm-10">
                                                        <button type="button" class="add_new_record_btn btn btn-success">Add New Record</button>
                                                        <button type="submit" id="save_term_btn" class="btn btn-info">Save Records</button><span></span>
                                                        <input type="hidden" name="data[AcademicTerm][deleted_term]" id="deleted_term">
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
        setTabActive("[href=\"'.DOMAIN_NAME.'/records/index\"]", 1);
    ');
    
//    echo $this->Js->buffer('
//        $(".polaris-input").iCheck({
//            checkboxClass: \"icheckbox_polaris\",
//            radioClass: \"iradio_polaris\",
//            increaseArea: \"20%\"
//        });
//    ');
?>