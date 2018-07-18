function in_bounds = std_threshold( data, ndevs )

time_mean = nanmean( data, 2 );
global_mean = nanmean( time_mean );
global_dev = nanstd( time_mean );

in_bounds = time_mean > (global_mean - global_dev * ndevs ) & ...
  time_mean < ( global_mean + global_dev * ndevs );

end