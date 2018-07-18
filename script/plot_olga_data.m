%%  load
import dsp2.util.general.fload;
import dsp2.process.format.*;

epoch = 'targOn';

conf = dsp2.config.load();

% target_load_dir = '011018';
target_load_dir = 'new2';

pathstr = fullfile( conf.PATHS.analyses, 'pupil', target_load_dir );
pathstr_baseline = fullfile( conf.PATHS.analyses, 'pupil' );

psth = fload( fullfile(pathstr, sprintf('psth_%s.mat', epoch)) );
tseries = fload( fullfile(pathstr, sprintf('time_series_%s.mat', epoch)) );
baseline = fload( fullfile(pathstr_baseline, 'psth_cueOn.mat') );
baselinet = fload( fullfile(pathstr_baseline, 'time_series_cueOn.mat') );

psth = dsp2.process.format.fix_block_number( psth );
psth = dsp2.process.format.fix_administration( psth );
baseline = dsp2.process.format.fix_block_number( baseline );
baseline = dsp2.process.format.fix_administration( baseline );

orig_psth = psth;
orig_baseline = baseline;

x = tseries.x;
look_back = tseries.look_back;
base_x = baselinet.x;
base_look_back = baselinet.look_back;

%%
psth = orig_psth;
baseline = orig_baseline;
%%
lowerb = -12e3;
upperb = -1e3;

ind_target = orig_psth.logic( true );
ind_baseline = ind_target;

% ind_target = pupil.std_threshold( orig_psth.data, 1 );
% ind_baseline = pupil.std_threshold( orig_baseline.data, 1 );

ind_target = ind_target & pupil.absolute_threshold( orig_psth.data, lowerb, upperb );
ind_baseline = ind_baseline & pupil.absolute_threshold( orig_baseline.data, lowerb, upperb );

ind_target = ind_target | any(isnan(orig_psth.data), 2);
ind_baseline = ind_baseline | any(isnan(orig_baseline.data), 2);

psth = orig_psth.keep( ind_target & ind_baseline );
baseline = orig_baseline.keep( ind_target & ind_baseline );

%%  normalize

% errs = isnan(psth.data(:, 1)) | isnan(baseline.data(:, 1));

% normed = psth.keep( ~errs );
% normalizer = baseline.keep( ~errs );

normed = psth;
normalizer = baseline;

norm_ind = ( base_x >= base_look_back & base_x <= 0 );
meaned = nanmean( normalizer.data(:, norm_ind), 2 );
dat = normed.data;

for i = 1:size(dat, 2)
%   dat(:, i) = dat(:, i) - meaned;
  dat(:, i) = dat(:, i) ./ meaned;
end

normed.data = dat;

%%  plot

plt = normed.only( 'px' );
% plt = dsp2.process.format.fix_block_number( plt );
% plt = dsp2.process.format.fix_administration( plt );

m_within = {'outcomes', 'sessions', 'blocks', 'trialtypes', 'days', 'administration'};

plt = plt.rm( {'unspecified', 'errors'} );
plt = plt.each1d( m_within, @rowops.nanmean );

%%

figure(2); clf();

pl = ContainerPlotter();
pl.add_ribbon = false;
pl.x = x;
pl.order_by = { 'pre', 'post' };
pl.y_lim = [];
pl.vertical_lines_at = [0, .15];
pl.shape = [1, 2];
pl.y_label = 'Pupil size';
pl.x_label = sprintf( 'Time (ms) from %s', epoch );
pl.x_lim = [-0.2, 0.5];

trace_level = plt;

trace_level = trace_level({'cued'});
trace_level = plt.rm( 'oxytocin' );
trace_level = trace_level.collapse( 'administration' );
trace_level = trace_level.collapse( 'drugs' );
trace_level = trace_level.collapse_except( {'outcomes', 'trialtypes', 'days', 'drugs', 'administration'} );
% trace_level = trace_level.only('post') - trace_level.only('pre');

trace_level.plot( pl, {'outcomes'}, {'drugs', 'administration', 'trialtypes'} );
