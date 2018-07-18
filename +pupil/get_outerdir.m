function outer = get_outerdir(inner)

assert( ischar(inner), 'Path must be char.' );

if ( ispc() )
  sep = '\';
else
  sep = '/';
end

components = strsplit( inner, sep );

if ( numel(components) == 1 )
  error( 'Path "%s" has no containing folder.', inner );
end

outer = fullfile( components{1:end-1} );

if ( isunix() )
  outer = fullfile( sep, outer );
end

end