function dr = get_dataroot()

rootfile = 'dataroot.mat';
fname = fullfile( pupil.get_pathsdir(), rootfile );

if ( exist(fname, 'file') ~= 2 )
  error( 'No "%s" file found in "%s". Define a data root with pupil.def_dataroot()' ...
    , rootfile, pupil.get_pathsdir() );
end

p = load( fname );
dr = p.(char(fieldnames(p)));

end