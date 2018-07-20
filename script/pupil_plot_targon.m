dataroot = pupil.get_dataroot();

traces = load( fullfile(dataroot, 'traces', 'traces.mat') );

%%

tracedat = traces.data;
tracelabs = fcat.from( traces.labels );

t = traces.t;

%%  traces

pltdat = tracedat;
pltlabs = tracelabs';

toselect = { 'targOn', 'cued' };
toremove = 'undefined-delay';
gcats = 'outcomes'; % groups
pcats = 'epochs'; % panels

t_ind = t >= 0 & t <= 1;
mask = find( pltlabs, toselect, findnone(pltlabs, toremove) );

pl = plotlabeled.make_common( ...
    'x',              t(t_ind) ...
  , 'add_smoothing',  true ...
  , 'smooth_func',    @(x) smooth(x, 5) ...
);

axs = pl.lines( pltdat(mask, t_ind), pltlabs(mask), gcats, pcats );

%%  u curve

pltdat = tracedat;
pltlabs = tracelabs';

toselect = { 'targOn', 'cued' };
toremove = 'undefined-delay';
xorder = { 'self', 'both', 'other', 'none' };
xcats = 'outcomes';
gcats = 'trialtypes';
pcats = 'epochs';
figs = 'epochs';

t_ind = t >= 0.7 & t <= 0.8;
mask = find( pltlabs, toselect, findnone(pltlabs, toremove) );

t_meaned = nanmean( pltdat(:, t_ind), 2 );

pl = plotlabeled.make_common( 'x_order', xorder, 'x_tick_rotation', 0 );
pl.fig = figure(2);

axs = pl.errorbar( t_meaned(mask), pltlabs(mask), xcats, gcats, pcats );
assert( isempty(pl.panel_order) && isempty(pl.group_order) );

panel_i = findall( pltlabs, figs, mask );

assert( numel(panel_i) == numel(axs) );

for i = 1:numel(panel_i)
  ax = axs(i);
  set( ax, 'nextplot', 'add' );

  [y, I] = keepeach( pltlabs', xcats, panel_i{i} );

  [~, order] = sort( cellfun(@(x) find(y, x), xorder) );

  y = y(order);
  I = I(order);

  means = rownanmean( t_meaned, I );
  ps = polyfit( 1:numel(means), means(:)', 2 );
  xs = 1:0.1:numel(means);
  plot( ax, xs, polyval(ps, xs) );
end

