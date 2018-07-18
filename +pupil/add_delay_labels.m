function gaze = add_delay_labels(gaze, behav, delays)

assert( numel(delays) == shape(behav, 1), 'Delays do not correspond to trial data.' );

gazedat = gaze.data;

parfor i = 1:numel(gazedat)
  current = gazedat{i};
  labs = current.labels;
  
  C = flat_uniques( current, {'days', 'blocks', 'sessions'} );
  
  matching_ind = where( behav, C );
  
  
  try
    assert( sum(matching_ind) == shape(current, 1), 'Subsets did not match.' );
    
    delay_strs = arrayfun( @(x) ['delay__', num2str(x)], delays(matching_ind), 'un', 0 );
  catch err
    %   known issue with 04192016
    day = C{1};
    assert( strcmp(day, 'day__04192016'), 'Unrecognized error day "%s".', day );
    
    subset_behav = behav(matching_ind);
    subset_behav.labels = recode_trial_labs( subset_behav.labels );
    recoded_labs = recode_trial_labs( labs );
    
    trials = full_fields( recoded_labs, 'trials' );
    delay_strs = cell( shape(recoded_labs, 1), 1 );
    
    num_inds = find( matching_ind );
    
    for j = 1:numel(trials)
      
      one_matching_ind = where( subset_behav, trials{j} );
      assert( sum(one_matching_ind) == 1 );
      c_ind = num_inds(one_matching_ind);
      
      delay_strs{j} = [ 'delay__', num2str(delays(c_ind)) ];
    end
  end
  
  labs = add_field( labs, 'delay' );
  labs = set_field( labs, 'delay', delay_strs );
  
  current.labels = labs;
  
  gazedat{i} = current;
end

gaze.data = gazedat;

end

function labs = recode_trial_labs(labs)

N = shape( labs, 1 );
ind = false( N, 1 );

for i = 1:shape(labs, 1)
  ind(i) = true;
  labs = set_field( labs, 'trials', sprintf('trial__%d', i), ind );
  ind(:) = false;
end

end