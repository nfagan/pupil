function in_bounds = absolute_threshold(data, lowerb, upperb)

if ( nargin < 3 || isempty(upperb) )
  upperb = Inf;
end

if ( isempty(lowerb) )
  lowerb = -Inf;
end

in_bounds = all( data > lowerb & data < upperb, 2 );

end