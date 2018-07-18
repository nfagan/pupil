function p = get_projectdir()

basep = fileparts( which(sprintf('pupil.%s', mfilename)) );
p = pupil.get_outerdir( basep );

end