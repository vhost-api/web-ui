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

function pretty_api_error(code, msg) {
	var result = {};
	switch(parseInt(code)) {
		case 1003:
			result['msg'] = 'Insufficient permission or Quota exhausted.';
			result['visible'] = true;
			break;
		case 1006:
			result['msg'] = null;
			result['visible'] = false;
			break;
		default:
			result['msg'] = msg;
			result['visible'] = true;
	}
	return result;
}

function delete_record(endpoint, id) {
	// build some stuff based on parameters
	var target = '/' + endpoint + '/' + id + '/delete?ajax=1';
	var row_selector = '#vhapi-' + endpoint.replace('/', '-') + '-' + id;

	// initialize variable
	var fadeout_delay = 3000;
	var result_status = '';
	var result_message = '';
	var rand_id = Math.random().toString(36).replace(/[^a-z]+/g, '').substr(0, 8);
	var table = $('#DataTables_Table_0').DataTable();
	var timer;

	// run the ajax
	$.ajax(target, {
		method: 'POST',
		success: function(data) {
			var result_hash = JSON.parse(data);
			result_status = result_hash['status'];
			result_message = result_hash['msg'];
		},
		error: function(xhr, status, error) {
			var result_hash = JSON.parse(xhr['responseText']);
			result_status = result_hash['status'];
			result_message = result_hash['msg'];
			// log additional info
			console.log(xhr);
			console.log(status);
			console.log(error);
		},
		complete: function(_xhr, _status) {
			$('#modal_delete').modal('toggle');

			// create the flash message element
			var flash_msg = document.createElement('div');
			flash_msg.setAttribute('id', 'ajax_flash-' + rand_id);
			flash_msg.setAttribute('role', 'alert');
			flash_msg.className = 'ajax_flash alert fade';

			// assign bootstrap alert class based on result_status
			if(result_status === 'success') {
				flash_msg.className += ' alert-success';

				// FIXME: TODO: special case with DKIM/DkimSigning
				/*----------------------------------------------------------*/
				/* due to relational contraints we need to also remove
				 * all DkimSigning records assigned to a DKIM record, when
				 * that DKIM record is deleted
				 */
				if( /^#vhapi-mail-dkim-/.test(row_selector) ) {
					var dkimsgn_table = $('#DataTables_Table_1').DataTable();
					var needs_redraw = false;
					// find matching DkimSigning records in the DkimSigning table
					$('[id^=vhapi-mail-dkimsigning-]').each(function(row) {
						if( id === parseInt($(this).children()[5].innerHTML) ){
							needs_redraw = true;
							dkimsgn_table.row($(this)).remove();
						}
					});
					if( needs_redraw ) dkimsgn_table.draw();
				}

				// remove the row from the table
				table.row($(row_selector)).remove();

				// redraw the datatable
				table.draw();
			} else {
				flash_msg.className += ' alert-danger';
				// increase fadeout delay for error messages
				fadeout_delay = 10000;
			}

			// flash message title
			var alert_header = document.createElement('h4');
			alert_header.textContent = result_status;
			flash_msg.appendChild(alert_header);

			// flash message body
			var alert_message = document.createElement('p');
			alert_message.textContent = result_message;
			flash_msg.appendChild(alert_message);

			// add flash message to the wrapper
			document.getElementById('alert-wrapper').appendChild(flash_msg);

			// fade-in the flash message
			$('#ajax_flash-' + rand_id).addClass("in");
			window.scrollTo(0, 0);

			// remove it after fadeout_delay ms
			timer = setTimeout(function() {
				$('#ajax_flash-' + rand_id).fadeOut('slow', function() {
					$(this).remove();
				});
			}, fadeout_delay);

			// clicking the message should remove it
			$('#ajax_flash-' + rand_id).click(function() {
				clearTimeout(timer);
				$(this).fadeOut('slow', function() {
					$(this).remove();
				});
			});
		}
	});
	return false;
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

	// use ajax for delete buttons
	$('a.item-delete').click(function(event) {
		event.preventDefault();
		event.stopPropagation();

		var target = this.getAttribute('href') + '?ajax=1';

		$.ajax(target, {
			success: function(data) {
				var parser = new DOMParser();
				var element = parser.parseFromString(data, 'text/html');
				var dialog_id = element.body.firstChild.getAttribute('id');
				$('#' + dialog_id).remove();
				$('BODY').append(element.body.innerHTML);
				$('#' + dialog_id).modal();
			},
			error: function(xhr, status, error) {
				console.log(xhr);
				console.log(status);
				console.log(error);
			}
		});

		return false;
	});

	// use ajax for submit buttons
	$('form :submit').click(function(event) {
		event.preventDefault();
		event.stopPropagation();

		// initialize variable
		var fadeout_delay = 3000;
		var r_status = '', r_msg = '', r_err, r_err_id = 0;
		var rand_id = Math.random().toString(36).replace(/[^a-z]+/g, '').substr(0, 8);
		var form = $(this).parents('form');
		var form_action = form.attr('action') + '?ajax=1';
		var form_method = form.attr('method');
		var timer;
		var alert_header = '', alert_message = '', alert_errors = '';
		var redirect;

		$.ajax({
			beforeSend: function() {
				// disable all form input
				form.find('input').attr('disabled', 'disabled');
				form.find('button').attr('disabled', 'disabled');
				form.find('select').attr('disabled', 'disabled');
			},
			url: form_action,
			method: form_method,
			data: form.serialize(),
			success: function(data) {
				var result_hash = JSON.parse(data);
				r_status = result_hash['status'];
				r_msg = result_hash['msg'];
				redirect = result_hash['redirect'];

				// create the flash message element
				var flash_msg = document.createElement('div');
				flash_msg.setAttribute('id', 'ajax_flash-' + rand_id);
				flash_msg.setAttribute('role', 'alert');
				flash_msg.className = 'ajax_flash alert fade';

				// flash message title
				alert_header = document.createElement('h4');
				alert_header.textContent = r_status;
				flash_msg.appendChild(alert_header);

				// log api return code, no need to show to the user
				console.log('api msg:', r_msg);

				// assign bootstrap alert class based on r_status
				if(r_status === 'success') {
					flash_msg.className += ' alert-success';
					flash_msg.appendChild(document.createElement('hr'));
					var msg = document.createElement('p');
					msg.textContent = r_msg;
					flash_msg.appendChild(msg);
					var redirect_hint = document.createElement('p');
					redirect_hint.textContent = 'Your are being redirected in ' + +Math.round(fadeout_delay/1000) + ' seconds...';
					flash_msg.appendChild(redirect_hint);
				} else {
					flash_msg.className += ' alert-danger';

					r_err_id = parseInt(result_hash['error_id']);
					r_err = result_hash['errors'];

					var pretty_error = pretty_api_error(r_err_id, r_msg);
					if( pretty_error['visible'] ) {
						flash_msg.appendChild(document.createElement('hr'));
						var err_code_p = document.createElement('p');
						err_code_p.textContent = pretty_error['msg'];
						flash_msg.appendChild(err_code_p);
					}

					// check if there are any validation errors
					if( 'validation' in r_err ) {
						flash_msg.appendChild(document.createElement('hr'));

						var validation_errors_heading = document.createElement('h5');
						validation_errors_heading.textContent = 'Validation Errors:'
						flash_msg.appendChild(validation_errors_heading);

						var val_errs = r_err['validation'];
						// loop through fields
						for (var i in val_errs) {
							var field = val_errs[i]['field'];
							var errors = val_errs[i]['errors'];
							var f = document.createElement('strong');
							f.textContent = field;
							flash_msg.appendChild(f);

							var e_ul = document.createElement('ul');

							// loop through errors for this field
							for (var j in errors) {
								var li = document.createElement('li');
								li.textContent = errors[j];
								e_ul.appendChild(li);
							}
							flash_msg.appendChild(e_ul);
						}

						// remove this property as we are done processing it
						delete r_err['validation'];
					}

					// show any remaining errors, that are not validation errors
					if( Object.keys(r_err).length > 0 ) {
						flash_msg.appendChild(document.createElement('hr'));

						alert_errors_heading = document.createElement('h5');
						alert_errors_heading.textContent = 'Other Errors:'
						flash_msg.appendChild(alert_errors_heading);

						alert_errors = document.createElement('p');
						alert_errors.textContent = JSON.stringify(r_err);
						flash_msg.appendChild(alert_errors);
					}

					// re-enable all form input
					form.find('input').removeAttr('disabled');
					form.find('button').removeAttr('disabled');
					form.find('select').removeAttr('disabled');
				}

				// add flash message to the wrapper
				document.getElementById('alert-wrapper').appendChild(flash_msg);

				// fade-in the flash message
				$('#ajax_flash-' + rand_id).addClass("in");
				window.scrollTo(0, 0);

				// remove it after fadeout_delay ms
				if(r_status === 'success') {
					timer = setTimeout(function() {
						$('#ajax_flash-' + rand_id).fadeOut('slow', function() {
							$(this).remove();
							window.location.replace(redirect);
						});
					}, fadeout_delay);
				}

				// clicking the message should remove it
				$('#ajax_flash-' + rand_id).click(function() {
					clearTimeout(timer);
					$(this).fadeOut('slow', function() {
						$(this).remove();
					});
				});
			},
			error: function(xhr, status, error) {
				console.log(xhr);
				console.log(status);
				console.log(error);
			}
		});

		return false;
	});
});
