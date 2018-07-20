function add_depends()

[files, depdir] = pupil.get_dependfiles();

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