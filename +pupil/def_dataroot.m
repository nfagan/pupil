function def_dataroot(dr)

assert( ischar(dr), 'Path must be char.' );

pathsdir = pupil.get_pathsdir();

if ( exist(pathsdir, 'dir') ~= 7 ), mkdir( pathsdir ); end

save( fullfile(pathsdir, 'dataroot.mat'), 'dr' );

end