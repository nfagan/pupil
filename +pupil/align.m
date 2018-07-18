function [t, pup] = align( task_data, event_name, look_back, look_ahead )

import shared_utils.assertions.*;

required_fields = { 'event_times', 'event_key', 'time', 'pupil' };

assert__are_fields( task_data, required_fields );
assert__isa( task_data, 'struct', 'task data' );
assert__isa( event_name, 'char', 'the event name' );
assert( numel(task_data) == 1, 'task data must be a scalar struct.' );
assert__isa( look_back, 'double' );
assert__isa( look_ahead, 'double' );
assert__is_scalar( look_back );
assert__is_scalar( look_ahead );

event_ind = strcmp( task_data.event_key, event_name );

assert( sum(event_ind) == 1, ['Expected to find one instance of "%s"' ...
  , ' but %d were found.'], event_name, sum(event_ind) );

event_time = task_data.event_times( event_ind );

start = event_time + look_back;
stop = event_time + look_ahead;

t_ind = task_data.time >= start & task_data.time <= stop;

t = task_data.time( t_ind ) - event_time;
pup = task_data.pupil( t_ind );

end