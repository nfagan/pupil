function mp = get_event_name_map(reverse)

mp = containers.Map();
mp( 'fixOn' ) = 'fixation on';
mp( 'targOn' ) = 'target on';
mp( 'targAcq' ) = 'target acquire';
mp( 'rwdOn' ) = 'reward';

if ( ~reverse )
  return;
end

vals = mp.values();
kys = mp.keys();

mp2 = containers.Map();

for i = 1:numel(kys)
  mp2(vals{i}) = kys{i};
end

mp = mp2;


end