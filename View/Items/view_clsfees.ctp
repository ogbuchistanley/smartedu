<?php 
    App::uses('Encryption', 'Utility'); 
    $Encryption = new Encryption();
    
?>
<?php echo $this->Html->script("../app/js/bootstrap-datatables.js", FALSE);?>
<?php echo $this->Html->script("../app/js/dataTables-custom.js", FALSE);?>
<?php echo $this->Html->script("../app/jquery/custom.item.js", FALSE);?>

<?php $Item = ClassRegistry::init('Item'); ?>
<div class="col-md-12">
    <div class="panel">
        <!-- Info Boxes -->
        <div class="row">
            <div class="col-md-12">
                <div class="info-box  bg-info  text-white">
                    <div class="info-icon bg-info-dark">
                        <i class="fa fa-money fa-4x"></i>
                    </div>
                    <div class="info-details">
                        <h4>View Students in a Class Room Terminal School Fees Charges </h4>
                    </div>
                </div>
            </div>
        </div>
        <!-- / Info Boxes -->
        <div class="panel-heading text-primary">
            <h3 class="panel-title">
               <i class="fa fa-male"></i> Summary of Students in a Class Room Terminal School Fees Charges
                <span class="pull-right">
                    <a href="javascript:void(0)"  title="Refresh"><i class="fa fa-refresh"></i></a>
                    <a href="#" class="panel-minimize"><i class="fa fa-chevron-up"></i></a>
                    <a href="#" class="panel-close"><i class="fa fa-times"></i></a>
                </span>
            </h3>
        </div>        
        <div class="row">
            <!-- Panel with Tables -->            
            <div class="col-md-6 col-md-offset-3">
                <div class="panel">
                    <div class="panel-body">
                        <div class="panel panel-primary">
                        <div class="panel-heading panel-title  text-white">Class Room Details</div>
                            <table class="table table-bordered table-hover table-striped">
                                <?php
                                    if(!empty($ClassBills['ClassBill'])):   
                                        $Info = $ClassBills['ClassBill'];
                                        $size = count($ClassBills['ClassBill']);
                                        $Info = array_shift($Info);
                                ?>
                                    <tbody>
                                        <tr>
                                          <th>Class Name</th>
                                          <td><?php echo $Info['class_name'];?></td>
                                        </tr>
                                        <tr>
                                          <th>No. of Students in Class</th>
                                          <td><?php echo $size;?></td>
                                        </tr>
                                        <tr>
                                          <th>Academic Term</th>
                                          <td><?php echo $Info['academic_term'];?></td>
                                        </tr>                                        
                                    </tbody>
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
        
        <div class="row">
            <div class="col-md-10 col-md-offset-1">
               <div class="panel">
                    <div class="panel-body">
                        <div class="panel panel-info">
                            <div class="panel-heading panel-title  text-white">Terminal Items Charges Summary</div>
                            <div style="overflow-x: scroll" class="panel-body">
                                <?php if(!empty($ClassBills['ClassBill'])):?>
                                <table  class="table table-bordered table-hover table-striped display">
                                    <thead>
                                     <tr>
                                      <th>#</th>
                                      <th>ID. No</th>
                                      <th>Student Name</th>
                                      <th>Student Status</th>
                                      <th>Sponsor Name</th>
                                      <th>Amount (&#8358;)</th>
                                      <th>Edit Status</th>
                                      <th>Details</th>
                                    </tr>
                                  </thead>
                                  <tbody>
                                    <?php $i=1; ?>
                                    <?php foreach ($ClassBills['ClassBill'] as $ItemBill): ?>
                                        <tr>
                                           <td><?php echo $i++;?></td>
                                           <td><?php echo h($ItemBill['student_no']);?></td>
                                           <td><?php echo h($ItemBill['student_name']);?></td>
                                           <td style="font-size: medium">
                                               <?php 
                                                if(h($ItemBill['student_status_id']) === '1' || h($ItemBill['student_status_id']) === '2'){
                                                    echo '<span class="label label-success"> '.$ItemBill['student_status'].'</span>';
                                                }else if(h($ItemBill['student_status_id']) === '3'){
                                                    echo '<span class="label label-warning"> '.$ItemBill['student_status'].'</span>';
                                                }else{
                                                    echo '<span class="label label-danger"> '.$ItemBill['student_status'].'</span>';
                                                }
                                              ?>
                                           </td>
                                           <td>
                                               <a target="__blank" href="<?php echo DOMAIN_NAME ?>/sponsors/view/<?php echo $ItemBill['sponsor_id']; ?>" class="btn-link">
                                                    <?php echo h($ItemBill['sponsor_name']); ?>
                                                </a>
                                           </td>
                                           <td><?php echo h(number_format($ItemBill['grand_total'], 2, '.', ','));?></td>
                                           <td style="font-size: medium">
                                               <?php 
                                                    if($ItemBill['order_status_id'] === '1'){
                                                        echo '<button title="1" value="'.$ItemBill['order_id'].'" class="btn btn-success btn-xs order_status_edit">'
                                                            . '<i class="fa fa-check-square-o fa-1x"></i><span class="label label-success">Paid</span></button>';
                                                    }else{
                                                        echo '<button title="2" value="'.$ItemBill['order_id'].'" class="btn btn-danger  btn-xs order_status_edit">'
                                                            . '<i class="fa fa-times-circle-o fa-1x"></i><span class="label label-danger">Not Paid</span></button>';
                                                    }
                                                ?>
                                           </td>
                                           <td>
                                               <?php
                                                $encrypted_id = $Encryption->encode($ItemBill['student_id'].'/'.$ItemBill['academic_term_id']);
                                               ?>
                                               <a target="__blank" href="<?php echo DOMAIN_NAME ?>/items/view_stdfees/<?php echo $encrypted_id; ?>" class="btn-link btn-primary">
                                                   Proceed
                                                </a>  
                                           </td>
                                        </tr>
                                    <?php endforeach; ?>
                                   </tbody>
                                   <tfoot>
                                     <tr>
                                      <th>#</th>
                                      <th>ID. No</th>
                                      <th>Student Name</th>
                                      <th>Student Status</th>
                                      <th>Sponsor Name</th>
                                      <th>Amount (&#8358;)</th>
                                      <th>Edit Status</th>
                                      <th>Details</th>
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
                    </div> <!-- /panel body --> 
               </div> <!-- /panel -->
            </div>
        </div>
    </div>
 </div> <!-- /col-md-12 -->
 <?php
    //on click of Manage Students link... activate the link
    echo $this->Js->buffer('
        setTabActive("[href=\"'.DOMAIN_NAME.'/items/index#process_fees\"]", 0);
    ');
?> 
 