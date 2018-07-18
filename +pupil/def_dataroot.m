function def_dataroot(dr)

assert( ischar(dr), 'Path must be char.' );

pathsdir = pupil.get_pathsdir();

save( fullfile(pathsdir, 'dataroot.mat'), 'dr' );

end