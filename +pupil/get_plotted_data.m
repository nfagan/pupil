function [store_data, ot, params] = get_plotted_data(gaze, events, event_key, varargin)

defaults = struct();
defaults.normalize = true;
defaults.norm_method = 'divide';
defaults.epochs = { 'targOn', 'rwdOn' };
defaults.within_block = true;
defaults.within_trial = false;
defaults.start = -1;
defaults.stop = 2;

params = pupil.parsestruct( defaults, varargin );

do_normalize = params.normalize;
norm_method = params.norm_method;

epochs = params.epochs;
use_zs = { true };
m_within_blocks = { params.within_block };

mean_within_block = { 'outcomes', 'trialtypes', 'days', 'blocks', 'sessions', 'monkeys' };
mean_within_day = { 'outcomes', 'trialtypes', 'days', 'monkeys' };

all_combs = allcomb( {epochs, use_zs, m_within_blocks} );
n_combs = size( all_combs, 1 );

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

start = params.start;
stop = params.stop;
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

if ( ~params.within_trial )
  meaned = meaned.each1d( mean_within, @rowops.nanmean );
end

meaned = meaned.require_fields( {'epochs'} );
meaned('epochs') = oevt;

plt = meaned;
plt = plt.rm( 'errors' );
plt = plt.collapse( {'drugs', 'monkeys'} );

store_data = append( store_data, plt );

end

end