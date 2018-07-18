function [mat, t_series] = align_pupil(evts, t, p, neg_t, pos_t, fs)

import shared_utils.assertions.*;

assert( numel(evts) == size(t, 1), 'Size mismatch between events and time-stamps.' );
assert__sizes_match( 'time and pupil data', t, p );
assert( numel(neg_t) == 1 && numel(pos_t) == 1, 'Specify +/- t values as scalar doubles.' );

did_prealc = false;

pre = NaN;
post = NaN;

n_start_t = -Inf;
n_stop_t = -Inf;
start_t = NaN;
stop_t = NaN;

t( t == 0 ) = NaN;

for i = 1:numel(evts)
  if ( isnan(evts(i)) || all(isnan(t(i, :))) ), continue; end
  
  if ( evts(i) == 0 )
    ind = 1;
  else
    [~, ind] = min( abs(t(i, :) - evts(i)) );
  end
  
  assert( ind ~= numel(t(i, :)) ...
    , 'Event time does not correspond to pupil time-stamps.' );
  
  pre_t = t(i, :) >= t(i, ind) + neg_t & t(i, :) < t(i, ind);
  post_t = t(i, :) <= t(i, ind) + pos_t & t(i, :) >= t(i, ind);
  
  if ( ~did_prealc )
    pre = nan( numel(evts), sum(pre_t) );
    post = nan( numel(evts), sum(post_t) );
    did_prealc = true;
  end
  
  post(i, 1:sum(post_t)) = p(i, post_t);
  pre(i, 1:sum(pre_t)) = fliplr(p(i, pre_t));
  
  if ( sum(post_t) > n_stop_t )
    stop_t = t(i, find(post_t, 1, 'last')) - t(i, ind);
    n_stop_t = sum( post_t );
  end
  
  if ( sum(pre_t) > n_start_t )
    start_t = t(i, find(pre_t, 1, 'first')) - t(i, ind);
    n_start_t = sum( pre_t );
  end
end

mat = [ fliplr(pre), post ];

start_t = round( start_t * 1e3 ) / 1e3;
stop_t = round( stop_t * 1e3 ) / 1e3;

t_series = start_t:fs:stop_t;

assert( numel(t_series) == size(mat, 2), 'Wrong sample rate provided.' );

end