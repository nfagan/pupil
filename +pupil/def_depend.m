function def_depend(name, p, subdir, recursive)

assert( ischar(name), 'Name must be char.' );

if ( nargin < 2 || isempty(p) )
  p = fullfile( pupil.get_repodir(), name );
else
  assert( ischar(p), 'Path must be char.' );
end

if ( nargin < 3 || isempty(subdir) )
  subdir = '';
else
  assert( ischar(subdir), 'Subdir must be char.' );
end

if ( nargin < 4 )
  recursive = false;
else
  assert( islogical(recursive), 'Recursive flag must be logical.' );
end

depdir = pupil.get_dependsdir();

if ( exist(depdir, 'dir') ~= 7 ), mkdir( depdir ); end

dep = struct( 'name', name, 'path', p, 'subdir', subdir, 'recursive', recursive );

save( fullfile(depdir, name), 'dep' );

end