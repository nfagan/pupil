function lab = relabel_outcome( lab, kind )

import shared_utils.assertions.*;

assert__isa( lab, 'char', 'the label' );
assert__isa( kind, 'char', 'the kind of label' );

assert( any(strcmp({'outcome', 'rewarded_by'}, kind)) ...
  , 'Unrecognized relabel kind "%s".', kind );

found = false;
out = struct();

if ( strcmpi(lab, 'no choice m1 rwd') )
  out.outcome = 'self';
  out.rewarded_by = 'experimenter';
  found = true;
end

if ( strcmpi(lab, 'no choice m1m2 rwd') )
  out.outcome = 'both';
  out.rewarded_by = 'experimenter';
  found = true;
end

if ( strcmpi(lab, 'no choice m2 rwd') )
  out.outcome = 'other';
  out.rewarded_by = 'experimenter';
  found = true;
end

if ( strcmpi(lab, 'no choice none rwd') )
  out.outcome = 'none';
  out.rewarded_by = 'experimenter';
  found = true;
end

if ( strcmpi(lab, 'm1 chose to reward m1') )
  out.outcome = 'self';
  out.rewarded_by = 'm1';
  found = true;
end

if ( strcmpi(lab, 'm1 chose to reward m1+m2') )
  out.outcome = 'both';
  out.rewarded_by = 'm1';
  found = true;
end

if ( strcmpi(lab, 'm1 chose to reward m2') )
  out.outcome = 'other';
  out.rewarded_by = 'm1';
  found = true;
end

if ( strcmpi(lab, 'm1 chose to reward none') )
  out.outcome = 'none';
  out.rewarded_by = 'm1';
  found = true;
end

if ( strcmpi(lab, 'm1 rewarded by experimenter') )
  out.outcome = 'self';
  out.rewarded_by = 'experimenter';
  found = true;
end

if ( strcmpi(lab, 'm1 rewarded by m1 saccade') )
  out.outcome = 'self';
  out.rewarded_by = 'm1';
  found = true;
end

if ( strcmpi(lab, 'm1+m2 both rewarded by experimenter') )
  out.outcome = 'both';
  out.rewarded_by = 'experimenter';
  found = true;
end

if ( strcmpi(lab, 'm1+m2 both rewarded by m1 saccade') )
  out.outcome = 'both';
  out.rewarded_by = 'm1';
  found = true;
end

if ( strcmpi(lab, 'm1+m2 not rewarded by experimenter') )
  out.outcome = 'none';
  out.rewarded_by = 'experimenter';
  found = true;
end

if ( strcmpi(lab, 'm1+m2 not rewarded by m1 saccade') )
  out.outcome = 'none';
  out.rewarded_by = 'm1';
  found = true;
end

if ( strcmpi(lab, 'm2 rewarded by experimenter') )
  out.outcome = 'other';
  out.rewarded_by = 'experimenter';
  found = true;
end

if ( strcmpi(lab, 'm2 rewarded by m1 saccade') )
  out.outcome = 'other';
  out.rewarded_by = 'm1';
  found = true;
end

if ( ~found )
  error( 'Unrecognized label type "%s".', lab );
end

lab = out.(kind);

end