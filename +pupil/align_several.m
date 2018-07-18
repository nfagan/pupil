function [t, p, bad] = align_several( task_data, event_name, start, stop )

p = nan( numel(task_data), stop - start + 1 );
t = nan( numel(task_data), stop - start + 1 );

bad = false( numel(task_data), 1 );

t_series = start:stop;

method_one = false;

for i = 1:numel( task_data )
  [t_, p_] = pupil.align( task_data(i), event_name, start, stop );
  
  if ( isempty(t_) ), continue; end
  
  sample_factor = round( mean(diff(t_)) );
  recorded_sample_factor = task_data(i).sample_factor;
  
  if ( sample_factor ~= recorded_sample_factor )
    bad(i) = true;
    continue;
  end
  
  start_t = ceil( abs(t_(1)) ) * sign( t_(1) );
  
  start_ind = find( t_series == start_t );
  
  assert( ~isempty(start_ind), 'Could not find the index of start time %0.3f', t_(1) );
  
  stp = start_ind;
  for j = 1:numel(t_)
    for k = 1:sample_factor
      if ( stp > size(p, 2) )
        fprintf( '\n Warning: %d samples will be truncated', numel(t_)-j+1 );
        break;
      end
      p(i, stp) = p_(j);
      stp = stp + 1;
    end
  end
  
  continue;
  
  
  %
  %   first
  %
  
  if ( method_one )
  
    t_rounded = ceil( abs(t_) ) .* sign( t_ );
    t_first = t_rounded(1);
    t_last = t_rounded(end);

    matching = t_series >= t_first & t_series <= t_last;
    found_matching = find( matching );

    stp = 1;
    sample_factor = task_data(i).sample_factor;

    for j = 1:sample_factor:numel(found_matching)
      ind = found_matching(j);
      if ( sample_factor == 1 )
        if ( stp > numel(p_) )
          break;
        end
        p(i, ind) = p_(stp);
      else
        assert( task_data(i).sample_factor == 2, 'Sample factor can be 1 or 2.' );
        p(i, ind) = p_(stp);
        p(i, ind+1) = p_(stp);
      end
      stp = stp + 1;
    end

    continue;
  else
  
    %
    %
    %

    n_t = numel( t_ );

    if ( n_t ~= stop-start && n_t ~= (stop-start)/2 )
      bad(i) = true;
      continue;
    end
    
    if ( n_t == (stop-start)/2 && task_data(i).sample_factor ~= 2 )
      bad(i) = true;
      fprintf( '\n Incorrect sample rate.' );
      continue;
    end
    
    if ( unique(diff(t_)) == 2 )
      new_t = zeros( 1, numel(t_) * 2 );
      new_p = zeros( 1, numel(p_) * 2 );
      stp = 1;
      for j = 1:numel(t_)
        new_t(stp) = t_(j);
        new_t(stp+1) = t_(j);
        new_p(stp) = p_(j);
        new_p(stp+1) = p_(j);
        stp = stp + 2;
      end
      p_ = new_p;
      t_ = new_t;
    end

    t(i, :) = t_;
    p(i, :) = p_;
  end
end

t = t_series;

% if ( ~method_one )
%   t = nanmean( t, 1 );
% else
%   t = t_series;
% end

end