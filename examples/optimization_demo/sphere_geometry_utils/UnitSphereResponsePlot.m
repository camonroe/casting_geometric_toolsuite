classdef (Sealed) UnitSphereResponsePlot < handle
    
    methods ( Access = public )
        
        function obj = UnitSphereResponsePlot( ...
                unit_sphere_response_data, ...
                unit_sphere_response_axes, ...
                figure_resolution_px ...
                )
            
            obj.response_data = unit_sphere_response_data;
            
            obj.figure_h = obj.create_base_figure( ...
                figure_resolution_px, ...
                obj.response_data.get_name(), ...
                obj.response_data.get_all_titles() ...
                );
            
            obj.response_axes = unit_sphere_response_axes;
            [ phi_grid, theta_grid ] = obj.response_data.get_grid_in_degrees();
            obj.response_axes.create_axes( ...
                obj.figure_h, ...
                @obj.ui_axes_button_down_Callback, ...
                phi_grid, ...
                theta_grid ...
                );
            
            obj.update_surface_plots();
            
        end
        
    end
    
    
    properties ( Access = private )
        
        response_data
        response_axes
        
        figure_h
        
        static_text_h
        
        listbox_h
        old_listbox_value
        
        visualize_button_h
        
        quantile_checkbox_h
        quantile_value_edit_text_h
        old_quantile_value
        
    end
    
    
    properties ( Access = private, Constant )
        
        QUANTILE_OFF = false;
        QUANTILE_ON = true;
        
        QUANTILE_MIN = 0.0;
        QUANTILE_MAX = 1.0;
        INITIAL_QUANTILE_VALUE = 0.01;
        
        MINIMA_OFF = false;
        MINIMA_ON = true;
        
        PARETO_FRONT_OFF = false;
        PARETO_FRONT_ON = true;
        
    end
    
    
    methods ( Access = private )
        
        function figure_h = create_base_figure( obj, ...
                figure_resolution_px, ...
                component_name, ...
                titles ...
                )
            
            widgets = UnitSphereResponsePlotWidgets( figure_resolution_px );
            
            figure_h = widgets.create_figure( component_name );
            
            obj.static_text_h = widgets.add_point_information_text( figure_h );
            
            obj.listbox_h = widgets.add_objective_selection_listbox( ...
                figure_h, ...
                titles, ...
                @obj.ui_objective_selection_listbox_Callback ...
                );
            obj.old_listbox_value = obj.get_objective_index();
            
            obj.visualize_button_h = widgets.add_visualize_button( ...
                figure_h, ...
                @obj.ui_visualize_button_Callback ...
                );
            
            [ obj.quantile_checkbox_h, obj.quantile_value_edit_text_h ] = ...
                widgets.add_quantile_widgets( ...
                obj.INITIAL_QUANTILE_VALUE, ...
                figure_h, ...
                @obj.ui_quantile_checkbox_Callback, ...
                @obj.ui_quantile_value_edit_text_Callback ...
                );
            obj.quantile_checkbox_h.Min = obj.QUANTILE_OFF;
            obj.quantile_checkbox_h.Max = obj.QUANTILE_ON;
            obj.quantile_checkbox_h.Value = obj.QUANTILE_OFF;
            obj.old_quantile_value = obj.get_quantile_value();
            
            [ minima_checkbox_h, pareto_front_checkbox_h ] = ...
                widgets.add_point_plot_widgets( ...
                figure_h, ...
                @obj.ui_minima_checkbox_Callback, ...
                @obj.ui_pareto_front_checkbox_Callback ...
                );
            minima_checkbox_h.Min = obj.MINIMA_OFF;
            minima_checkbox_h.Max = obj.MINIMA_ON;
            minima_checkbox_h.Value = obj.MINIMA_OFF;
            pareto_front_checkbox_h.Min = obj.PARETO_FRONT_OFF;
            pareto_front_checkbox_h.Max = obj.PARETO_FRONT_ON;
            pareto_front_checkbox_h.Value = obj.PARETO_FRONT_OFF;
            
        end
        
        
        function ui_objective_selection_listbox_Callback( obj, ~, ~, ~ )
            
            if obj.get_objective_index() ~= obj.old_listbox_value
                obj.update_surface_plots();
                obj.update_minima();
                obj.update_old_listbox_value();
            end
            
        end
        
        
        function ui_quantile_checkbox_Callback( obj, ~, ~, ~ )
            
            obj.update_surface_plots();
            drawnow();
            
        end
        
        
        function ui_quantile_value_edit_text_Callback( obj, ~, ~, ~ )
            
            obj.constrain_quantile_value();
            if obj.get_quantile_value() ~= obj.old_quantile_value
                obj.update_surface_plots();
                obj.update_old_quantile_value();
            end
            drawnow();
            
        end
        
        
        function constrain_quantile_value( obj )
            
            value = obj.get_quantile_value();
            
            if isnan( value )
                obj.set_quantile_value( obj.old_quantile_value );
            end
            
            if obj.QUANTILE_MAX < value
                obj.set_quantile_value( obj.QUANTILE_MAX );
            elseif value < obj.QUANTILE_MIN
                obj.set_quantile_value( obj.QUANTILE_MIN );
            end
            
        end
        
        
        function ui_minima_checkbox_Callback( obj, handle, ~, ~ )
            
            switch handle.Value
                case obj.MINIMA_OFF
                    obj.response_axes.remove_minima();
                case obj.MINIMA_ON
                    obj.update_minima();
                otherwise
                    assert( false );
            end
            drawnow();
            
        end
        
        
        function update_minima( obj )
            
            obj.response_axes.update_minima( obj.get_minima_decisions() );
            
        end
        
        
        function decisions = get_minima_decisions( obj )
            
            decisions = obj.response_data.get_minima_decisions_in_degrees( ...
                obj.get_objective_index() ...
                );
            
        end
        
        
        function ui_pareto_front_checkbox_Callback( obj, handle, ~, ~ )
            
            switch handle.Value
                case obj.PARETO_FRONT_OFF
                    obj.response_axes.remove_pareto_fronts();
                case obj.PARETO_FRONT_ON
                    obj.response_axes.update_pareto_fronts( ...
                        obj.get_pareto_front_decisions() ...
                        );
                otherwise
                    assert( false );
            end
            drawnow();
            
        end
        
        
        function decisions = get_pareto_front_decisions( obj )
            
            decisions = obj.response_data.get_pareto_front_decisions_in_degrees();
            
        end
        
        
        function ui_visualize_button_Callback( obj, h, ~, ~ )
            
            fprintf( 'not yet implemented\n' );
            return;
            % attach options when running on hpc so we are consistent
            % attach stl when running etc etc
            % add both paths to result table
            obc = OrientationBaseCase( ...
                obj.option_path, ...
                obj.stl_path, ...
                obj.objective_variables_path ...
                );
            % attach observer for status updates?
            % factor out feature computation from determine_objectives in obc
            % generate desired visualization based on results table, i.e. using
            %  "process" and the appropriate visualization method
            % create new figure etc
            % display vis in figure
            
        end
        
        
        function ui_axes_button_down_Callback( obj, h, ~, ~ )
            
            point_values = gcpmap( h );
            phi = point_values( 1, 2 );
            theta = point_values( 1, 1 );
            [ phi_index, theta_index ] = ...
                obj.get_grid_indices_from_decisions( phi, theta );
            value = num2str( obj.get_objective_value( theta_index, phi_index ) );
            degrees = char( 176 );
            pattern = [ ...
                'Selected Point is @X: %.2f' degrees ...
                ', @Y: %.2f' degrees ...
                ', Value: %s' ...
                ];
            obj.static_text_h.String = sprintf( pattern, phi, theta, value );
            
        end
        
        
        function [ phi_index, theta_index ] = get_grid_indices_from_decisions( ...
                obj, ...
                phi, ...
                theta ...
                )
            
            [ phi_index, theta_index ] = ...
                obj.response_data.get_grid_indices_from_decisions( phi, theta );
            
        end
        
        
        function update_surface_plots( obj )
            
            obj.response_axes.update_surface_plots( obj.get_surface_plot_values() );
            
        end
        
        
        function values = get_surface_plot_values( obj )
            
            switch obj.get_quantile_state()
                case obj.QUANTILE_OFF
                    values = obj.get_objective_values();
                case obj.QUANTILE_ON
                    values = obj.get_quantile_values();
                otherwise
                    assert( false );
            end
            
        end
        
        
        function state = get_quantile_state( obj )
            
            state = obj.quantile_checkbox_h.Value;
            
        end
        
        
        function update_old_listbox_value( obj )
            
            obj.old_listbox_value = obj.get_objective_index();
            
        end
        
        
        function update_old_quantile_value( obj )
            
            obj.old_quantile_value = obj.get_quantile_value();
            
        end
        
        
        function set_quantile_value( obj, value )
            
            obj.quantile_value_edit_text_h.String = num2str( value );
            
        end
        
        
        function value = get_objective_value( obj, phi_index, theta_index )
            
            value = obj.response_data.get_objective_value( ...
                phi_index, ...
                theta_index, ...
                obj.get_objective_index() ...
                );
            
        end
        
        
        function values = get_objective_values( obj )
            
            values = obj.response_data.get_objective_values( ...
                obj.get_objective_index() ...
                );
            
        end
        
        
        function values = get_quantile_values( obj )
            
            values = obj.response_data.get_quantile_values( ...
                obj.get_quantile_value(), ...
                obj.get_objective_index() ...
                );
            values = double( values );
            
        end
        
        
        function value = get_objective_index( obj )
            
            value = obj.listbox_h.Value;
            
        end
        
        
        function value = get_quantile_value( obj )
            
            value = str2double( obj.quantile_value_edit_text_h.String );
            
        end
        
    end
    
end

