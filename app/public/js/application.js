function pretty_filesize_index(bytes) {
	var thresh = 1024;
	if(Math.abs(bytes) < thresh) {
		return 0;
	}
	var units = ['B','KiB','MiB','GiB'];
	var u = 0;
	do {
		bytes /= thresh;
		++u;
	} while(Math.abs(bytes) >= thresh && u < units.length - 1);
	return u;
}

function pretty_filesize(bytes) {
	var thresh = 1024;
	if(Math.abs(bytes) < thresh) {
		return bytes;
	}
	var units = ['B','KiB','MiB','GiB'];
	bytes /= (Math.pow(1024, pretty_filesize_index(bytes)));
	return bytes.toFixed(2);
}

$( document ).ready(function() {
	// prettify byte units
	$('input.byte-unit').each(function() {
		input_field = $(this);
		select_field_id = "#" + input_field.attr("name") + "_unit";
		select_field = $(select_field_id);

		input_val = parseInt(input_field.val());
		index = pretty_filesize_index(input_val);
		mult = Math.pow(1024, index);
		value = pretty_filesize(input_val);

		input_field.data('bytes', input_val);

		input_field.val(value);
		select_field.val(mult);
	});

	// initialize multi selects
	$(':input[multiple]:not([id$="_to"])').multiselect({
		search: {
			left: '<input type="text" autocomplete="off" name="q" class="form-control" placeholder="Search..." />',
			right: '<input type="text" autocomplete="off" name="q" class="form-control" placeholder="Search..." />',
		}
	});

	// bind on-change function to byte unit selects
	$('select.byte-unit').change(function() {
		select_field = $(this);
		input_field_id = "#" + select_field.attr("id").replace("_unit", "");
		input_field = $(input_field_id);

		selected = $('#' + select_field.attr('id') + ' option:selected');
		var mult = parseInt(selected.val());
		var value = parseInt(input_field.data('bytes')) / mult;
		if(mult === 1) {
			value = value.toFixed(0);
		} else {
			value = value.toFixed(2);
		}

		input_field.val(value);
	});

	// bind on-change function to byte unit input
	$('input.byte-unit').change(function() {
		input_field = $(this);
		select_field_id = "#" + input_field.attr("name") + "_unit";
		select_field = $(select_field_id);

		selected = $('#' + select_field.attr('id') + ' option:selected');
		var mult = parseInt(selected.val());
		var value = (parseInt(input_field.val()) * mult).toFixed(0);

		input_field.data('bytes', value);
	});

	// setup text input for each footer cell
	$('.data-table tfoot th:not(.no-sort):not(.no-search)').each(function() {
		$(this).html('<input type="text" autocomplete="off" class="form-control table-search" placeholder="..." />');
	});

	// initializa datatables
	$('.data-table').each(function() {
		var table = $(this).DataTable({
			paging: false,
			columnDefs: [
			{ targets: 'no-sort', orderable: false }
			],
			searching: true,
			"sDom": 'lrtip'
		});

		// bind the search
		table.columns().every(function() {
			var that = this;

			$( 'input', this.footer() ).on( 'keyup change', function () {
				if ( that.search() !== this.value ) {
					that
						.search( this.value )
						.draw();
				}
			} );
		} );
	});
});
