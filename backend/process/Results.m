classdef (Sealed) Results < handle
    
    properties ( Access = private )
        
        results
        
    end
    
    
    methods ( Access = public )
        
        function obj = Results()
            
            obj.results = containers.Map( ...
                'keytype', 'char', ...
                'valuetype', 'any' ...
                );
            
        end
        
        
        function add( obj, key, result )
            
            obj.results( key ) = result;
            
        end
        
        
        function exist = exists( obj, key )
            
            exist = isKey( obj.results, key );
            
        end
        
        
        function result = get( obj, key )
            
            result = obj.results( key );
            
        end
        
        
        function keyset = get_keys( obj )
            
            keyset = keys( obj.results );
            
        end
        
        
        function count = get_count( obj )
            
            count = numel( obj.get_keys() );
            
        end
        
    end
    
end

