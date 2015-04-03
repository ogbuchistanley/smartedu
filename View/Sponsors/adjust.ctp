<?php echo $this->Html->script("../app/jquery/custom.sponsor.js", FALSE);?>
<?php 
    App::uses('Encryption', 'Utility'); 
    $Encryption = new Encryption();

?>
    <div class="row">
        <?php
        $errors = $this->validationErrors['Sponsor'];
        $flatErrors = Set::flatten($errors);
        $flatErrors2 = $flatErrors;
        $test = array();
        foreach($flatErrors as $key => $value){
            $test[] = $value;
        }
        if(!empty($test[count($test) - 1])) {
            echo '<div class="alert alert-danger">';
            echo '<ul>';
            foreach($flatErrors2 as $key => $value) {
                echo (!empty($value)) ? '<li>'.$value.'</li>' : false;
            }
            echo '</ul>';
            echo '</div>';
        }
        ?>
    </div>
    <div class="col-md-12">
        <div class="panel">
            <!-- Info Boxes -->
            <!--div class="row">
                <div class="col-md-12">
                    <div class="info-box  bg-info  text-white">
                        <div class="info-icon bg-info-dark">
                            <i class="fa fa-edit fa-4x"></i>
                        </div>
                        <div class="info-details">
                            <h4>Please fill the form properly and modify accurately...</h4>
                        </div>
                    </div>
                </div>
            </div>
            <!-- / Info Boxes -->
            <div class="panel-heading text-primary">
                <h3 class="panel-title">
                    <i class="fa fa-pencil-square"></i>
                   Adjust Parents' Information <small class="text-danger"> <i class="fa fa-warning"></i>Note All Fields With * Need To Be Filled</small>
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
                        <?php
                            //$sponsor = $this->request->data;
                            $encrypted_sponsor_id = $Encryption->encode($sponsor['Sponsor']['sponsor_id']);
                            //Creates The Form
                            echo $this->Form->create('Sponsor', array(
                                    'url' => '/sponsors/adjust/'.$encrypted_sponsor_id,
                                    'class' => 'form-horizontal cascde-forms',
                                    'novalidate' => 'novalidate',
                                    'id' => 'sponsor_form',
                                    'type' => 'file'
                                )
                            );     
                        ?>
                        <div class="form-group">
                            <?php echo $this->Form->input('sponsor_id'); ?>
                        </div>
                        <!--form class="form-horizontal cascde-forms" method="post" action="#" name="basic_validate" id="basic_validate" novalidate="novalidate"-->
                            <br/>
                            <div class="form-group">
                                <label class="col-lg-2 col-md-3 control-label" for="salutation_id">Title <small class="text-danger"> * </small></label>
                                <div class="col-lg-7 col-md-9">
                                    <?php 
                                        echo $this->Form->input('salutation_id', array(
                                                'div' => false,
                                                'label' => false,
                                                'class' => 'form-control',
                                                'id' => 'salutation_id',
                                                'options' => $Salutations,
                                                'empty' => '(Select Parent\'s Title)'
                                            )
                                        ); 
                                    ?>
                               </div>
                            </div>
                            <div class="form-group">
                              <label class="col-lg-2 col-md-3 control-label" for="first_name">Surname <small class="text-danger"> * </small></label>
                              <div class="col-lg-7 col-md-9">
                               <input type="text" class="form-control form-cascade-control input-small" name="data[Sponsor][first_name]" id="other_name"
                                  value="<?php echo (empty($sponsor['Sponsor']['first_name'])) ? '' : $sponsor['Sponsor']['first_name']?>" placeholder="Type Parent's Surname">
                             </div>
                            </div>
                            <div class="form-group">
                                <label class="col-lg-2 col-md-3 control-label" for="other_name">First Name <small class="text-danger"> * </small></label>
                                <div class="col-lg-7 col-md-9">
                                    <input type="text" class="form-control form-cascade-control input-small" value="<?php echo $sponsor['Sponsor']['other_name']?>"
                                 name="data[Sponsor][other_name]" id="other_name" placeholder="Type Parent's first name" required>
                               </div>
                            </div>
                            <div class="form-group">
                                <label class="col-lg-2 col-md-3 control-label" for="email">Email</label>
                              <div class="col-lg-7 col-md-9">
                                <input type="email" class="form-control form-cascade-control input-small" name="data[Sponsor][email]" 
                                    value="<?php echo (empty($sponsor['Sponsor']['email'])) ? '' : $sponsor['Sponsor']['email'];?>" id="email" placeholder="Parent's e-mail">
                              </div>
                            </div>
                            <div class="form-group">
                                <label class="col-lg-2 col-md-3 control-label" for="mobile_number1">Mobile Number 1 <small class="text-danger"> * </small></label>
                              <div class="col-lg-7 col-md-9">
                                    <input type="text" class="form-control form-cascade-control input-small" name="data[Sponsor][mobile_number1]"
                                    value="<?php echo $sponsor['Sponsor']['mobile_number1']?>" id="mobile_number1" placeholder="Parent's Mobile number One" required>
                              </div>
                            </div>
                            <div class="form-group">
                                <label class="col-lg-2 col-md-3 control-label" for="mobile_number2">Mobile Number 2</label>
                                <div class="col-lg-7 col-md-9">
                                    <input type="text" class="form-control form-cascade-control input-small" name="data[Sponsor][mobile_number2]"
                                    value="<?php echo ($sponsor['Sponsor']['mobile_number2']) ? $sponsor['Sponsor']['mobile_number2'] : ""?>" id="mobile_number2" placeholder="Parent's Mobile number Two if any">
                                </div>
                            </div>
                            <div class="form-group">
                                <label class="col-lg-2 col-md-3 control-label" for="contact_address">Contact Address</label>
                                <div class="col-lg-7 col-md-9">
                                    <textarea class="form-control form-cascade-control input-small" name="data[Sponsor][contact_address]" 
                                    id="contact_address" placeholder="Parent's Contact Address" required><?php echo $sponsor['Sponsor']['contact_address']?></textarea>
                                </div>
                            </div>
                            <!--div class="form-group">
                                <label class="col-lg-2 col-md-3 control-label" for="sponsorship_type">Sponsorship Type</label>
                                <div class="col-lg-7 col-md-9">
                                    <?php 
//                                        echo $this->Form->input('sponsorship_type_id', array(
//                                                'div' => false,
//                                                'label' => false,
//                                                'class' => 'form-control',
//                                                'id' => 'sponsorship_type_id',
//                                                'options' => $SponsorshipTypes,
//                                                'empty' => '(Select Parent\'s Sponsorship Type)'
//                                            )
//                                        ); 
                                    ?>
                                </div>
                            </div-->
                            <div class="form-group">
                                <label class="col-lg-2 col-md-3 control-label" for="country_id">Nationality</label>
                                <div class="col-lg-7 col-md-9">
                                    <?php 
                                        echo $this->Form->input('country_id', array(
                                                'div' => false,
                                                'label' => false,
                                                'class' => 'form-control',
                                                'id' => 'country_id',
                                                'required' => 'required',
                                                'options' => $Countrys,
                                                'empty' => '(Select Parent\'s Country)'
                                            )
                                        ); 
                                    ?>
                                </div>
                            </div>
                            <div id="state_lga_div">
                                <div class="form-group">
                                    <label for="state_id" class="col-lg-2 col-md-3 control-label">State of origin </label>
                                    <div class="col-lg-7 col-md-9">
                                        <?php 
                                            echo $this->Form->input('state_id', array(
                                                    'div' => false,
                                                    'label' => false,
                                                    'class' => 'form-control',
                                                    'id' => 'state_id',
                                                    'options' => $States,
                                                    'empty' => '(Select Parent\'s State)'
                                                )
                                            ); 
                                        ?>
                                    </div>
                                 </div>
                                 <div class="form-group">
                                    <label for="local_govt_id" class="col-lg-2 col-md-3 control-label">Local Govt. </label>
                                    <div class="col-lg-7 col-md-9">
                                        <select class="form-control" name="data[Sponsor][local_govt_id]" id="local_govt_id">
                                            <?php 
                                                if(!empty($sponsor['Sponsor']['local_govt_id'])) { 
                                                    echo '<option value="'.$sponsor['Sponsor']['local_govt_id'].'">'.$sponsor['LocalGovt']['local_govt_name'].'</option>';
                                                } else { ?>
                                                    <option value="">  (Select Parent's L.G.A)  </option>
                                            <?php } ?>
                                         </select>
                                    </div>
                                 </div>
                            </div>
                            <div class="form-group">
                                <label class="col-lg-2 col-md-3 control-label" for="occupation">Occupation </label>
                                <div class="col-lg-7 col-md-9">
                                    <input type="text" class="form-control form-cascade-control input-small" name="data[Sponsor][occupation]" 
                                    value="<?php echo $sponsor['Sponsor']['occupation']?>" id="occupation" placeholder="Parent's Occupation" required>
                                </div>
                            </div>
                            <div class="form-group">
                                <label class="col-lg-2 col-md-3 control-label" for="company_name">Company name</label>
                                <div class="col-lg-7 col-md-9">
                                    <input type="text" class="form-control form-cascade-control input-small" name="data[Sponsor][company_name]" 
                                    value="<?php echo ($sponsor['Sponsor']['company_name']) ? $sponsor['Sponsor']['company_name'] : ""?>" id="company_name" placeholder="Parent's Company name if any" required>
                                </div>
                            </div>
                            <div class="form-group">
                                <label class="col-lg-2 col-md-3 control-label" for="company_address">Office Address</label>
                                <div class="col-lg-7 col-md-9">
                                    <textarea class="form-control form-cascade-control input-small" name="data[Sponsor][company_address]" 
                                    id="company_address" placeholder="Sponsor's Company Address if any" required><?php echo ($sponsor['Sponsor']['company_address']) ? $sponsor['Sponsor']['company_address'] : ""?></textarea>
                                </div>
                            </div>
                            <div class="form-group">
                                <label for="image_url" class="col-lg-2 col-md-3 control-label">&nbsp;&nbsp;</label>
                                <div class="col-lg-7 col-md-9">
                                    <span class="btn btn-info fileinput-button" ng-class="{disabled: disabled}">
                                        <i class="glyphicon glyphicon-plus"></i>
                                        <span>Browse File...</span>
                                        <input ng-disabled="disabled" value="<?php echo $sponsor['Sponsor']['image_url']?>" type="file" name="data[Sponsor][image_url]" id="image_url" onChange="readURL(this);" required="required" /><br>
                                        <img data-src="holder.js/140x140" class="img-rounded" id="img_prev" src="<?php echo DOMAIN_NAME ?>/img/uploads/<?php echo ($sponsor['Sponsor']['image_url']) ? $sponsor['Sponsor']['image_url'] : 'avatar.jpg';?>" style="width: 140px; height: 140px;"/>
                                    </span>
                                    <div id="image_error"></div>
                                </div>
                            </div>
                            <div class="form-group">
                              <label class="col-lg-2 col-md-3 control-label">&nbsp;&nbsp;</label>
                              <div class="col-lg-7 col-md-9">
                                  <button type="submit" id="register_sponsor_btn" class="btn btn-info">Update Record</button>
                              </div>
                            </div> 
                        </form>
                    </div>
                </div>
            </div>
        </div>	
    </div>
<?php
    //on click of Edit Parent Record link... activate the link
    echo $this->Js->buffer('
        setTabActive("[href=\"'.DOMAIN_NAME.'/sponsors/\"]", 0);
    ');
?> 
<?php
    // OnChange Of States Get Local Govt
//    $this->Utility->getDependentListBox('#state_id', '#local_govt_id', 'local_govts', 'ajax_get_local_govt', 'Sponsor');
?>