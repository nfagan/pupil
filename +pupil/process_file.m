function [task_data, labels, label_key] = process_file(data, filename, date_str)

import shared_utils.assertions.*;

assert__isa( data, 'struct', 'the trial data' );
assert__isa( filename, 'char', 'the data filename' );
assert__isa( date_str, 'char', 'the date' );

required_fields = { 'EventTime', 'EventType', 'EYEDATA', 'Time_Diff' };

assert__are_fields( data, required_fields );

label_map = containers.Map();
eye_data_map = containers.Map();

label_map( 'trialnum' ) = 'trial_n';
label_map( 'unit_number' ) = 'unit_n';
label_map( 'rwd_type' ) = 'outcome';
label_map( 'task_id' ) = 'task_type';
label_map( 'monkey_1' ) = 'm1';
label_map( 'monkey_2' ) = 'm2';

eye_data_map( 'pupil' ) = 12;
eye_data_map( 'time' ) = 1;
eye_data_map( 'x' ) = 14;
eye_data_map( 'y' ) = 16;

fields = fieldnames( data );
key = keys( label_map );

inds = zeros( size(key) );

for i = 1:numel(inds)
  ind = strcmpi( fields, key{i} );
  assert( sum(ind) == 1, ['Expected key ''%s'' to appear once, but there' ...
    , ' were %d occurrences.'], sum(ind) );
  inds(i) = find( ind );
end

labels = cell( 1, numel(inds) );

for i = 1:numel(key)
  field = fields(inds(i));
  value = data.(field{1});

  if ( ischar(value) )
    value = lower( value );
  end

  if ( strcmpi(key{i}, 'unit_number') )
    value = str2double( value );
    assert( ~isnan(value), 'Failed to parse unit number "%s".', data.(field{1}) );
  end

  labels{i} = value;
end

label_key = cell( size(key) );

for i = 1:numel(key)
  label_key{i} = label_map(key{i});
end

label_key{end+1} = 'run_n';

try
  run_n = get_run_number( filename );
catch err
  throwAsCaller( err );
end

labels{end+1} = run_n;

label_key{end+1} = 'date';
labels{end+1} = date_str;

start_time_ind = data.EYEDATA(eye_data_map('time'), :) == -32768;

if ( any(start_time_ind) )
  assert( start_time_ind(1), 'Invalid start time id for file "%s".', filename );
  bad_start_col = 0;
  while ( start_time_ind(bad_start_col+1) )
    bad_start_col = bad_start_col + 1;
  end
else
  bad_start_col = 0;
end

eye_data = data.EYEDATA(:, bad_start_col+1:end);

event_times = data.EventTime;
event_names = data.EventType;

[event_times, I] = sort( event_times );
event_names = event_names(I);

assert( ~any(isnan(event_times)), 'Some event times were NaN for file "%s".', filename );
assert( strcmpi(event_names{1}, 'trial start'), ['the first event must be "trial start"' ...
  , ' was "%s".'], event_names{1} );
assert( strcmpi(event_names{2}, 'fixation on'), ['the second event must be "fixation on"' ...
  , ' was "%s".'], event_names{2} );

time_multiplier = 1e3;

t = eye_data(eye_data_map('time'), :);
p = eye_data(eye_data_map('pupil'), :);

assert( numel(unique(diff(t)) == 1) && (t(2)-t(1) == 1 || t(2)-t(1) == 2), ...
  'Incorrect sample rate for file "%s".', filename );

sample_factor = t(2) - t(1);

subtract_to_align = event_times(2) * time_multiplier;
t = t - subtract_to_align + (data.Time_Diff * time_multiplier);

incrementing_event_times_ms = (event_times - event_times(2)) * 1e3;

for i = 2:numel(incrementing_event_times_ms)
  if ( min(t) > incrementing_event_times_ms(i) || max(t) < incrementing_event_times_ms(i) )
    error( 'Event time was out of bounds for file "%s".', filename );
  end
end

task_data = struct();
task_data.event_times = incrementing_event_times_ms;
task_data.event_key = event_names;
task_data.time = t;
task_data.pupil = p;
task_data.sample_factor = sample_factor;

end

function run_n =  get_run_number(filename)

run_ind = strfind( lower(filename), 'run' );
underscore_ind = strfind( lower(filename), '_' );

assert( ~isempty(run_ind), 'No ''run'' tag found in filename ''%s''', filename );
assert( ~isempty(underscore_ind), 'No underscores found in filename ''%s''', filename );

underscore_ind = underscore_ind( underscore_ind > run_ind + numel('run') );

assert( numel(underscore_ind) == 1, ['Expected one underscore to follow' ...
  , ' Runxx; but there were %d in filename "%s".'], numel(underscore_ind), filename );

run_n = str2double( filename(run_ind+numel('run'):underscore_ind-1) );

assert( ~isnan(run_n), 'Failed to parse the run number for filename ''%s''', filename );

end