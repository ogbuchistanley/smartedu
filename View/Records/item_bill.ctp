<?php echo $this->Html->script("../app/js/bootstrap-datatables.js", FALSE);?>
<?php echo $this->Html->script("../app/js/dataTables-custom.js", FALSE);?>
<?php echo $this->Html->script("../app/jquery/custom.record.js", FALSE);?>

<div class="col-md-12">
    <div class="panel">
        <!-- Info Boxes -->
        <!--div class="row">
            <div class="col-md-12">
                <div class="info-box  bg-info  text-white">
                    <div class="info-icon bg-info-dark">
                        <i class="fa fa-4x fa-money"></i>
                    </div>
                    <div class="info-details">
                        <h4>Item Bills Master Record</h4>
                    </div>
                </div>
            </div>
        </div>
        <!-- / Info Boxes -->
        <div class="panel-heading text-primary">
            <h3 class="panel-title">
               <i class="fa fa-plus"></i> Add New / <i class="fa fa-edit"></i>  Modify Existing Records
                <span class="label label-primary">Item Bills Master Record</span>
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
                                                echo $this->Form->create('SearchItemBill', array(
                                                        'class' => 'form-horizontal'
                                                    )
                                                );     
                                            ?>       
                                                
                                                <div class="form-group">
                                                    <label for="item_search_id" class="col-sm-4 control-label">Item</label>
                                                    <div class="col-sm-8">
                                                        <?php 
                                                            echo $this->Form->input('item_search_id', array(
                                                                    'div' => false,
                                                                    'label' => false,
                                                                    'class' => 'form-control',
                                                                    'id' => 'item_search_id',
                                                                    'options' => $Items,
                                                                    'empty' => '(Select Item)'
                                                                )
                                                            ); 
                                                        ?>
                                                    </div>
                                                </div>
                                                <div class="form-group">
                                                    <label for="classlevel_search_id" class="col-sm-4 control-label">Class Level</label>
                                                    <div class="col-sm-8">
                                                        <?php 
                                                            echo $this->Form->input('classlevel_search_id', array(
                                                                    'div' => false,
                                                                    'label' => false,
                                                                    'class' => 'form-control',
                                                                    'id' => 'classlevel_search_id',
                                                                    'options' => $Classlevels,
                                                                    'empty' => '(Select Class Level)'
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
                        <div class="col-md-11">
                           <div class="panel">
                                <div class="panel-body">
                                    <div class="panel panel-info">
                                        <div class="panel-heading panel-title  text-white">Item Bills Record Table</div>
                                        <div style="overflow-x: scroll" class="panel-body">                                            
                                            <?php 
                                                //Creates The Form
                                                echo $this->Form->create('ItemBill', array(
                                                        //'action' => 'term_records',
                                                        'class' => 'form-horizontal'
                                                    )
                                                );     
                                            ?>
                                            <table  class="table table-bordered table-hover table-striped display custom_tables" >
                                                <thead>
                                                 <tr>
                                                  <th>#</th>
                                                  <th>Item </th>
                                                  <th>Class Level</th>
                                                  <th>Price (&#8358;)</th>
                                                  <th>Action</th>
                                                </tr>
                                              </thead>
                                              <tbody>
                                                  <?php if(!empty($ItemBills)):?>
                                                      <?php $i=1; foreach ($ItemBills as $ItemBill): ?>
                                                        <tr class="gradeA">
                                                           <td><?php echo $i++;?></td>
                                                           <td>
                                                               <?php 
                                                                    echo $this->Form->input('item_id', array(
                                                                            'div' => false,
                                                                            'label' => false,
                                                                            'class' => 'form-control',
                                                                            'id' => 'item_id',
                                                                            'name' => 'data[ItemBill][item_id][]',
                                                                            'required' => "required",
                                                                            'selected' => $ItemBill['ItemBill']['item_id'],
                                                                            'options' => $Items,
                                                                            'empty' => '(Select Item)'
                                                                        )
                                                                    ); 
                                                                ?>
                                                               <input type="hidden" name="data[ItemBill][item_bill_id][]" value="<?php echo h($ItemBill['ItemBill']['item_bill_id']);?>">
                                                           </td>
                                                           <td>
                                                              <?php 
                                                                  echo $this->Form->input('classlevel_id', array(
                                                                          'div' => false,
                                                                          'label' => false,
                                                                          'class' => 'form-control',
                                                                          'name' => 'data[ItemBill][classlevel_id][]',
                                                                          'required' => "required",
                                                                          'selected' => $ItemBill['ItemBill']['classlevel_id'],
                                                                          'options' => $Classlevels,
                                                                          'empty' => '(Select Class Level)'
                                                                      )
                                                                  ); 
                                                              ?>
                                                           </td>
                                                           <td>
                                                               <input class="form-control form-cascade-control" required name="data[ItemBill][price][]" value="<?php echo h($ItemBill['ItemBill']['price']);?>">
                                                           </td>
                                                           <td>
                                                               <input type="checkbox" class="polaris-input delete_ids" value="<?php echo h($ItemBill['ItemBill']['item_bill_id']);?>">&nbsp;Delete
                                                           </td>
                                                        </tr>
                                                        
                                                       <?php endforeach; ?>
                                                        
                                                    <?php else:?>
                                                        <tr class="gradeA">
                                                           <td>1</td>
                                                           <td>
                                                               <?php 
                                                                    echo $this->Form->input('item_id', array(
                                                                            'div' => false,
                                                                            'label' => false,
                                                                            'class' => 'form-control',
                                                                            'id' => 'item_id',
                                                                            'name' => 'data[ItemBill][item_id][]',
                                                                            'required' => "required",
                                                                            'options' => $Items,
                                                                            'empty' => '(Select Item)'
                                                                        )
                                                                    ); 
                                                                ?>
                                                               <input type="hidden" name="data[ItemBill][item_bill_id][]" value="">
                                                           </td>
                                                           <td>
                                                              <?php 
                                                                  echo $this->Form->input('classlevel_id', array(
                                                                          'div' => false,
                                                                          'label' => false,
                                                                          'class' => 'form-control',
                                                                          'name' => 'data[ItemBill][classlevel_id][]',
                                                                          'required' => "required",
                                                                          'options' => $Classlevels,
                                                                          'empty' => '(Select Class Level)'
                                                                      )
                                                                  ); 
                                                              ?>
                                                           </td>
                                                           <td>
                                                               <input class="form-control form-cascade-control" required name="data[ItemBill][price][]">
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
                                                  <th>Item </th>
                                                  <th>Class Level</th>
                                                  <th>Price (&#8358;)</th>
                                                  <th>Action</th>
                                                </tr>
                                              </tfoot>                                              
                                            </table> 
                                                <div class="form-group">
                                                    <div class="col-sm-offset-2 col-sm-10">
                                                        <button type="button" class="add_new_record_btn btn btn-success">Add New Record</button>
                                                        <button type="submit" id="save_item_bill_btn" class="btn btn-info">Save Records</button><span></span>
                                                        <input type="hidden" name="data[ItemBill][deleted_term]" id="deleted_term">
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
        setTabActive("[href=\"'.DOMAIN_NAME.'/records/item_bill\"]", 1);
    ');