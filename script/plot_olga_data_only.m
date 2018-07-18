%%  olga

[behav, keys] = dsp2.io.get_behavior( 'INCLUDE_GAZE', false );
events = behav.events;
event_key = keys.events;

gaze = dsp2.io.get_gaze_data();
gaze = gaze.only( {'px', 'py', 'pt'} );

%%  olga alignment

do_normalize = true;
trial_by_trial_z = true;
match_fs = true;
do_threshold = false;
norm_method = 'divide';

epochs = { 'targOn', 'rwdOn' };
use_zs = { true, false };
m_within_blocks = { true, false };

mean_within_block = { 'outcomes', 'trialtypes', 'days', 'blocks', 'sessions', 'monkeys' };
mean_within_day = { 'outcomes', 'trialtypes', 'days', 'monkeys' };

all_combs = allcomb( {epochs, use_zs, m_within_blocks} );

processed_already = containers.Map();

for idx = 1:size(all_combs, 1)

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

if ( ~processed_already.isKey(processed_string) )
  [op, ot, omeans] = pupil.align_data_olga( gaze, events, event_key, oevt, start, stop, fs );
  [op_b, ot_b] = pupil.align_data_olga( gaze, events, event_key, oevt_b, ostart_b, ostop_b, fs );

  op.data = (op.data - omin) / (omax-omin);
  op_b.data = (op_b.data - omin) / (omax-omin);

  op = pupil.keep_saline_and_oxy_pre( op );
  op_b = pupil.keep_saline_and_oxy_pre( op_b );
  omeans = pupil.keep_saline_and_oxy_pre( omeans );
  
  assert( omeans.labels == op.labels );

  op_z = op;
  op_z_b = op_b;
  
  op_z_across_trials = Container();
  op_z_b_across_trials = Container();

  [I, C] = op_z.get_indices( {'days'} );

  for i = 1:numel(I)
    subset_non_z = omeans.data(I{i}, :);
    all_vals = zeros( 1, sum(subset_non_z(:, 2)) );
    stp = 1;
    for j = 1:size(subset_non_z, 1)
      val = subset_non_z(j, 1);
      reps = subset_non_z(j, 2);
      for k = 1:reps
        all_vals(stp) = val;
        stp = stp + 1;
      end
    end
    
    session_mean = nanmean( all_vals );
    session_dev = nanstd( all_vals );
    
    if ( trial_by_trial_z )
      z_trans_data = op_z.data(I{i}, :);
      z_trans_data = (z_trans_data - session_mean) ./ session_dev;

      z_trans_data_b = op_z_b.data(I{i}, :);
      z_trans_data_b = (z_trans_data_b - session_mean) ./ session_dev;

      op_z.data(I{i}, :) = z_trans_data;
      op_z_b.data(I{i}, :) = z_trans_data_b;
    else
      subset_z = op_z(I{i});
      subset_z_b = op_z_b(I{i});
      
      subset_z = subset_z.each1d( mean_within, @rowops.nanmean );
      subset_z_b = subset_z_b.each1d( mean_within, @rowops.nanmean );
      
      z_trans_data = subset_z.data;
      z_trans_data = (z_trans_data - session_mean) ./ session_dev;
      
      z_trans_data_b = subset_z_b.data;
      z_trans_data_b = (z_trans_data_b - session_mean) ./ session_dev;
      
      op_z_across_trials = append( op_z_across_trials, subset_z );
      op_z_b_across_trials = append( op_z_b_across_trials, subset_z_b );
    end
  end
  
  if ( ~trial_by_trial_z )
    op_z = op_z_across_trials;
    op_z_b = op_z_b_across_trials;
  end
  
  processed_already(processed_string) = struct( 'z', op_z, 'z_baseline', op_z_b ...
    , 'nonz', op, 'nonz_baseline', op_b );
else
  fprintf( '\n Using cached data.' );
  processed_data = processed_already(processed_string);
  op_z = processed_data.z;
  op_z_b = processed_data.z_baseline;
  op = processed_data.nonz;
  op_b = processed_data.nonz_baseline;
end

%  olga normalize

if ( use_z )
  to_norm = op_z;
  to_norm_b = op_z_b;
else
  to_norm = op;
  to_norm_b = op_b;
end

if ( do_normalize )
  o_b = nanmean( to_norm_b.data, 2 );
  op_cont = set_data( to_norm, pupil.normalize( to_norm.data, o_b, norm_method) );
  op_cont.data( isinf(op_cont.data) ) = NaN;
else
  op_cont = to_norm;
end

op_cont = op_cont.require_fields( {'task_type', 'session_type'} );

%  mean olga data only

meaned = op_cont;

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

pl = ContainerPlotter();

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
panels_are = { 'task_type', 'session_type', 'monkeys', 'trialtypes', 'drugs' };

plt.plot( pl, lines_are, panels_are );

f = FigureEdits( gcf() );

if ( do_save )
  filenames_are = union( panels_are, {'epochs'} );
  filename = dsp2.util.general.append_uniques( plt, 'pupil', filenames_are );
  
  if ( use_z )
    filename = sprintf( 'z_%s', filename );
    if ( ~trial_by_trial_z )
      filename = sprintf( 'trial_average_%s', filename );
    end
  end
  
  if ( is_within_block )
    filename = sprintf( 'within_block_%s', filename );
  end
  
  dsp2.util.general.save_fig( gcf(), fullfile(save_p, filename), {'epsc', 'png', 'fig'} );
end

end


