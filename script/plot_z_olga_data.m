%%  olga

[behav, keys] = dsp2.io.get_behavior( 'INCLUDE_GAZE', false );
events = behav.events;
event_key = keys.events;

gaze = dsp2.io.get_gaze_data();
gaze = gaze.only( {'px', 'py', 'pt'} );

%%  olga alignment

do_plot = false;
do_normalize = true;
norm_method = 'divide';

epochs = { 'targOn', 'rwdOn' };
use_zs = { true };
% m_within_blocks = { true, false };
m_within_blocks = { true };

mean_within_block = { 'outcomes', 'trialtypes', 'days', 'blocks', 'sessions', 'monkeys' };
mean_within_day = { 'outcomes', 'trialtypes', 'days', 'monkeys' };

all_combs = allcomb( {epochs, use_zs, m_within_blocks} );
% n_combs = size( all_combs, 1 );
n_combs = 1;

processed_already = containers.Map();

store_data = Container();

for idx = 1:n_combs

oevt = all_combs{idx, 1};
use_z = all_combs{idx, 2};
is_within_block = all_combs{idx, 3};

if ( is_within_block )
  mean_within = mean_within_block;
else
  mean_within = mean_within_day;
end

if ( use_z )
  proc_z = 'use_z';
else
  proc_z = 'no_z';
end

processed_string = oevt;

start = -1;
stop = 1;
fs = 4/1e3;

omin = -2^16 / 2;
omax = 2^16 / 2;

oevt_b = 'cueOn';
ostart_b = -0.15;
ostop_b = 0;

%   if we don't yet have data for this epoch
if ( ~processed_already.isKey(processed_string) )
  [op, ot, omeans] = pupil.align_data_olga( gaze, events, event_key, oevt, start, stop, fs );
  [op_b, ot_b] = pupil.align_data_olga( gaze, events, event_key, oevt_b, ostart_b, ostop_b, fs );

  op.data = (op.data - omin) / (omax-omin);
  op_b.data = (op_b.data - omin) / (omax-omin);

  op = pupil.keep_saline_and_oxy_pre( op );
  op_b = pupil.keep_saline_and_oxy_pre( op_b );
  omeans = pupil.keep_saline_and_oxy_pre( omeans );
  
  assert( omeans.labels == op.labels );
  
  if ( do_normalize )
    op_baseline = nanmean( op_b.data, 2 );
    op_cont = set_data( op, pupil.normalize(op.data, op_baseline, norm_method) );
    op_cont.data( isinf(op_cont.data) ) = NaN;
  else
    op_cont = op;
  end
  
  session_means = op_cont.each1d( {'days'}, @(x) nanmean(nanmean(x, 2)) );
  session_devs = op_cont.each1d( {'days'}, @(x) nanstd(nanstd(x, [], 2)) );
  
  [I, C] = op_cont.get_indices( {'days'} );
  
  op_z = op_cont;
  
  for i = 1:numel(I)
    subset_means = session_means(C(i, :));
    subset_devs = session_devs(C(i, :));
    
    assert( shape(subset_means, 1) == 1 && shapes_match(subset_means, subset_devs) );
    
    subset_z = get_data( op_z(I{i}) );
    subset_z = (subset_z - subset_means.data) ./ (subset_devs.data);
    
    op_z.data(I{i}, :) = subset_z;
  end
  
  processed_already(processed_string) = struct( 'z', op_z, 'nonz', op_cont );
else
  fprintf( '\n Using cached data.' );
  processed_data = processed_already(processed_string);
  op_z = processed_data.z;
  op_cont = processed_data.nonz;
end

if ( use_z )
  meaned = op_z;
else
  meaned = op_cont;
end

meaned = meaned.each1d( mean_within, @rowops.nanmean );

%

conf = dsp2.config.load();

save_p = fullfile( conf.PATHS.plots, 'pupil', dsp2.process.format.get_date_dir() );

do_save = true;

if ( do_save )
  dsp2.util.general.require_dir( save_p );
end

meaned = meaned.require_fields( {'epochs'} );
meaned('epochs') = oevt;

plt = meaned;

plt = plt.rm( 'errors' );
plt = plt.collapse( {'drugs', 'monkeys'} );

store_data = append( store_data, plt );

if ( ~do_plot ), continue; end

pl = ContainerPlotter();

pl.add_smoothing = true;
pl.smooth_function = @(x) smooth(x, 7);

pl.x = ot;
pl.summary_function = @nanmean;
pl.error_function = @ContainerPlotter.nansem;
pl.add_ribbon = true;
pl.order_by = { 'self', 'both', 'other', 'none' };
pl.x_label = sprintf( 'time (ms) from %s', oevt );
pl.vertical_lines_at = 0;
pl.x_lim = [ -0.2, 1 ];

if ( use_z )
  pl.y_label = 'Z-scored, normalized pupil size';
else
  pl.y_label = 'normalized pupil size';
end

h = figure(2); clf( h );

lines_are = { 'outcomes' };
panels_are = { 'monkeys', 'trialtypes', 'drugs' };

plt.plot( pl, lines_are, panels_are );

f = FigureEdits( gcf() );

if ( do_save )
  filenames_are = union( panels_are, {'epochs'} );
  filename = dsp2.util.general.append_uniques( plt, 'pupil', filenames_are );
  
  if ( use_z )
    filename = sprintf( 'z_%s', filename );
  end
  
  if ( is_within_block )
    filename = sprintf( 'within_block_%s', filename );
  end
  
  dsp2.util.general.save_fig( gcf(), fullfile(save_p, filename), {'epsc', 'png', 'fig'} );
end

end


