function p = get_projectdir()

basep = fileparts( which(sprintf('pupil.%s', mfilename)) );

if ( ispc() )
  sep = '\';
else
  sep = '/';
end

components = strsplit( basep, sep );

p = fullfile( components{1:end-1} );

end