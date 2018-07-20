function [files, depdir] = get_dependfiles()

depdir = pupil.get_dependsdir();
files = dir( fullfile(depdir, '*.mat') );
files = { files(:).name };

end