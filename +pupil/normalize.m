function data = normalize(data, baseline, method)

import shared_utils.assertions.*;

assert__isa( data, 'double' );
assert__isa( baseline, 'double' );
assert__isa( method, 'char' );

assert( size(data, 1) == numel(baseline) ...
  , 'Dimension mismatch between baseline and to-normalize data.' );

for i = 1:size(data, 2)
  if ( strcmp(method, 'divide') )
    data(:, i) = data(:, i) ./ baseline;
  elseif ( strcmp(method, 'subtract') )
    data(:, i) = data(:, i) - baseline;
  else
    error( 'Unrecognized normalization method "%s".', method );
  end
end

end