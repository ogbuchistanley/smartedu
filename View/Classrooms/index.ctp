<?php echo $this->Html->script("../app/jquery/custom.classroom.js", FALSE);?>
<?php $term_id = ClassRegistry::init('AcademicTerm'); ?>

<div class="col-md-12">
    <div class="panel">
        <!-- Info Boxes -->
        <!--div class="row">
            <div class="col-md-12">
                <div class="info-box  bg-info  text-white">
                    <div class="info-icon bg-info-dark">
                        <i class="fa fa-arrow-circle-o-left fa-4x"></i>
                        <i class="fa fa-arrow-circle-o-right fa-4x"></i>
                    </div> 
                    <div class="info-details">
                        <h4>Manage and View Students in class room</h4>
                    </div> 
                </div>
            </div>
        </div>
        <!-- / Info Boxes -->
        <div class="panel-heading text-primary">
            <h3 class="panel-title">                
               <i class="fa fa-home"></i>
               Students Class Room Management
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
                        <li class="active"><a href="<?php echo DOMAIN_NAME ?>/classrooms/index#assign_students" data-toggle="tab">
                            <b><i class="fa fa-plus-circle"></i> Add or <i class="fa fa-minus-square"></i> Remove Student in class</b></a>
                        </li>
                        <li><a href="<?php echo DOMAIN_NAME ?>/classrooms/index#search_students" data-toggle="tab">
                            <b><i class="fa fa-search-plus"></i> Search Students by class</b></a>
                        </li>
                        <li><a href="<?php echo DOMAIN_NAME ?>/classrooms/index#assign_head_tutor" data-toggle="tab">
                            <b><i class="fa fa-plus-square"></i> Assign Class Teacher</b></a>
                        </li>
                    </ul>
                    <div id="myTabContent" class="tab-content">
                        <div class="tab-pane fade in active" id="assign_students"><br>
                            <div class="col-md-6">
                                <div class="panel panel-cascade">
                                    <div class="panel-body">
                                        <div class="panel panel-default">
                                            <div class="panel-heading">Assigning Students To A Classroom </div> 
                                            <div class="panel-body">
                                                <?php 
                                                    //Creates The Form
                                                    echo $this->Form->create('StudentsClass', array(
                                                            'action' => 'search',
                                                            'class' => 'form-horizontal',
                                                            'id' => 'search_form'
                                                        )
                                                    );     
                                                ?>
                                                    <div class="form-group">
                                                        <label for="classlevel_id" class="col-sm-4 control-label">Class Level</label>
                                                        <div class="col-sm-8">
                                                            <?php 
                                                                echo $this->Form->input('classlevel_id', array(
                                                                        'div' => false,
                                                                        'label' => false,
                                                                        'class' => 'form-control',
                                                                        'id' => 'classlevel_id',
                                                                         'required' => "required",
                                                                        'options' => $Classlevels,
                                                                        'empty' => '(Select Classlevel)'
                                                                    )
                                                                ); 
                                                            ?>
                                                        </div>
                                                    </div>
                                                    <div class="form-group">
                                                        <label for="class_id" class="col-sm-4 control-label">Class Room</label>
                                                        <div class="col-sm-8">
                                                            <select class="form-control" name="data[StudentsClass][class_id]" id="class_id" required="required">
                                                                <option value="">  (Select Class Room)  </option>

                                                            </select>
                                                        </div>
                                                    </div>
                                                    <div class="form-group">
                                                        <div class="col-sm-offset-2 col-sm-10">
                                                            <input type="hidden" value="" name="hidden_class_id" id="hidden_class_id">
                                                            <button type="submit" class="btn btn-info">Search</button>
                                                        </div>
                                                    </div>
                                                </form>					
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                            <div class="col-md-6" id="msg_box">     </div>
                            <div class="col-md-12">
                                <div style="overflow-x: scroll"  class="hide" id="students_table_div">
                                    <table class="table display">
                                        <tr>
                                            <td>
                                                <table  class="table table-bordered table-hover table-striped display" id="available_students" >

                                                </table>
                                            </td>
                                            <td>
                                                <table class="table table-bordered table-hover table-striped display"  id="assigned_students">

                                                </table>
                                            </td>
                                        </tr>
                                    </table>
                                </div>
                            </div>
                        </div>
                        <div class="tab-pane fade" id="search_students"><br>
                            <div class="col-md-6">
                                <div class="panel panel-cascade">
                                    <div class="panel-body">
                                        <div class="panel panel-default">
                                            <div class="panel-heading">Search For Students in a Classroom or Class Level </div> 
                                            <div class="panel-body">
                                                <?php 
                                                    //Creates The Form
                                                    echo $this->Form->create('StudentsClassAll', array(
                                                            'action' => 'search_all',
                                                            'class' => 'form-horizontal',
                                                            'id' => 'search_form_all'
                                                        )
                                                    );     
                                                ?>
                                                    <div class="form-group">
                                                        <label for="academic_year_id" class="col-sm-4 control-label">Academic Year</label>
                                                        <div class="col-sm-8">
                                                            <?php                                                                 
                                                                echo $this->Form->input('academic_year_id', array(
                                                                        'div' => false,
                                                                        'label' => false,
                                                                        'class' => 'form-control',
                                                                        'id' => 'academic_year_id',
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
                                                        <label for="classlevel_id_all" class="col-sm-4 control-label">Class Level</label>
                                                        <div class="col-sm-8">
                                                            <?php                                                         
                                                                echo $this->Form->input('classlevel_id_all', array(
                                                                        'div' => false,
                                                                        'label' => false,
                                                                        'class' => 'form-control',
                                                                        'id' => 'classlevel_id_all',
                                                                        'required' => "required",
                                                                        'options' => $Classlevels,
                                                                        'empty' => '(Select Classlevel)'
                                                                    )
                                                                ); 
                                                            ?>
                                                        </div>
                                                    </div>
                                                    <div class="form-group">
                                                        <label for="class_id_all" class="col-sm-4 control-label">Class Room</label>
                                                        <div class="col-sm-8">
                                                            <select class="form-control" name="data[StudentsClassAll][class_id_all]" id="class_id_all">
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
                            <div class="col-md-6" id="msg_box2"> </div>
                            <div class="col-md-10">
                                <div style="overflow-x: scroll" class="panel-body">
                                    <table  class="table table-bordered table-hover table-striped display" id="students_table_div_all" >
                                        
                                    </table>
                                </div> <!-- /panel body -->
                            </div>
                        </div>
                        <div class="tab-pane fade in" id="assign_head_tutor"><br>
                            <div class="col-md-6">
                                <div class="panel panel-cascade">
                                    <div class="panel-body">
                                        <div class="panel panel-default">
                                            <div class="panel-heading">Assigning Classroom To Head Tutor (Master / Mistress) </div> 
                                            <div class="panel-body">
                                                <?php 
                                                    //Creates The Form
                                                    echo $this->Form->create('TeachersClass', array(
                                                            'class' => 'form-horizontal',
                                                            'id' => 'search_classes_form'
                                                        )
                                                    );     
                                                ?>
                                                    <div class="form-group">
                                                        <label for="academic_year_id_search" class="col-sm-4 control-label">Academic Year</label>
                                                        <div class="col-sm-8">
                                                            <?php 
                                                                echo $this->Form->input('academic_year_id_search', array(
                                                                        'div' => false,
                                                                        'label' => false,
                                                                        'class' => 'form-control',
                                                                        'id' => 'academic_year_id_search',
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
                                                        <label for="classlevel_id_search" class="col-sm-4 control-label">Class Level</label>
                                                        <div class="col-sm-8">
                                                            <?php                                                         
                                                                echo $this->Form->input('classlevel_id_search', array(
                                                                        'div' => false,
                                                                        'label' => false,
                                                                        'class' => 'form-control',
                                                                        'id' => 'classlevel_id_search',
                                                                        'required' => "required",
                                                                        'options' => $Classlevels,
                                                                        'empty' => '(Select Classlevel)'
                                                                    )
                                                                ); 
                                                            ?>
                                                        </div>
                                                    </div>
                                                    <div class="form-group hide">
                                                        <div class="col-sm-8">
                                                            <?php 
                                                                echo $this->Form->input('employee_names', array(
                                                                        'div' => false,
                                                                        'label' => false,
                                                                        'class' => 'form-control',
                                                                        'id' => 'employee_names',
                                                                        'options' => $Employees
                                                                    )
                                                                ); 
                                                            ?>
                                                        </div>
                                                    </div>
                                                    <div class="form-group">
                                                        <div class="col-sm-offset-2 col-sm-10">
                                                            <input type="hidden" value="" name="hidden_class_id" id="hidden_class_id">
                                                            <button type="submit" class="btn btn-info">Search</button>
                                                        </div>
                                                    </div>
                                                </form>					
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                            <div class="col-md-6" id="msg_box3">     </div>
                            <div class="col-md-8">
                                <div style="overflow-x: scroll" class="panel-body">
                                    <table  class="table table-bordered table-hover table-striped display" id="head_tutor_class_table" >
                                        
                                    </table>
                                </div> 
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>	
</div>
<?php
    // OnChange Of Classlevel Get Class Room
//    $this->Utility->getDependentListBox('#classlevel_id', '#class_id', 'classrooms', 'ajax_get_classes', 'StudentsClass');
//    $this->Utility->getDependentListBox('#classlevel_id_all', '#class_id_all', 'classrooms', 'ajax_get_classes', 'StudentsClassAll');
//?>