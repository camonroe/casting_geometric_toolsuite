classdef (Sealed) WidgetFactory < handle
    
    methods ( Access = public )
        
        function obj = WidgetFactory( resolution_px )
        
            obj.figure_position = obj.compute_figure_position( resolution_px );
            obj.previous_position = obj.figure_position;
            
        end
        
        
        function handle = create_figure( obj, name )
            
            handle = figure();
            handle.Name = sprintf( 'Orientation Data for %s', name );
            handle.NumberTitle = 'off';
            handle.Position = obj.figure_position;
            handle.MenuBar = 'none';
            handle.ToolBar = 'none';
            handle.DockControls = 'off';
            handle.Resize = 'off';
            movegui( handle, 'center' );
            
        end
        
        
        function pos = adjust_axes_position( obj, pos )
            
            pos = [ ...
                obj.center( pos( 3 ) ), ...
                obj.above_previous(), ...
                pos( 3 ), ...
                pos( 4 ) ...
                ];
            
        end
        
        
        function handle = add_point_information_text( obj, figure_handle )
            
            TEXT_WIDTH = 600;
            handle = uicontrol();
            handle.Style = 'text';
            handle.String = 'Click on the axes to get point data!';
            handle.FontSize = obj.FONT_SIZE;
            handle.Position = [ ...
                obj.center( TEXT_WIDTH ), ...
                obj.at_top_edge( obj.HEIGHT ) ...
                TEXT_WIDTH ...
                obj.HEIGHT ...
                ];
            handle.Parent = figure_handle;
            
            obj.previous_position = handle.Position;
            
        end
        
        
        function handle = add_objective_selection_listbox( ...
                obj, ...
                figure_handle, ...
                titles, ...
                callback ...
                )
            
            LISTBOX_WIDTH = 300;
            handle = uicontrol();
            handle.Style = 'popupmenu';
            handle.String = titles;
            handle.FontSize = obj.FONT_SIZE;
            handle.Value = obj.INITIAL_LISTBOX_VALUE;
            handle.Position = [ ...
                obj.center( LISTBOX_WIDTH ) ...
                obj.below_previous( obj.HEIGHT ) ...
                LISTBOX_WIDTH ...
                obj.HEIGHT ...
                ];
            handle.Callback = callback;
            handle.Parent = figure_handle;
            
            obj.previous_position = handle.Position;
            
        end
        
        
        function handle = add_visualize_button( obj, figure_handle, callback )
            
            BUTTON_WIDTH = 200;
            handle = uicontrol();
            handle.Style = 'pushbutton';
            handle.String = 'Visualize Picked Point...';
            handle.FontSize = obj.FONT_SIZE;
            handle.Position = [ ...
                obj.center( BUTTON_WIDTH ) ...
                obj.at_bottom_edge() ...
                BUTTON_WIDTH ...
                obj.HEIGHT ...
                ];
            handle.Callback = callback;
            handle.Parent = figure_handle;
            
            obj.previous_position = handle.Position;
            
        end
        
        
        function [ left_handle, right_handle ] = add_point_plot_widgets( ...
                obj, ...
                figure_handle, ...
                left_callback, ...
                right_callback ...
                )
            
            LEFT_WIDTH = 120;
            x_pos = obj.split_across_center( LEFT_WIDTH );
            
            left_handle = uicontrol();
            left_handle.Style = 'checkbox';
            left_handle.String = 'Show Minimum';
            left_handle.FontSize = obj.FONT_SIZE;
            left_handle.Position = [ ...
                x_pos( 1 ) ...
                obj.above_previous() ...
                LEFT_WIDTH ...
                obj.HEIGHT ...
                ];
            left_handle.Callback = left_callback;
            left_handle.Parent = figure_handle;
            
            RIGHT_WIDTH = 140;
            right_handle = uicontrol();
            right_handle.Style = 'checkbox';
            right_handle.String = 'Show Pareto Front';
            right_handle.FontSize = obj.FONT_SIZE;
            right_handle.Position = [ ...
                x_pos( 2 ) ...
                obj.above_previous() ...
                RIGHT_WIDTH ...
                obj.HEIGHT ...
                ];
            right_handle.Callback = right_callback;
            right_handle.Parent = figure_handle;
            
            obj.previous_position = right_handle.Position;
            
        end
        
        
        function h = add_thresholding_widget( ...
                obj, ...
                figure_handle, ...
                value_picker_fns, ...
                labels, ...
                default_mins, ...
                default_maxs, ...
                default_values, ...
                selection_changed_function, ...
                edit_text_callback, ...
                slider_callback ...
                )
            
            x = obj.center( ThresholdingWidgets.get_width );
            y = obj.above_previous();
            h = ThresholdingWidgets( ...
                figure_handle, ...
                [ x, y ], ...
                obj.VERTICAL_PAD, ...
                obj.FONT_SIZE, ...
                value_picker_fns, ...
                labels, ...
                default_mins, ...
                default_maxs, ...
                default_values, ...
                selection_changed_function, ...
                edit_text_callback, ...
                slider_callback ...
                );
            
            obj.previous_position = h.get_position();
            
        end
        
    end
    
    
    properties ( Access = private )
        
        figure_position
        previous_position
        
    end
    
    
    properties ( Access = private, Constant )
        
        MIN_RESOLUTION = 300;
        VERTICAL_PAD = 6;
        HORIZONTAL_PAD = 6;
        HEIGHT = 23;
        
        FONT_SIZE = 10;
        
        INITIAL_LISTBOX_VALUE = 1;
        
    end
    
    
    methods ( Access = private )
        
        function y_pos = at_top_edge( obj, height )
            
            y_pos = obj.figure_position( 4 ) ...
                - obj.VERTICAL_PAD ...
                - height ...
                - 1;
            
        end
        
        
        function y_pos = at_bottom_edge( obj )
            
            y_pos = obj.VERTICAL_PAD ...
                + 1;
            
        end
        
        
        function y_pos = below_previous( obj, height )
            
            y_pos = obj.previous_position( 2 ) ...
                - obj.VERTICAL_PAD ...
                - height;
            
        end
        
        
        function y_pos = above_previous( obj )
            
            y_pos = obj.previous_position( 2 ) ...
                + obj.previous_position( 4 ) ...
                + obj.VERTICAL_PAD;
            
        end
        
        
        function x_pos = center( obj, widget_width )
            
            x_pos = round( obj.figure_position( 3 ) / 2 ) ...
                - round( widget_width / 2 ) ...
                + 1;
            
        end
        
        
        function x_pos = split_across_center( obj, left_widget_width )
            
            x_pos = [ ...
                obj.center( obj.HORIZONTAL_PAD ) - left_widget_width ...
                obj.center( -obj.HORIZONTAL_PAD ) ...
                ];
            
        end
        
    end
    
    
    methods ( Access = private, Static )
        
        function pos = compute_figure_position( resolution_px )
            
            assert( resolution_px >= UnitSphereResponsePlotWidgets.MIN_RESOLUTION );
            pos = [ ...
                0, ...
                0, ...
                1.8 * resolution_px + 1, ...
                1.1 * make_odd( resolution_px ) ...
                ];
            
        end
        
    end
    
end
