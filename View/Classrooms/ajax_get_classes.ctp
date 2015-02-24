<option value="">  (Select Class Room)  </option>
<?php foreach ($classes as $key => $value): ?>
<option value="<?php echo $key; ?>"><?php echo $value; ?></option>
<?php endforeach; ?>