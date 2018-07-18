%%  olga

[behav, keys] = dsp2.io.get_behavior( 'INCLUDE_GAZE', false );
events = behav.events;
event_key = keys.events;

gaze = dsp2.io.get_gaze_data();
gaze = gaze.only( {'px', 'py', 'pt'} );

%%  jessica

outer_dir = 'E:\nick_data\jessica\processed_data\old_pupil2';
load( fullfile(outer_dir, 'pupil.mat') );

sp = pupil.make_sparse_labels( labels, key ...
  , {'outcome', 'date', 'task_type', 'session_type'} );

cont = Container( task_data(:), sp );

%%  olga alignment

do_normalize = true;
match_fs = true;
do_threshold = false;
norm_method = 'divide';

start = -1;
stop = 1;
oevt = 'rwdOn';
fs = 4/1e3;

omin = -2^16 / 2;
omax = 2^16 / 2;

oevt_b = 'cueOn';
ostart_b = -0.15;
ostop_b = 0;

[op, ot] = pupil.align_data_olga( gaze, events, event_key, oevt, start, stop, fs );
[op_b, ot_b] = pupil.align_data_olga( gaze, events, event_key, oevt_b, ostart_b, ostop_b, fs );

op.data = (op.data - omin) / (omax-omin);
op_b.data = (op_b.data - omin) / (omax-omin);

op = pupil.keep_saline_and_oxy_pre( op );
op_b = pupil.keep_saline_and_oxy_pre( op_b );

rep_x = @(x, y) repmat( y, size(x, 1), 1 );
z_func = @(x) (x - rep_x(x, rowops.mean(x))) ./ rep_x(x, rowops.std(x));

op_z = op.for_each_nd( {'days', 'outcomes'}, z_func );
op_b_z = op_b.for_each_nd( {'days', 'outcomes'}, z_func );

%%  olga normalize

if ( do_normalize )
  o_b = nanmean( op_b.data, 2 );
  op_cont = set_data( op, pupil.normalize( op.data, o_b, norm_method) );
  op_cont.data( isinf(op_cont.data) ) = NaN;
else
  op_cont = op;
end

%%  jessica alignment

event_map = pupil.get_event_name_map( false );
jevt = event_map( oevt );

subset = cont;
subset = subset.rm( 'twotargs' );
% subset = subset({'cuedonly'});

jmax = 9999;
jmin = 0;

jevt_b = 'target on';
jstart_b = -200;
jstop_b = 0;

[jt, jp, bad] = pupil.align_several( subset.data, jevt, start*1e3, stop*1e3 );
[jt_b, jp_b, bad_b] = pupil.align_several( subset.data, jevt_b, jstart_b, jstop_b );

jp( jp == 0 ) = NaN;
jp_b( jp_b == 0 ) = NaN;

jp_b = nanmean( jp_b, 2 );

jp = (jp - jmin) / (jmax-jmin);
jp_b = (jp_b - jmin) / (jmax-jmin);

%%  jessica normalize

if ( do_normalize )
  jp_cont = set_data( subset, pupil.normalize( jp, jp_b, norm_method) );
  jp_cont.data( isinf(jp_cont.data) ) = NaN;
else
  jp_cont = set_data( subset, jp );
end

%%  combine

if ( match_fs )
  jp_cont_downsampled = set_data(jp_cont, pupil.downsample(jp_cont.data, 4) );
  jt_downsampled = downsample( jt, 4 );

  jto_match = jp_cont_downsampled;
  oto_match = op_cont;

  jto_match = jto_match.rename_field( 'date', 'days' );
  jto_match = jto_match.rename_field( 'outcome', 'outcomes' );
  jto_match = jto_match.rename_field( 'unit_n', 'sessions' );
  jto_match = jto_match.rename_field( 'run_n', 'blocks' );
  jto_match = jto_match.rename_field( 'm1', 'monkeys' );
  jto_match = jto_match.rename_field( 'm2', 'recipients' );

  all_cats = union( oto_match.categories(), jto_match.categories() );

  jto_match = jto_match.require_fields( all_cats );
  oto_match = oto_match.require_fields( all_cats );

  oto_match( 'task_type' ) = 'olga_dictator';
  jto_match = jto_match.collapse( 'trialtypes' );

  jo_cont = append( jto_match, oto_match );
  jo_t = jt_downsampled;
else
  jo_cont = jp_cont;
  jo_t = jt;
end

%%  threshold

n_devs = 3;

do_threshold = false;

if ( do_threshold )
  [I, C] = jo_cont.get_indices( {'task_type', 'session_type', 'monkeys'} );
  to_keep = jo_cont.logic( false );
  for i = 1:numel(I)
    ind = pupil.std_threshold( jo_cont.data(I{i}, :), n_devs );
    to_keep( I{i} ) = ind;
  end
else
  to_keep = jo_cont.logic( true );
end

jo_thresh = jo_cont( to_keep );

%%

meaned = jo_thresh;

m_within = { 'outcomes', 'task_type', 'session_type' ...
  , 'trialtypes', 'days', 'blocks', 'sessions' };

meaned = meaned.each1d( m_within, @rowops.nanmean );


%%

conf = dsp2.config.load();
save_p = fullfile( conf.PATHS.plots, 'pupil', dsp2.process.format.get_date_dir() );
do_save = true;
if ( do_save )
  dsp2.util.general.require_dir( save_p );
end

meaned = meaned.require_fields( {'epochs'} );
meaned('epochs') = oevt;

for i = 1:4

if ( i < 4 )

  pre_oxy = meaned({'oxytocin', 'pre'});
  pre_sal = meaned({'saline', 'pre'});
  non_inject = meaned({'unspecified'});

  set1 = extend( pre_oxy, pre_sal );
  % set2 = non_inject;
  set3 = meaned({'saline'});

  set1('drugs') = 'oxy_and_sal_pre';
  % set2('drugs') = 'non_injection';
  set3('drugs') = 'saline';

  plt = extend( set1, set3 );
else
  plt = meaned({'oxytocin', 'saline'});
  plt = plt({'post'});
end

% plt = extend( pre_oxy, pre_sal, non_inject );

if ( i == 1 )
  plt = plt({'kuro'});
elseif ( i == 2 )
  plt = plt({'hitch'});
else
  plt = plt.collapse( 'monkeys' );
end

plt = plt.rm( {'errors', 'cuedonly'} );
% plt = plt.collapse( 'monkeys' );
% plt = plt.rm( 'olga_dictator' );
plt = plt({'olga_dictator'});

pl = ContainerPlotter();

pl.x = jo_t;
pl.summary_function = @nanmean;
pl.error_function = @ContainerPlotter.nansem;
pl.add_ribbon = true;
pl.order_by = { 'self', 'both', 'other', 'none' };
pl.x_lim = [0, 1000 ];
pl.x_label = sprintf( 'time (ms) from %s', oevt );
pl.vertical_lines_at = 0;
% pl.match_y_lim = false;

h = figure(2); clf( h );

lines_are = { 'outcomes' };
panels_are = { 'task_type', 'session_type', 'monkeys', 'trialtypes', 'drugs' };

plt.plot( pl, lines_are, panels_are );

f = FigureEdits( gcf() );

if ( do_save )
  filenames_are = union( panels_are, {'epochs'} );
  filename = dsp2.util.general.append_uniques( plt, 'pupil', filenames_are );
  dsp2.util.general.save_fig( gcf(), fullfile(save_p, filename), {'epsc', 'png', 'fig'} );
end


end

%%  mean olga data only

meaned = jo_thresh;

m_within = { 'outcomes', 'task_type', 'session_type' ...
  , 'trialtypes', 'days', 'blocks', 'sessions' };

meaned = meaned.each1d( m_within, @rowops.nanmean );

%%

conf = dsp2.config.load();
save_p = fullfile( conf.PATHS.plots, 'pupil', dsp2.process.format.get_date_dir() );
do_save = true;
if ( do_save )
  dsp2.util.general.require_dir( save_p );
end

meaned = op

meaned = meaned.require_fields( {'epochs'} );
meaned('epochs') = oevt;

pl = ContainerPlotter();

pl.x = jo_t;
pl.summary_function = @nanmean;
pl.error_function = @ContainerPlotter.nansem;
pl.add_ribbon = true;
pl.order_by = { 'self', 'both', 'other', 'none' };
pl.x_lim = [0, 1000 ];
pl.x_label = sprintf( 'time (ms) from %s', oevt );
pl.vertical_lines_at = 0;
% pl.match_y_lim = false;

h = figure(2); clf( h );

lines_are = { 'outcomes' };
panels_are = { 'task_type', 'session_type', 'monkeys', 'trialtypes', 'drugs' };

plt.plot( pl, lines_are, panels_are );

f = FigureEdits( gcf() );

if ( do_save )
  filenames_are = union( panels_are, {'epochs'} );
  filename = dsp2.util.general.append_uniques( plt, 'pupil', filenames_are );
  dsp2.util.general.save_fig( gcf(), fullfile(save_p, filename), {'epsc', 'png', 'fig'} );
end




