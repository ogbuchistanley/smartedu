<?php echo $this->Html->script("../web/js/custom.home.js", FALSE);?>
<?php 
    App::uses('Encryption', 'Utility'); 
    $Encryption = new Encryption();
?>
<?php $Item = ClassRegistry::init('Item'); ?>
<section id="content">
    <div class="container">
        <div class="row">
            <div class="span12">
                <div class="info-box  bg-info  text-white">
                    <div class="info-icon bg-info-dark">
                        <i class="fa fa-money fa-4x"></i>
                    </div>
                    <div class="info-details">
                        <h4>View Students Terminal School Fees Charges </h4>
                    </div>
                </div>
            </div>
        </div>
        <div class="row">
            <!-- Panel with Tables -->            
            <div class="span9">
                <div class="panel">
                    <div class="panel-body">
                        <div class="panel panel-primary">
                        <div class="panel-heading panel-title  text-white">Student Details</div>
                            <table class="table table-bordered table-hover table-striped">
                                <?php
                                    if(!empty($ItemBills['ItemBill'])):   
                                        $Info = $ItemBills['ItemBill'];
                                        $Info = array_shift($Info);
                                ?>
                                    <tbody>
                                        <tr>
                                            <th>Student Name</th>
                                            <td>
                                                <?php $encrypted_student_id = $Encryption->encode($Info['student_id']); ?>
                                                <a target="__blank" href="<?php echo DOMAIN_NAME ?>/home/record/<?php echo $encrypted_student_id; ?>" class="btn btn-primary btn-medium">
                                                    <?php echo $Info['student_name'];?>
                                                </a>                                                
                                            </td>
                                            <td rowspan="4">
                                                <img class="img-rounded" data-src="holder.js/140x140" src="<?php echo DOMAIN_NAME ?>/img/uploads/<?php echo ($Info['image_url']) ? $Info['image_url'] : '';?>" style='width: 140px; height: 140px;'/>
                                            </td>
                                        </tr>
                                        <tr>
                                            <th>Student Status</th>
                                          <td style="font-size: medium">
                                              <?php 
                                                if(h($Info['student_status_id']) === '1' || h($Info['student_status_id']) === '2'){
                                                    echo '<span class="label label-success"> '.$Info['student_status'].'</span>';
                                                }else if(h($Info['student_status_id']) === '3'){
                                                    echo '<span class="label label-warning"> '.$Info['student_status'].'</span>';
                                                }else{
                                                    echo '<span class="label label-danger"> '.$Info['student_status'].'</span>';
                                                }
                                              ?>
                                          </td>                                 
                                        </tr>
                                        <tr>
                                            <th>Parent Name</th>
                                            <td><?php echo $Info['salutation_name'], ' ', $Info['sponsor_name'];?></td>
                                        </tr>
                                        <tr>
                                          <th>Payment Status</th>
                                          <td style="font-size: medium">
                                              <?php 
                                                if(h($Info['order_status_id']) === '1'){
                                                    echo '<span class="label label-success">Paid</span>';
                                                }else{
                                                    echo '<span class="label label-danger">Not Paid</span>';
                                                }
                                              ?>
                                          </td>
                                        </tr>
                                        <tr>
                                          <th>Class Room</th>
                                          <td><?php echo $Info['class_name'];?></td>
                                          <th>Passport</th>
                                        </tr>
                                        <tr>
                                          <th>Academic Term</th>
                                          <td colspan="2"><?php echo $Info['academic_term'];?></td>
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
            <div class="span10">
               <div class="panel">
                    <div class="panel-body">
                        <div class="panel panel-info">
                            <div class="panel-heading panel-title  text-white">Terminal Items Charges Summary</div>
                            <div style="overflow-x: scroll" class="panel-body">
                                <?php if(!empty($ItemBills['ItemBill'])):?>
                                <table  class="table table-bordered table-hover table-striped display">
                                    <thead>
                                     <tr>
                                      <th>#</th>
                                      <th>Items</th>
                                      <th>Amount (&#8358;)</th>
                                      <th>SubTotal (&#8358;)</th>
                                    </tr>
                                  </thead>
                                  <tbody>
                                    <?php $gTotal=0; $i=1; ?>
                                    <?php foreach ($ItemBills['ItemBill'] as $ItemBill): ?>
                                        <tr>
                                           <td><?php echo $i++;?></td>
                                           <td><?php echo h($ItemBill['item_name']);?></td>
                                           <td><?php echo h($ItemBill['price']);?></td>
                                           <td><?php $gTotal += $ItemBill['subtotal'];  echo h($ItemBill['subtotal']);?></td>
                                        </tr>
                                    <?php endforeach; ?>
                                   </tbody>
                                   <tfoot>
                                        <tr>
                                            <th colspan="3">Grand Total</th>
                                            <th>
                                                <span class="label label-info" style="font-size: medium">&#8358; <?php echo number_format($gTotal, 2, '.', ',') ;?></span>
                                            </th>
                                        </tr>
                                        <tr>
                                            <th colspan="4"><span class="label label-info" style="font-size: medium">
                                                <?php 
                                                    try {
                                                        echo $Item->convert_number_to_words($gTotal), ' Naria Only';
                                                    } catch(Exception $e) {
                                                        echo $e->getMessage();
                                                    }
                                                ?></span>
                                            </th>
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
    </div><!-- /col-md-12 -->
</section>
<!-- End Content-->