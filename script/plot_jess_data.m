%%

outer_dir = 'E:\nick_data\jessica\processed_data\old_pupil2';
load( fullfile(outer_dir, 'pupil.mat') );

sp = pupil.make_sparse_labels( labels, key, {'outcome', 'date', 'task_type', 'session_type'} );

cont = Container( task_data(:), sp );

%%

evt_name = 'reward';

subset = cont;
subset = subset.rm( 'twotargs' );
% subset = subset({'cuedonly'});

[t, p, bad] = pupil.align_several( subset.data, evt_name, -200, 500 );
[~, p_baseline, bad_b] = pupil.align_several( subset.data, 'target on', -200, 0 );

p_baseline = nanmean( p_baseline, 2 );

%%

do_normalize = true;
n_devs = 1;

lower_abs_thresh = -Inf;
upper_abs_thresh = Inf;

pup = Container( p, subset.labels );
pup_baseline = Container( p_baseline, subset.labels );

thresh_within = { 'outcome', 'session_type' };
[I, C] = pup.get_indices( thresh_within );
new_subset = Container();
new_subset_b = Container();
for i = 1:numel(I)
  extr = pup(I{i});
  extr_baseline = pup_baseline( I{i} );
  thresholded = pupil.std_threshold( extr.data, n_devs );
  thresholded_b = pupil.std_threshold( extr_baseline.data, n_devs );
  threshold2 = pupil.absolute_threshold( extr.data, lower_abs_thresh, upper_abs_thresh );
  threshold3 = pupil.absolute_threshold( extr_baseline.data, lower_abs_thresh, upper_abs_thresh );
  
  ind = thresholded & thresholded_b;
  
  ind = ind & threshold2 & threshold3;
  
  new_subset_b = append( new_subset_b, extr_baseline(ind) );
  new_subset = append( new_subset, extr(ind) );
end

if ( do_normalize )
  data = get_data( new_subset );
  data_b = get_data( new_subset_b );
  for i = 1:size(data, 2)
%     data(:, i) = data(:, i) ./ data_b;
    data(:, i) = data(:, i) - data_b;
  end
  new_subset.data = data;
end

pup = new_subset;


%%

pup = Container( p, subset.labels );

%%

norm = p;

for i = 1:size(norm, 2)
%   norm(:, i) = norm(:, i) - p_baseline;
  norm(:, i) = norm(:, i) ./ p_baseline;
end

pup = Container( norm, subset.labels );

%%

mean_each = { 'unit_n', 'run_n', 'date', 'outcome', 'session_type' };

meaned = pup.each1d( mean_each, @rowops.nanmean );

nans = any( isnan(meaned.data), 2 );

meaned = meaned(~nans);

%%

% meaned = meaned.rm( 'twotargs' );
meaned = meaned.only( 'cuedonly' );

pl = ContainerPlotter();

figure(4); clf();

pl.x = t;
pl.add_ribbon = false;

lines_are = 'outcome';
panels_are = {'task_type', 'session_type'};

pl.vertical_lines_at = 0;
pl.order_by = { 'self', 'both', 'other', 'none' };

pl.x_label = sprintf( 'Time (ms) from %s', evt_name );
pl.x_lim = [-200, 500];
pl.y_lim = [];

meaned.plot( pl, lines_are, panels_are );

