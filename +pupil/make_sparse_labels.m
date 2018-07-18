function sp = make_sparse_labels(lab, key, avoid_prefix)

import shared_utils.assertions.*;

assert__isa( lab, 'cell' );
assert__is_cellstr( key, 'the key' );

assert( numel(key) == size(lab, 2), 'The key does not correspond to the given labels.' );

if ( nargin < 3 )
  avoid_prefix = {};
end

avoid_prefix = shared_utils.cell.ensure_cell( avoid_prefix );
assert__is_cellstr( avoid_prefix );

assert( isequal(intersect(key, avoid_prefix), sort(avoid_prefix)) ...
  , 'some of the values to avoid prefixing are not present in the key.' );

rest = key;

all_labs = struct();

for i = 1:numel(rest)
  a_ind = strcmp( key, rest{i} );
  orig = lab(:, a_ind);
  for j = 1:numel(orig)
    if ( ~ischar(orig{j}) )
      assert( isa(orig{j}, 'double') && mod(orig{j}, 1) == 0, 'Values can be string or int.' );
      val = sprintf( '%d', orig{j} );
    else
      val = orig{j};
    end
    if ( ~any(strcmp(avoid_prefix, rest{i})) )
      orig{j} = sprintf( '%s__%s', rest{i}, val );
    else
      orig{j} = val;
    end
  end
  all_labs.(rest{i}) = orig;
end


sp = SparseLabels( all_labs );


end