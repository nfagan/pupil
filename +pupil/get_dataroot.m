function dr = get_dataroot()

%   GET_DATAROOT -- Get absolute path to data root folder.
%
%     Define the root data folder with `pupil.def_dataroot()`
%
%     OUT:
%       - `dr` (char)

rootfile = 'dataroot.mat';
fname = fullfile( pupil.get_pathsdir(), rootfile );

if ( exist(fname, 'file') ~= 2 )
  error( 'No "%s" file found in "%s". Define a data root with pupil.def_dataroot()' ...
    , rootfile, pupil.get_pathsdir() );
end

p = load( fname );
dr = p.(char(fieldnames(p)));

end