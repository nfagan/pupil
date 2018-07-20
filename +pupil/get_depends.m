function dep = get_depends()

[files, depdir] = pupil.get_dependfiles();

for i = 1:numel(files)
  s = load( fullfile(depdir, files{i}) );
  dep(i) = s.(char(fieldnames(s)));
end

end