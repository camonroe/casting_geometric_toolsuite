classdef (Sealed) UnitSphereResponseData < handle
    
    methods ( Access = public )
        
        function obj = UnitSphereResponseData( ...
                results, ...
                figure_resolution_px, ...
                objective_variables_path ...
                )
            
            if nargin < 3
                objective_variables_path = results.Properties.UserData.ObjectiveVariablesPath;
            end
            
            if isfile( objective_variables_path )
                objective_variables = ObjectiveVariables( objective_variables_path );
            else
                warning( ...
                    [ 'Unable to find objective variables at %s\n' ...
                    'Using default titles and interpolation methods.\n' ], ...
                    objective_variables_path ...
                    );
                objective_start_column = results.Properties.UserData.ObjectiveStartColumn;
                objective_count = size( results, 2 ) - objective_start_column + 1;
                titles = strcat( 'objective ', string( 1 : objective_count ) );
                [ methods{ 1 : objective_count } ] = deal( 'natural' );
                objective_variables = ObjectiveVariables( titles, methods );
            end
            
            options_path = results.Properties.UserData.OptionsPath;
            if isempty( options_path )
                obj.options_path = which( 'oo_options.json' );
            else
                obj.options_path = options_path;
            end
            
            obj.objective_variables = objective_variables;
            obj.stl_path = results.Properties.UserData.StlPath;
            obj.name = results.Properties.UserData.Name;
            obj.titles = objective_variables.get_titles();
            
            interpolants = obj.generate_interpolants( results, objective_variables );
            
            interpolant_resolution = figure_resolution_px / 2;
            [ phi_resolution, theta_resolution ] = ...
                unit_sphere_grid_resolution( interpolant_resolution );
            [ obj.phi_grid, obj.theta_grid ] = ...
                unit_sphere_mesh_grid( interpolant_resolution );
            obj.objective_values = obj.generate_objective_values( ...
                interpolants, ...
                obj.phi_grid, ...
                obj.theta_grid, ...
                phi_resolution, ...
                theta_resolution ...
                );
            
            obj.minima_decisions = obj.generate_minima_decisions( ...
                obj.objective_values, ...
                results, ...
                obj.phi_grid, ...
                obj.theta_grid ...
                );
            
            obj.pareto_front_decisions = ...
                obj.generate_pareto_front_decisions( results );
            
            obj.quantile_interpolants = obj.generate_quantile_interpolants( ...
                obj.objective_values, ...
                objective_variables, ...
                obj.theta_grid ...
                );
            
        end
        
        
        function variables = get_objective_variables( obj )
            
            variables = obj.objective_variables;
            
        end
        
        
        function path = get_options_path( obj )
            
            path = obj.options_path;
            
        end
        
        
        function path = get_stl_path( obj )
            
            path = obj.stl_path;
            
        end
        
        
        function name = get_name( obj )
            
            name = obj.name;
            
        end
        
        
        function title = get_title( obj, objective_index )
            
            title = obj.titles{ objective_index };
            
        end
        
        
        function titles = get_all_titles( obj )
            
            titles = obj.titles;
            
        end
        
        
        function value = get_objective_value( ...
                obj, ...
                phi_index, ...
                theta_index, ...
                objective_index ...
                )
            
            value = obj.objective_values( ...
                phi_index, ...
                theta_index, ...
                objective_index ...
                );
            
        end
        
        
        function values = get_objective_values( obj, objective_index )
            
            values = obj.objective_values( :, :, objective_index );
            
        end
        
        
        function values = get_quantile_values( obj, quantile, objective_index )
            
            values = obj.get_objective_values( objective_index );
            threshold = obj.get_quantile_threshold_value( ...
                quantile, ...
                objective_index ...
                );
            values = values < threshold;
            
        end
        
        
        function decisions = get_minima_decisions_in_degrees( ...
                obj, ...
                objective_index ...
                )
            
            decisions = rad2deg( obj.minima_decisions( objective_index, : ) );
            
        end
        
        
        function decisions = get_pareto_front_decisions_in_degrees( obj )
            
            decisions = rad2deg( obj.pareto_front_decisions );
            
        end
        
        
        function value = get_quantile_threshold_value( ...
                obj, ...
                quantile, ...
                objective_index ...
                )
            
            if quantile < 0.0 || 1.0 < quantile
                assert( false );
            end
            value = obj.quantile_interpolants{ objective_index }( quantile );
            
        end
        
        
        function [ phi_grid, theta_grid ] = get_grid_in_degrees( obj )
            
            phi_grid = rad2deg( obj.phi_grid );
            theta_grid = rad2deg( obj.theta_grid );
            
        end
        
        
        function [ phi_grid, theta_grid ] = get_grid_in_radians( obj )
            
            phi_grid = obj.phi_grid;
            theta_grid = obj.theta_grid;
            
        end
        
        
        function [ phi_index, theta_index ] = get_grid_indices_from_decisions( ...
                obj, ...
                phi, ...
                theta ...
                )
            
            phi_index = round( ...
                ( deg2rad( phi ) + pi ) ...
                * size( obj.phi_grid, 2 ) ...
                ./ ( 2 * pi ) ...
                );
            theta_index = round( ...
                ( deg2rad( theta ) + pi/2 ) ...
                * size( obj.theta_grid, 1 ) ...
                ./ pi ...
                );
            
        end
        
        
        function [ phi, theta ] = get_grid_decisions_from_indices_in_radians( ...
                obj, ...
                phi_index, ...
                theta_index ...
                )
            
            phi = obj.phi_grid( 1, phi_index );
            theta = obj.theta_grid( theta_index, 1 );
            
        end
        
    end
    
    
    properties ( Access = private )
        
        objective_variables
        options_path
        stl_path
        name
        titles
        phi_grid
        theta_grid
        objective_values
        minima_decisions
        pareto_front_decisions
        quantile_interpolants
        
    end
    
    
    methods ( Access = private, Static )
        
        function interpolants = generate_interpolants( ...
                results, ...
                objective_variables ...
                )
            
            objective_count = objective_variables.get_objective_count();
            decision_count = results.Properties.UserData.DecisionEndColumn;
            interpolants = cell( objective_count, 1 );
            for i = 1 : objective_count
                
                interpolants{ i } = generate_unit_sphere_scattered_interpolant( ...
                    results{ :, 1 : decision_count }, ...
                    results{ :, objective_variables.get_title( i ) }, ...
                    objective_variables.get_interpolation_method( i ) ...
                    );
                
            end
            
        end
        
        
        function values = generate_objective_values( ...
                interpolants, ...
                phi_grid, ...
                theta_grid, ...
                phi_resolution, ...
                theta_resolution ...
                )
            
            objective_count = numel( interpolants );
            values = nan( theta_resolution, phi_resolution, objective_count );
            for i = 1 : objective_count
                
                values( :, :, i ) = interpolants{ i }( ...
                    phi_grid, ...
                    theta_grid ...
                    );
                
            end
            assert( ~any( isnan( values( : ) ) ) );
            
        end
        
        
        function decisions = generate_minima_decisions( ...
                objective_values, ...
                results, ...
                phi_grid, ...
                theta_grid ...
                )
            
            objective_count = size( objective_values, 3 );
            decision_count = results.Properties.UserData.DecisionEndColumn;
            decisions = nan( objective_count, decision_count );
            for i = 1 : objective_count
                
                values = objective_values( :, :, i );
                [ ~, index ] = min( values( : ) );
                decisions( i, : ) = [ phi_grid( index ) theta_grid( index ) ];
                
            end
            assert( ~any( isnan( decisions( : ) ) ) );
            
        end
        
        
        function decisions = generate_pareto_front_decisions( results )
            
            decisions( :, : ) = [ ...
                results.phi( results.is_pareto_dominant ) ...
                results.theta( results.is_pareto_dominant ) ...
                ];
            
        end
        
        
        function quantile_interpolants = generate_quantile_interpolants( ...
                objective_values, ...
                objective_variables, ...
                theta_grid ...
                )
            
            objective_count = size( objective_values, 3 );
            quantile_interpolants = cell( objective_count );
            for i = 1 : objective_count
                
                quantile_interpolants{ i } = generate_unit_sphere_quantile_interpolant( ...
                    theta_grid, ...
                    objective_values( :, :, i ), ...
                    objective_variables.get_interpolation_method( i ) ...
                    );
                
            end
            
        end
        
    end
    
end
