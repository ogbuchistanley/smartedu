<?php echo $this->Html->script("app/jquery/custom.item.js", FALSE);?>
<?php $term_id = ClassRegistry::init('AcademicTerm'); ?>
<?php
    $item_process_fees = Configure::read('item_process_fees');
?>

<div class="col-md-12">
    <div class="panel">
        <!-- Info Boxes -->
        <div class="row">
            <div class="col-md-12">
                <div class="info-box  bg-info  text-white">
                    <div class="info-icon bg-info-dark">
                        <i class="fa fa-list-alt fa-4x"></i>
                    </div> 
                    <div class="info-details">
                        <h4>Process, Manage and View Fees / Item Bills Assigned to a Students or Class Room</h4>
                    </div> 
                </div>
            </div>
        </div>
        <!-- / Info Boxes -->
        <div class="panel-heading text-primary">
            <h3 class="panel-title">                
               <i class="fa fa-align-center"></i>
               Management of Fees / Item Bills for Students or Class Room
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
                    <ul id="myTab" class="nav nav-tabs">
                        <?php if ($item_process_fees) :?>
                        <li>
                            <a href="<?php echo DOMAIN_NAME ?>/items/index#process_fees" data-toggle="tab"><b><i class="fa fa-gear"></i> Process Fees</b></a>
                        </li>
                        <?php endif; ?>
                        <li>
                            <a href="<?php echo DOMAIN_NAME ?>/items/index#bill_student" data-toggle="tab"><b><i class="fa fa-money"></i> Bill Student / <i class="fa fa-eye-slash"></i> Fees Status</b></a>
                        </li>
                        <!--li>
                            <a href="<?php //echo DOMAIN_NAME ?>/items/index#search" data-toggle="tab"><b><i class="fa fa-search"></i> Search History</b></a>
                        </li-->
                    </ul>
                    <div id="myTabContent" class="tab-content">
                        <?php if ($item_process_fees) :?>
                        <div class="tab-pane fade in active" id="process_fees"><br>
                            <div class="col-md-7">
                                <div class="panel panel-cascade">
                                    <div class="panel-body">
                                        <div class="panel panel-default">
                                            <div class="panel-heading">
                                                <span class="label label-warning" style="font-size: large">
                                                    <i class="fa fa-warning"></i> Note::This Process is not reversible
                                                </span>
                                            </div>                                            
                                            <div class="panel-body">
                                                <?php 
                                                    //Creates The Form
                                                    echo $this->Form->create('ProcessItem', array(
                                                            'class' => 'form-horizontal',
                                                            'id' => 'process_item_form'
                                                        )
                                                    );     
                                                ?>    
                                                    <div class="form-group">
                                                        <label for="academic_year_id" class="col-sm-4 control-label">Academic Years</label>
                                                        <div class="col-sm-8">
                                                            <?php 
                                                                echo $this->Form->input('academic_year_id', array(
                                                                        'div' => false,
                                                                        'label' => false,
                                                                        'class' => 'form-control',
                                                                        'id' => 'academic_year_id',
                                                                        'required' => "required",
                                                                        'options' => $AcademicYears,
                                                                        'empty' => '(Select Academic Year)'
                                                                    )
                                                                ); 
                                                            ?>
                                                        </div>
                                                    </div>
                                                    <div class="form-group">
                                                        <label for="academic_term_id" class="col-sm-4 control-label">Academic Terms</label>
                                                        <div class="col-sm-8">
                                                            <select class="form-control" name="data[ProcessItem][academic_term_id]" id="academic_term_id" required="required">
                                                                <option value="">  (Select Academic Term)  </option>
                                                                
                                                            </select>
                                                        </div>
                                                    </div>
                                                    <div class="form-group">
                                                        <label for="birth_date" class="col-sm-4 control-label">Process Date</label>
                                                        <div class="col-md-8">
                                                            <input type="text" class="form-control form-cascade-control input-small" name="data[ProcessItem][process_date]" 
                                                                id="process_date" value="<?php echo date('m/d/Y');?>" placeholder="Select Process Date" required="required"/>
                                                        </div>
                                                     </div>
                                                    <div class="form-group">                                                
                                                        <div class="col-sm-offset-2 col-sm-10">
                                                            <button type="submit" class="btn btn-info">Process Fees</button>
                                                        </div>
                                                    </div>
                                                </form>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                            <div class="col-md-5" id="msg_box"> </div>
                        </div>
                        <?php endif; ?><!-- /panel body -->
                        <div class="tab-pane fade in" id="bill_student"><br>
                            <div class="col-md-7">
                                <div class="panel panel-cascade">
                                    <div class="panel-body">
                                        <div class="panel panel-default">
                                            <div class="panel-heading"><i class="fa fa-search fa-1x"></i> Search for Students in a CLass Room or CLass Rooms in a Class Level </div>                                            
                                            <div class="panel-body">
                                                <?php 
                                                    //Creates The Form
                                                    echo $this->Form->create('SearchExamTAScores', array(
                                                            'action' => 'search',
                                                            'class' => 'form-horizontal',
                                                            'id' => 'search_student_class_form'
                                                        )
                                                    );     
                                                ?>                                                                                                  
                                                    <div class="form-group">
                                                        <label for="academic_year_examTAScores_id" class="col-sm-4 control-label">Academic Years</label>
                                                        <div class="col-sm-8">
                                                            <?php 
                                                                echo $this->Form->input('academic_year_examTAScores_id', array(
                                                                        'div' => false,
                                                                        'label' => false,
                                                                        'class' => 'form-control',
                                                                        'id' => 'academic_year_examTAScores_id',
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
                                                        <label for="academic_term_examTAScores_id" class="col-sm-4 control-label">Academic Terms</label>
                                                        <div class="col-sm-8">
                                                            <select class="form-control" name="data[SearchExamTAScores][academic_term_examTAScores_id]" id="academic_term_examTAScores_id" required="required">
                                                                <option value="<?php echo $term_id->getCurrentTermID();?>"><?php echo $term_id->getCurrentTermName();?></option>

                                                            </select>
                                                        </div>
                                                    </div>
                                                    <div class="form-group">
                                                        <label for="classlevel_examTAScores_id" class="col-sm-4 control-label">Class Levels</label>
                                                        <div class="col-sm-8">
                                                            <?php 
                                                                echo $this->Form->input('classlevel_examTAScores_id', array(
                                                                        'div' => false,
                                                                        'label' => false,
                                                                        'class' => 'form-control',
                                                                        'id' => 'classlevel_examTAScores_id',
                                                                         'required' => "required",
                                                                        'options' => $Classlevels,
                                                                        'empty' => '(Select Classlevel)'
                                                                    )
                                                                ); 
                                                            ?>
                                                        </div>
                                                    </div>
                                                    <div class="form-group">
                                                        <label for="class_examTAScores_id" class="col-sm-4 control-label">Class Rooms</label>
                                                        <div class="col-sm-8">
                                                            <select class="form-control" name="data[SearchExamTAScores][class_examTAScores_id]" id="class_examTAScores_id">
                                                                <option value="">  (Select Class Room)  </option>

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
                            <div class="col-md-5" id="msg_box2">     </div>
                            <div class="col-md-9">
                                <div style="overflow-x: scroll"  class="panel-body">
                                    <table class="table table-bordered table-hover table-striped display" id="bill_student_table_div" >
                                        
                                    </table>
                                </div> 
                            </div>
                        </div>
                        <div class="tab-pane fade in" id="search"><br>
                            <div class="col-md-7">
                                <div class="panel panel-cascade">
                                    <div class="panel-body">
                                        <div class="panel panel-default">
                                            <div class="panel-heading">
                                                <div class="panel-heading"><i class="fa fa-search fa-1x"></i> Search for Academic Term to view Students Payment Status</div>                                            
                                            </div>                                            
                                            <div class="panel-body">
                                                <?php 
                                                    //Creates The Form
                                                    echo $this->Form->create('SearchPayment', array(
                                                            'class' => 'form-horizontal',
                                                            'id' => 'search_payment_status'
                                                        )
                                                    );     
                                                ?>    
                                                    <div class="form-group">
                                                        <label for="academic_year_id" class="col-sm-4 control-label">Academic Years</label>
                                                        <div class="col-sm-8">
                                                            <?php 
                                                                echo $this->Form->input('search_academic_year_id', array(
                                                                        'div' => false,
                                                                        'label' => false,
                                                                        'class' => 'form-control',
                                                                        'id' => 'search_academic_year_id',
                                                                        'required' => "required",
                                                                        'options' => $AcademicYears,
                                                                        'empty' => '(Select Academic Year)'
                                                                    )
                                                                ); 
                                                            ?>
                                                        </div>
                                                    </div>
                                                    <div class="form-group">
                                                        <label for="search_academic_term_id" class="col-sm-4 control-label">Academic Terms</label>
                                                        <div class="col-sm-8">
                                                            <select class="form-control" name="data[SearchPayment][search_academic_term_id]" id="search_academic_term_id" required="required">
                                                                <option value="">  (Select Academic Term)  </option>
                                                                
                                                            </select>
                                                        </div>
                                                    </div>
                                                    <div class="form-group">                                                
                                                        <div class="col-sm-offset-2 col-sm-10">
                                                            <button type="submit" class="btn btn-info">Search </button>
                                                        </div>
                                                    </div>
                                                </form>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                            <div class="col-md-5" id="msg_box3"> </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>	
    <!-- Model for confirming the fees processed for an academic term  -->
    <div id="confirm_process_fees_modal" class="modal fade" tabindex="-1" data-width="400" style="display: none;">
       <div class="modal-header">
           <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
           <div class="modal-title alert alert-info">Confirming Process Fees For an Academic Term</div>
       </div>
        <form action="#" id="confirm_process_fees_form" method="post">
            <div class="modal-body">
                <div class="row">
                    <div class="col-md-12" id="confirm_output"></div>
                </div>
                <div class="row">
                    <div class="col-md-12">
                        <p style="color: orangered">
                            Are You Really Sure You Want To Process Fees For The Academic Term
                            <i class="fa fa-warning fa-1x"></i>
                            <i class="fa fa-warning fa-1x"></i>
                            <i class="fa fa-warning fa-1x"></i>
                        </p>
                    </div>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" data-dismiss="modal" class="btn btn-default">Close</button>
                <button type="submit" class="btn btn-primary">Yes Confirm</button>
            </div>
            <div class="col-md-12" id="msg_box_modal">     </div>
        </form>
   </div><!-- /Modal Form Confirmation of subject-->
    <!-- Model for Billing Students or Class rooms-->
    <div id="confirm_bill_student_modal" class="modal fade" tabindex="-1" data-width="400" style="display: none;">
       <div class="modal-header">
           <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
            <div class="modal-title alert alert-danger">
                Billing of a Student or Students in a Class Room<br>
                <i class="fa fa-warning"></i> Note::This Process is not reversible
            </div>
       </div>
        <?php 
                //Creates The Form
                echo $this->Form->create('ItemVariable', array(
                        'class' => 'form-horizontal',
                        'id' => 'confirm_bill_student_form'
                    )
                );     
            ?>
            <div class="modal-body">
                <div class="row">
                    <div class="form-group">
                        <label for="itemIV_id" class="col-sm-4 control-label">Item</label>
                        <div class="col-sm-8">
                            <?php 
                                echo $this->Form->input('itemIV_id', array(
                                        'div' => false,
                                        'label' => false,
                                        'class' => 'form-control',
                                        'id' => 'itemIV_id',
                                        'required' => "required",
                                        'options' => $Items,
                                        'empty' => '(Select Item)'
                                    )
                                ); 
                            ?>
                        </div>
                    </div>
                    <div class="form-group">
                        <label for="priceIV" class="col-sm-4 control-label">Amount</label>
                        <div class="col-sm-8">
                            <input type="text" class="input-small" required="required" id="priceIV" name="data[ItemVariable][priceIV]">
                        </div>
                    </div>
                </div>
            </div>
            <div class="modal-footer">
                <input type="hidden" class="input-small" id="studentIV_id" name="data[ItemVariable][studentIV_id]">
                <input type="hidden" class="input-small" id="classIV_id" name="data[ItemVariable][classIV_id]">
                <input type="hidden" class="input-small" id="academic_termIV_id" name="data[ItemVariable][academic_termIV_id]">
                <button type="button" data-dismiss="modal" class="btn btn-default">Close</button>
                <button type="submit" class="btn btn-primary">Yes Confirm</button>
            </div>
            <div class="col-md-12" id="msg_box2_modal">     </div>
        </form>
   </div><!--/ Modal Modifying Subjects Assigned-->
</div>
<?php
    // OnChange Of Classlevel Get Class Room
//    $this->Utility->getDependentListBox('#classlevel_examTAScores_id', '#class_examTAScores_id', 'classrooms', 'ajax_get_classes', 'SearchExamTAScores');
//    
//    // OnChange of Academic Year Get Academic Term
//    $this->Utility->getDependentListBox('#academic_year_id', '#academic_term_id', 'academic_terms', 'ajax_get_terms', 'ProcessItem');
//    $this->Utility->getDependentListBox('#academic_year_examTAScores_id', '#academic_term_examTAScores_id', 'academic_terms', 'ajax_get_terms', 'SearchExamTAScores');
?>