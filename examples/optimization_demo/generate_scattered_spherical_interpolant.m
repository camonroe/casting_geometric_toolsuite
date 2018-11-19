% modified from
% user Sven
% originally posted 29 Aug 2012
% https://www.mathworks.com/matlabcentral/answers/46922-correctly-wrap-data-for-spherical-interpolation#answer_57341

function interpolant = generate_scattered_spherical_interpolant( ...
    angles, ...
    values, ...
    interp_method ...
    )

WRAP_AMOUNT = pi / 4;

[ phi_range, theta_range ] = unit_sph_ranges();
phi_wrap_bounds = [ ...
    phi_range( 1 ) + WRAP_AMOUNT ...
    phi_range( 2 ) - WRAP_AMOUNT ...
    ];
phi_wrap_range = [ ...
    phi_range( 1 ) - WRAP_AMOUNT ...
    phi_range( 2 ) + WRAP_AMOUNT ...
    ];


phis = angles( :, 1 );
fringe_indices = find( ...
    phis < phi_wrap_bounds( 1 ) ...
    | phis > phi_wrap_bounds( 2 ) ...
    );
fringe = phis( fringe_indices );
fringe = sign(fringe) .* ( abs(fringe) - 2*pi );

%pole_resolution = ( 2 * WRAP_AMOUNT + 2 * pi ) / ( 2 * pi ) * resolution * 2 + 1;
pole_resolution = length( unique( fringe ) ) ./ 2;
pole_phis = linspace( phi_wrap_range( 1 ), phi_wrap_range( 2 ), pole_resolution ).';
thetas = angles( :, 2 );
south_pole_index = find( thetas == theta_range( 1 ) );
if isempty( south_pole_index )
    [ ~, south_pole_index ] = min( thetas );
end
south_pole = [ pole_phis repmat( [ theta_range( 1 ) south_pole_index ], size( pole_phis ) ) ];


north_pole_index = find( thetas == theta_range( 2 ) );
if isempty( north_pole_index )
    [ ~, north_pole_index ] = max( thetas );
end
north_pole = [ pole_phis repmat( [ theta_range( 2 ) north_pole_index ], size( pole_phis ) ) ];
all_angles = [ ...
    phis thetas; ...
    fringe thetas( fringe_indices ); ...
    north_pole( :, 1 : 2 ); ...
    south_pole( :, 1 : 2 ) ...
    ];
[ all_angles, unique_indices ] = unique( all_angles, 'rows' );
all_indices = [ ...
    ( 1 : size( angles, 1 ) )'; ...
    fringe_indices; ...
    north_pole( :, 3 ); ...
    south_pole( :, 3 ) ...
    ];
all_indices = all_indices( unique_indices );

interpolant = scatteredInterpolant( ...
    all_angles( :, 1 ), ...
    all_angles( :, 2 ), ...
    values( all_indices ), ...
    interp_method ...
    );

end

