pup_dir = 'E:\nick_data\jessica\raw_data\old_pupil';
save_dir = 'E:\nick_data\jessica\processed_data\old_pupil2';

outer_folders = shared_utils.io.dirnames( pup_dir, 'folders' );

stp = 1;

for idx = 1:numel(outer_folders)
  fprintf( '\n %d of %d', idx, numel(outer_folders) );
  outer_folder = outer_folders{idx};
  sub_folders = shared_utils.io.dirnames( fullfile(pup_dir, outer_folder), 'folders' );
 
  for j = 1:numel(sub_folders)
    fprintf( '\n\t %d of %d', j, numel(sub_folders) );
  
    folder = fullfile( pup_dir, outer_folder, sub_folders{j} );
    
    date_str = datestr( sub_folders{j}(1:10) );

    files = shared_utils.io.dirnames( folder, '.mat' );

    out = false( size(files) );
    bad_files = out;

    for i = 1:numel(files)      
      file = files{i};
      
      if ( strcmp(file(1:3), 'xxx') ), continue; end

      data = load( fullfile(folder, file) );
      data = data.(char(fieldnames(data)));

      if ( ~data(1).Error )
        [task_data_, labels_, key] = pupil.process_file( data, file, date_str );
        if ( i == 1 && idx == 1 && j == 1 )
          task_data = task_data_;
          labels = cell( 1, numel(key) ); 
          labels(1, :) = labels_;
          labels(1, end+1) = { lower(outer_folder) };
        else
          task_data(stp) = task_data_;
          labels(stp, :) = [ labels_, lower(outer_folder) ];
        end
        key{end+1} = 'session_type';
        stp = stp + 1;
      end
    end
  end
end

percell = @(varargin) cellfun( varargin{:}, 'un', false );

outcomes = labels(:, strcmp(key, 'outcome'));

outs = percell( @(x) pupil.relabel_outcome(x, 'outcome'), outcomes );
rewarded_by = percell( @(x) pupil.relabel_outcome(x, 'rewarded_by'), outcomes );

labels(:, strcmp(key, 'outcome')) = outs;
labels(:, end+1) = rewarded_by;
key{end+1} = 'rewarded_by';

save( fullfile(save_dir, 'pupil.mat'), 'task_data', 'labels', 'key' );

