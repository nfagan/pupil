function make_traces(consolidated)

dataroot = pupil.get_dataroot();
outputp = reqdir( fullfile(dataroot, 'traces') );

if ( nargin < 1 || isempty(consolidated) )
  consolidated = load( fullfile(dataroot, 'consolidated', 'consolidated.mat') );
end

gaze = consolidated.gaze;
events = consolidated.events;
event_key = consolidated.event_key;

[traces, t, params] = pupil.get_plotted_data( gaze, events, event_key ...
  , 'within_trial', true ...
  , 'start', -1 ...
  , 'stop', 2 ...
);

data = traces.data;
labels = gather( fcat.from(traces.labels) );

save( fullfile(outputp, 'traces.mat'), 'data', 'labels', 't', 'params' );

end

function p = reqdir(p)
if ( exist(p, 'dir') ~= 7 ), mkdir( p ); end
end