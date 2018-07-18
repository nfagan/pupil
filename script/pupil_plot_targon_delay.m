%%

dataroot = pupil.get_dataroot();

consolidated = load( fullfile(dataroot, 'consolidated', 'consolidated.mat') );
gaze = consolidated.gaze;
events = consolidated.events;
event_key = consolidated.event_key;
behav = consolidated.behav.trial_info;

datedir = datestr( now, 'mmddyy' );
plotp = fullfile( dataroot, 'plots', datedir );
analysisp = fullfile( dataroot, 'analysis', datedir );

% gz = pupil.add_delay_labels( gaze, behav, ones(shape(behav, 1), 1) );

%%

[traces, t, params] = pupil.get_plotted_data( gaze, events, event_key ...
  , 'within_trial', true ...
  , 'start', -1 ...
  , 'stop', 2 ...
);

%%

tracedat = traces.data;
tracelabs = fcat.from( traces.labels );

%%

do_save = true;

t_ind = t >= 0 & t <= 1;

% delays = 0.2:0.2:0.8;
delays = params.delays(1:4); delays(1) = 0.18;
add_delays = true;

pltlabs = tracelabs';
pltdata = tracedat(:, t_ind);

toselect = { 'cued', 'targOn' };
toremove = { 'errors', 'undefined-delay' };

mask = find( pltlabs, toselect, findnone(pltlabs, toremove) );

pl = plotlabeled.make_common();
pl.x = t(t_ind);
pl.smooth_func = @(x) smooth(x, 7);
pl.add_smoothing = true;
pl.main_line_width = 2;
pl.group_order = { 'self', 'both', 'other', 'none' };
pl.panel_order = { 'short-delay', 'med-delay', 'long-delay' };

lines_are = { 'outcomes' };
panels_are = { 'epochs', 'monkeys', 'trialtypes', 'drugs', 'delays' };

axs = pl.lines( rowref(pltdata, mask), pltlabs(mask), lines_are, panels_are );

if ( add_delays )
  assert( numel(delays) == numel(axs), 'Axes and delays must correspond.' );
end

shared_utils.plot.hold( axs );

for i = 1:numel(delays)
  
  [tf, delay_ind] = ismembertol( delays(i), t, 0.001 );
  
  if ( ~tf ), continue; end
  
  shared_utils.plot.add_vertical_lines( axs(i), t(delay_ind) ); 
end

if ( do_save )
  shared_utils.io.require_dir( plotp );
  fname = dsp3.fname( pltlabs, csunion(lines_are, panels_are) );
  dsp3.savefig( gcf, fullfile(plotp, fname) );  
end


