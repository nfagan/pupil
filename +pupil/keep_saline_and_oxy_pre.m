function out = keep_saline_and_oxy_pre( cont )

pre_oxy = cont({'oxytocin', 'pre'});
pre_sal = cont({'saline', 'pre'});

out = append( pre_oxy, pre_sal );

end