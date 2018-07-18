function add_depends()

depdir = fullfile( pupil.get_dependsdir() ); 
files = dir( fullfile(depdir, '*.mat') );
files = { files(:).name };

for i = 1:numel(files)
  s = load( fullfile(depdir, files{i}) );
  dep = s.(char(fieldnames(s)));
  
  path = fullfile( dep.path, dep.subdir );
  
  if ( dep.recursive )
    path = genpath( path );
  end
  
  addpath( path );
end

end