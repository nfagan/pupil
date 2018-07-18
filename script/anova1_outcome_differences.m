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

%%  preference

do_save = false;
prefix = 'pref_';

pref = Container( zeros(shape(traces, 1), 1), traces.labels );
pref = dsp3.get_processed_pref_index( pref );

prefdat = pref.data;
preflabs = fcat.from( pref.labels );

pl = plotlabeled();
pl.error_func = @plotlabeled.nansem;
pl.mask = find( preflabs, 'choice' );

pl.bar( prefdat, preflabs, 'contexts', {}, {} );

if ( do_save )
  full_plotp = fullfile( plotp, 'pref' );
  shared_utils.io.require_dir( full_plotp );
  fname = sprintf( '%s_%s', prefix, joincat(preflabs, 'contexts') );
  shared_utils.plot.save_fig( gcf, fullfile(full_plotp, fname), {'epsc', 'png', 'fig'}, true );
end

%%  preference stat

do_save = true;

[statslabs, I] = keepeach( preflabs', 'contexts', find(preflabs, 'choice') );
ps = zeros( size(I) );
zs = zeros( size(I) );
meds = zeros( size(I) );

N = numel( I );

for i = 1:numel(I)
  onedat = prefdat(I{i});
  [ps(i), ~, stats] = signrank( onedat );
  meds(i) = median( onedat );
  zs(i) = stats.zval;
end

alldat = [ ps; meds; zs ];

set1 = 1:N;
set2 = set1 + N;
set3 = set2 + N;

repmat( statslabs, numel(alldat)/N );
addcat( statslabs, 'measure' );
setcat( statslabs, 'measure', 'p', set1 );
setcat( statslabs, 'measure', 'median', set2 );
setcat( statslabs, 'measure', 'z', set3 );

[t, rc] = tabular( statslabs, 'contexts', 'measure' );

tbl = fcat.table( cellfun(@(x) alldat(x), t), rc{:} );

if ( do_save )
  base_fname = fcat.trim( joincat(prune(statslabs), {'outcomes', 'epochs', 'measure'}) );
  fname = sprintf( '%s.csv', base_fname );  
  shared_utils.io.require_dir( analysisp );

  inputs = { 'writerownames', true, 'writevariablenames', true };
  writetable( tbl, fullfile(analysisp, fname), inputs{:} );
end


%%  1 way anova, test for differences between outcomes

do_save = true;
anova_summary_prefix = 'anova_summary';
anova_table_prefix = 'anova_table';
anova_comparison_prefix = 'anova_comparisons';

tracedat = traces.data;
tracelabs = fcat.from( traces.labels );

setcat( addcat(tracelabs, 'measure'), 'measure', 'pupil' );

ts = [ 0.4, 0.8 ];
t_ind = t >= ts(1) & t <= ts(2);

selectors = { 'rwdOn', 'cued' };

[~, I] = only( tracelabs, selectors );
tracedat = tracedat(I, :);

timedat = nanmean( tracedat(:, t_ind), 2 );
grp = fullcat( tracelabs, 'outcomes' );

[p, atbl, stats] = anova1( timedat, grp, 'off' );
[c, m, ~, gnames] = multcompare( stats, 'display', 'off' );

atbl = cell2table( atbl(2:end, :), 'variablenames', matlab.lang.makeValidName(atbl(1, :)) );

% reformat multcompare output to display group names and column labels
header = { 'g1', 'g2', 'lb', 'est', 'ub', 'p' };
cs = [ arrayfun(@(x) gnames(x), c(:, 1:2)), arrayfun(@(x) {x}, c(:, 3:end)) ];
stbl = cell2table( cs, 'variablenames', header );

[tabinds, rc] = tabular( tracelabs, 'outcomes', {'epochs', 'measure'} );

means = arrayfun( @(x) mean(timedat(x{1})), tabinds );
devs = arrayfun( @(x) std(timedat(x{1})), tabinds );
ns = arrayfun( @(x) numel(x{1}), tabinds );

mtbl = fcat.table( means, rc{1}, setcat(rc{2}, 'measure', 'mean') );
dtbl = fcat.table( devs, rc{1}, setcat(rc{2}, 'measure', 'dev') );
ntbl = fcat.table( ns, rc{1}, setcat(rc{2}, 'measure', 'N') );

bothtbls = [ mtbl, dtbl, ntbl ];

if ( do_save )
  base_fname = fcat.trim( joincat(prune(tracelabs), {'outcomes', 'epochs', 'measure'}) );
  
  fname1 = sprintf( '%s_%s.csv', anova_summary_prefix, base_fname );
  fname2 = sprintf( '%s_%s.csv', anova_table_prefix, base_fname );
  fname3 = sprintf( '%s_%s.csv', anova_comparison_prefix, base_fname );
  
  shared_utils.io.require_dir( analysisp );
  
  inputs = { 'writerownames', true, 'writevariablenames', true };
  
  writetable( bothtbls, fullfile(analysisp, fname1), inputs{:} );
  writetable( atbl, fullfile(analysisp, fname2), inputs{:} );
  writetable( stbl, fullfile(analysisp, fname3), inputs{:} );
end

%%  count n trials per condition, per block

[blocklabs, blockinds] = keepeach( tracelabs', {'days', 'blocks', 'sessions'} );

N = length( blocklabs );
nouts = 4;
repmat( blocklabs, nouts );

dat = zeros( N * nouts, 1 );

for i = 1:numel(blockinds)
  
  s = find( tracelabs, 'self', blockinds{i} );
  b = find( tracelabs, 'both', blockinds{i} );
  o = find( tracelabs, 'other', blockinds{i} );
  n = find( tracelabs, 'none', blockinds{i} );
  
  si = i;
  bi = i + N;
  oi = i + N * 2;
  ni = i + N * 3;
  
  setcat( blocklabs, 'outcomes', 'self', si );
  setcat( blocklabs, 'outcomes', 'both', bi );
  setcat( blocklabs, 'outcomes', 'other', oi );
  setcat( blocklabs, 'outcomes', 'none', ni );
  
  dat(si) = numel(s);
  dat(bi) = numel(b);
  dat(oi) = numel(o);
  dat(ni) = numel(n);
end

[perout, I] = keepeach( blocklabs', {'outcomes'} );

mins = cellfun( @(x) min(dat(x)), I );
maxs = cellfun( @(x) max(dat(x)), I );

[tabinds, rc] = tabular( perout, 'outcomes', 'epochs' );
fcat.table( arrayfun(@(x) maxs(x{1}), tabinds), rc{:} )

%%

do_save = true;

pltlabs = fcat.from( traces.labels );
pltdata = traces.data;

selectors = {'cued', 'rwdOn', 'targOn' };

[~, I] = only( pltlabs, selectors );
pltdata = rowref( pltdata, I );

pl = plotlabeled();
pl.x = t;
pl.smooth_func = @(x) smooth(x, 7);
pl.add_smoothing = true;
pl.summary_func = @plotlabeled.nanmean;
pl.error_func = @plotlabeled.nansem;
pl.main_line_width = 2;
pl.panel_order = { 'low', 'medium', 'high' };
pl.group_order = { 'self', 'both', 'other', 'none' };

lines_are = { 'outcomes' };
panels_are = { 'epochs', 'monkeys', 'trialtypes', 'drugs' };

axs = pl.lines( labeled(pltdata, pltlabs), lines_are, panels_are );

set( axs, 'nextplot', 'add' );
arrayfun( @(x) xlim(x, [-0.2, 1]), axs );

arrayfun( @(x) xlabel(x, 'Reward onset'), axs );
arrayfun( @(x) ylim(x, [-4, 1.5]), axs );
shared_utils.plot.add_vertical_lines( axs, 0 );

if ( do_save )
  fname1 = fcat.trim( joincat(prune(pltlabs), unique([lines_are, panels_are])) );
  shared_utils.io.require_dir( plotp );
  shared_utils.plot.save_fig( gcf, fullfile(plotp, fname1), {'epsc', 'png', 'fig'}, true );
end

%%  u-curve

pltlabs = fcat.from( traces.labels );
pltdat = traces.data;

ts = [ 0.5, 0.7 ];
t_ind = t >= ts(1) & t <= ts(2);

tdata = nanmean( pltdat(:, t_ind), 2 );

%%
do_save = true;
prefix = 'inverted_u';

evt = 'targOn';
rwd_mask = find( pltlabs, {evt, 'cued'} );

[outlabs, I, C] = keepeach( pltlabs', 'outcomes', rwd_mask );

means = rownanmean( tdata, I );
errs = rowop( tdata, I, @(x) plotlabeled.nansem(x) );

[exists, ordered_ind] = ismember( {'self', 'both', 'other', 'none'}, C );
ordered_ind = ordered_ind(exists);

means = means(ordered_ind);
errs = errs(ordered_ind);
outlabs = outlabs(ordered_ind);
I = I(ordered_ind);
C = C(ordered_ind);

f = figure(1);
clf( f );

ps = polyfit( 1:numel(I), means(:)', 2 );
x_vec = 1:0.01:numel(I);

errorbar( 1:numel(I), means(:)', errs(:)' );

hold on;
plot( x_vec, polyval(ps, x_vec) );

set( gca, 'xtick', 1:numel(I) );
set( gca, 'xticklabels', C );

title_lab = sprintf( '%0.1f to %0.1f s post %s', ts, evt );
title( title_lab );

xlim( [0, numel(I)+1] );

ylabel( 'Z-Scored pupil size' );

if ( do_save )
  fname = fcat.trim( joincat(outlabs, {'outcomes', 'epochs'}) );
  fname = sprintf( '%s_%s_%d_%d', prefix, fname, round(ts*1e3) );
  full_plotp = fullfile( plotp, 'inverted_u' );
  shared_utils.io.require_dir( full_plotp );
  shared_utils.plot.save_fig( gcf, fullfile(full_plotp, fname), {'epsc', 'png', 'fig'}, true );
end




