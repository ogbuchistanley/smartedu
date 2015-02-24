<?php echo $this->Html->script("../web/js/custom.home.js", FALSE);?>
<?php $term_id = ClassRegistry::init('AcademicTerm'); ?>

<!-- Start Content-->
<section id="content">
    <div class="container">
        <div class="row">

            <div class="span6">

                <h4 class="thin"><strong>Search</strong> Form</h4>
                <p></p>
                <!-- Contact Form-->
                <?php 
                    //Creates The Form
                    echo $this->Form->create('SearchStudent', array(
                            'class' => 'validateform margintop10',
                            'id' => 'search_student_sponsor_form'
                        )
                    );     
                ?>
                    <div class="row">
                        <div class="span5 field">
                            <label for="academic_year_id">Academic Years</label>
                            <?php 
                                echo $this->Form->input('academic_year_id', array(
                                        'div' => false,
                                        'label' => false,
                                        'id' => 'academic_year_id',
                                        'required' => "required",
                                        'selected' => $term_id->getCurrentYearID(),
                                        'options' => $AcademicYears,
                                        'empty' => '(Select Academic Year)'
                                    )
                                ); 
                            ?>

                        </div>
                        <div class="span5 field"></div>
                        <div class="span5 field">
                            <div class="validation"></div>
                            <label for="academic_term_id">Academic Terms</label>
                            <select name="data[SearchStudent][academic_term_id]" id="academic_term_id" required="required">
                                <option value="<?php echo $term_id->getCurrentTermID();?>"><?php echo $term_id->getCurrentTermName();?></option>

                            </select>

                        </div>
                        <div class="span8 margintop10 field">
                            <div class="validation"></div>
                            <p>
                                <button class="btn btn-theme margintop10 pull-left" type="submit">Search</button>
                            </p>
                        </div>
                    </div>
                </form>
                <!-- End contact form-->
            </div>

            <!-- Contact sidebar-->
            <div class="span6">
                <div id="msg_box"> </div>
            </div>
            <!-- End contact sidebar-->
        </div>
        
        <div class="row">
            <div class="col-md-12">
                <div style="overflow-x: scroll" class="panel-body">
                    <table  class="table table-bordered table-hover table-striped display" id="search_students_table" >

                    </table>
                </div> 
            </div>
        </div>
    </div>
</section>
<!-- End Content-->

<?php
// OnChange of Academic Year Get Academic Term
    $this->Utility->getDependentListBox('#academic_year_id', '#academic_term_id', 'academic_terms', 'ajax_get_terms', 'SearchStudent');
?>