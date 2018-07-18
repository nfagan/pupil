function new_data = upsample(data, factor)

assert( factor > 0 && mod(factor, 1) == 0 ...
, 'Sample factor must be an integer > 0' );

new_data = nan( size(data, 1), factor * size(data, 2) );

stp = 1;
for i = 1:size(data, 2)
  for j = 1:factor
    new_data(:, stp) = data(:, i);
    stp = stp + 1;
  end
end

end