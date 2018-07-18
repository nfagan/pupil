function new_data = downsample(data, factor)

assert( factor > 0 && mod(factor, 1) == 0 ...
, 'Sample factor must be an integer > 0' );

for i = 1:size(data, 1)
  dat = downsample( data(i, :), factor );
  if ( i == 1 )
    new_data = nan( size(data, 1), size(dat, 2) );
  end
  new_data(i, :) = dat;
end

end