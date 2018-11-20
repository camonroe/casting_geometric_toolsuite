function generate_csvs_on_hpc( input_path, option_path, angles, index, id, output_mat_dir )

opt = OrientationBaseCase( option_path, input_path );
results = opt.determine_results_as_table( angles );
filename = sprintf( ...
    'results_%s_%i_%i.csv', ...
    opt.get_name(), ...
    id, ...
    index );
writetable( results, fullfile( output_mat_dir, filename ) );

end