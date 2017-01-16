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

function toggle_form_input(active = false, form) {
	if(active) {
		form.find('input').removeAttr('disabled');
		form.find('button').removeAttr('disabled');
		form.find('select').removeAttr('disabled');
	} else {
		form.find('input').attr('disabled', 'disabled');
		form.find('button').attr('disabled', 'disabled');
		form.find('select').attr('disabled', 'disabled');
	}
}

function AjaxResponse(form_origin = false, rand_id, status = '', msg = '', redirect = null, fadeout_delay = 3000, error_id, errors = []) {
	this.form_origin = form_origin;
	this.rand_id = rand_id;
	this.status = status;
	this.msg = msg;
	this.redirect = redirect;
	this.fadeout_delay = fadeout_delay;
	this.error_id = error_id;
	this.errors = errors;

	console.log('api msg:', this.msg);

	this.render = function() {
		var timer;
		var form = $('form');

		var container = document.createElement('div');
		container.setAttribute('id', 'ajax_flash-' + this.rand_id);
		container.setAttribute('role', 'alert');
		container.className = 'ajax_flash alert fade';

		var alert_heading = document.createElement('h4');
		alert_heading.textContent = this.status;
		container.appendChild(alert_heading);

		if(this.status === 'success') {
			document.body.style.cursor = 'wait';
			container.className += ' alert-success';
			container.appendChild(document.createElement('hr'));

			var message = document.createElement('p');
			message.textContent = this.msg;
			container.appendChild(message);

			container.appendChild(document.createElement('br'));
			var redirect_hint = document.createElement('p');
			redirect_hint.textContent = 'You are being redirected in ' + +Math.round(this.fadeout_delay/1000) + ' seconds...';
			container.appendChild(redirect_hint);
		} else {
			container.className += ' alert-danger';

			var errors = this.errors;

			var pretty_error = pretty_api_error(this.error_id, this.msg);
			if( pretty_error['visible'] ) {
				container.appendChild(document.createElement('hr'));
				var error_p = document.createElement('p');
				error_p.textContent = pretty_error['msg'];
				container.appendChild(error_p);
			}

			if(errors) {
				if( 'validation' in errors ) {
					container.appendChild(document.createElement('hr'));

					var heading = document.createElement('h5');
					heading.textContent = 'Validation Errors:';
					container.appendChild(heading);

					var val_errs = errors['validation'];
					for (var i in val_errs) {
						var field = val_errs[i]['field'];
						var f_errors = val_errs[i]['errors'];

						var f = document.createElement('strong');
						f.textContent = field;
						container.appendChild(f);

						var err_ul = document.createElement('ul');

						for (var j in f_errors) {
							var err_li = document.createElement('li');
							err_li.textContent = f_errors[j];
							err_ul.appendChild(err_li);
						}
						container.appendChild(err_ul);
					}
					// remove this property as we are done processing it
					delete errors['validation'];
				}

				// show any remaining errors, that are not validation errors
				if( Object.keys(errors).length > 0 ) {
					container.appendChild(document.createElement('hr'));
					var heading = document.createElement('h5');
					heading.textContent = 'Other Errors:';
					container.appendChild(heading);

					var alert_errors = document.createElement('div');
					for( var err_idx in errors ) {
						var err_p = document.createElement('p');
						err_p.textContent = JSON.stringify(errors[err_idx]);
						alert_errors.appendChild(err_p);
					}
					container.appendChild(alert_errors);
				}
			}


			if(this.form_origin) toggle_form_input(true, form);
			document.body.style.cursor = 'auto';
		}

		// add flash message to the wrapper
		document.getElementById('alert-wrapper').appendChild(container);

		// fade-in the flash message
		$('#ajax_flash-' + this.rand_id).addClass('in');
		window.scrollTo(0, 0);

		// remove success messages after fadeout_delay ms
		if(this.status === 'success') {
			var redirect = this.redirect;
			var rand_id = this.rand_id;
			timer = setTimeout(function() {
				$('#ajax_flash-' + rand_id).fadeOut('slow', function() {
					$(this).remove();
				});
				if(redirect) window.location.replace(redirect);
			}, this.fadeout_delay);
		}

		// clicking the message should remove it
		$('#ajax_flash-' + this.rand_id).click(function() {
			$(this).fadeOut('slow', function() {
				$(this).remove();
			});
		});
	}
}

function delete_record(endpoint, id) {
	// build some stuff based on parameters
	var target = '/' + endpoint + '/' + id + '/delete?ajax=1';
	var row_selector = '#vhapi-' + endpoint.replace('/', '-') + '-' + id;

	// initialize variable
	var table = $('#DataTables_Table_0').DataTable();
	var rand_id = Math.random().toString(36).replace(/[^a-z]+/g, '').substr(0, 8);
	var response;

	// run the ajax
	$.ajax({
		beforeSend: function() {
			document.body.style.cursor = 'wait';
		},
		url: target,
		method: 'POST',
		success: function(data) {
			var result_hash = JSON.parse(data);
			response = new AjaxResponse(
				false,
				rand_id,
				result_hash['status'],
				result_hash['msg'],
				null,
				3000,
				parseInt(result_hash['error_id']),
				result_hash['errors']
			);
		},
		error: function(xhr, status, error) {
			console.log(xhr);
			console.log(status);
			console.log(error);
			var result_hash = JSON.parse(xhr['responseText']);
			response = new AjaxResponse(
				false,
				rand_id,
				result_hash['status'],
				result_hash['msg'],
				null,
				10000,
				parseInt(result_hash['error_id']),
				result_hash['errors']
			);
		},
		complete: function(_xhr, _status) {
			$('#modal_delete').modal('toggle');

			// assign bootstrap alert class based on result_status
			if(response.status === 'success') {
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
			}
			// render the flash message
			response.render();
			document.body.style.cursor = 'auto';
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
		var rand_id = Math.random().toString(36).replace(/[^a-z]+/g, '').substr(0, 8);
		var form = $(this).parents('form');
		var form_action = form.attr('action') + '?ajax=1';
		var form_method = form.attr('method');
		var form_data = form.serialize();

		// include select[multiple] options to form_data (ajax endpoint will interpret those)
		// exclude multi-select with name "from[]" as they are not relevant
		form.find('select[multiple]:not([name="from\[\]"])').each(function(_idx, el) {
			$(el).children().each(function(_idx, opt) {
				form_data += '&' + $(el).attr('name') + '=' + $(opt).val();
			});
		});

		$.ajax({
			beforeSend: function() {
				toggle_form_input(false, form);
				document.body.style.cursor = 'wait';
			},
			url: form_action,
			method: form_method,
			data: form_data,
			success: function(data) {
				var result_hash = JSON.parse(data);
				var response = new AjaxResponse(
					true,
					rand_id,
					result_hash['status'],
					result_hash['msg'],
					result_hash['redirect'],
					3000,
					parseInt(result_hash['error_id']),
					result_hash['errors']
				);
				response.render();
			},
			error: function(xhr, status, error) {
				console.log(xhr);
				console.log(status);
				console.log(error);
				var result_hash;
				try {
					result_hash = JSON.parse(xhr['responseText']);
				} catch(e) {
					console.log(e);
					result_hash = {
						status: xhr['statusText'],
						msg: 'unknown error',
						error_id: parseInt(xhr['status']),
						errors: null
					};
				}
				response = new AjaxResponse(
					true,
					rand_id,
					result_hash['status'],
					result_hash['msg'],
					null,
					10000,
					parseInt(result_hash['error_id']),
					result_hash['errors']
				);
				response.render();
			}
		});
		return false;
	});
});
