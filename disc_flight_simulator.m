clear; clc;

% TO DO
% - Animate the disc flight (just show from throw to landing)
% - Account for unequal lift on the disc by rotation (though minimal)
% - Ideally get to a point where the disc is shown in 3D with the roll,
% pitch, and yaw.
% - Come up with a script to assign flight numbers to disc geometries
% - Improve the workflow from getting flight coefficients to putting them
% in the aero table in MATLAB
% - ML-based disc geometry optimization (ehhh that's gonna SUCK)
% - spin decay from rotational drag
% - spin-dependent drag coefficients

% disc characteristics
disc.m   = 0.175;          % mass, kg
disc.D   = 0.211;          % diameter, m
disc.S   = pi*(disc.D/2)^2; % planform area, m^2
disc.Ixy = 0.00125;        % moment of inertia about in-plane axis, kg m^2
disc.Iz  = 0.00235;        % moment of inertia about spin axis, kg m^2

aero.data = [ ...
   -10.0   8.0  0.1384662  -0.2469406  -0.0602598
   -10.0  14.0  0.1323100  -0.2337933  -0.0566442
   -10.0  20.0  0.1295806  -0.2295144  -0.05508614
   -10.0  26.0  0.1279961  -0.2271237  -0.05453947
   -10.0  30.0  0.1272375  -0.2261800  -0.05424424

    -5.0   8.0  0.1010877  -0.1070350  -0.03774391
    -5.0  14.0  0.09605618 -0.1061321  -0.03268631
    -5.0  20.0  0.09439836 -0.1016378  -0.03197758
    -5.0  26.0  0.09334645 -0.09902986 -0.03181236
    -5.0  30.0  0.09282485 -0.09780377 -0.03176191

    -2.5   8.0  0.09636281 -0.007694713 -0.03031369
    -2.5  14.0  0.0887523  -0.01721118  -0.02643667
    -2.5  20.0  0.08466419 -0.01852760  -0.02505768
    -2.5  26.0  0.08084048 -0.02832773  -0.02037004
    -2.5  30.0  0.08037904 -0.02778616  -0.02025714

     0.0   8.0  0.1004871   0.1017559  -0.02092974
     0.0  14.0  0.08946224  0.07361692 -0.01405368
     0.0  20.0  0.08544589  0.06746925 -0.01244600
     0.0  26.0  0.0834410   0.06446447 -0.01176837
     0.0  30.0  0.0826323   0.06312528 -0.01141476

     2.5   8.0  0.1144585   0.2129231  -0.01092762
     2.5  14.0  0.1027742   0.1857447  -0.005291002
     2.5  20.0  0.09853606  0.1776117  -0.003450181
     2.5  26.0  0.09674769  0.1750871  -0.002947438
     2.5  30.0  0.09580427  0.1728784  -0.002468079

     5.0   8.0  0.1427243   0.3482350  -0.004065983
     5.0  14.0  0.1337653   0.3358157  -0.003739284
     5.0  20.0  0.1274623   0.3135674   0.001196237
     5.0  26.0  0.1283688   0.3267077  -0.002763923
     5.0  30.0  0.1237557   0.3054545   0.002631750

     7.5   8.0  0.1798422   0.4771820   0.006218100
     7.5  14.0  0.1694519   0.4587108   0.007623705
     7.5  20.0  0.1673588   0.4510299   0.007922029
     7.5  26.0  0.1649329   0.4549728   0.007673608
     7.5  30.0  0.1649740   0.4492808   0.008205614

    10.0   8.0  0.2223624   0.5904900   0.02300970
    10.0  14.0  0.2148582   0.5778479   0.02295953
    10.0  20.0  0.2112198   0.5711461   0.02323347
    10.0  26.0  0.2088451   0.5661702   0.02381358
    10.0  30.0  0.2077136   0.5632883   0.02420254

    12.5   8.0  0.2733201   0.7031775   0.03854547
    12.5  14.0  0.2667029   0.6925377   0.03764702
    12.5  20.0  0.2614037   0.6838048   0.03812234
    12.5  26.0  0.2599807   0.6836240   0.03774128
    12.5  30.0  0.2594401   0.6833620   0.03787130

    15.0   8.0  0.3327788   0.8139999   0.05303118
    15.0  14.0  0.3278136   0.8098473   0.05171464
    15.0  20.0  0.3252386   0.8068712   0.05160544
    15.0  26.0  0.3236936   0.8043782   0.05155180
    15.0  30.0  0.3228060   0.8025391   0.05162040

    20.0   8.0  0.4735310   1.0161820   0.07894416
    20.0  14.0  0.4712595   1.0157610   0.07684095
    20.0  20.0  0.4693332   1.0143270   0.07595520
    20.0  26.0  0.4675216   1.0120970   0.07549327
    20.0  30.0  0.4665795   1.0108290   0.07534001

    25.0   8.0  0.6255410   1.1610230   0.09430410
    25.0  14.0  0.6240202   1.1592940   0.09159505
    25.0  20.0  0.6225974   1.1577540   0.09039917
    25.0  26.0  0.6216271   1.1572870   0.08993737
    25.0  30.0  0.6212831   1.1571150   0.08971204
];

aero.alpha_deg = unique(aero.data(:,1));   % [0; 10; 20]
aero.U_grid    = unique(aero.data(:,2));   % [10; 20; 30]

nAlpha = length(aero.alpha_deg);
nU     = length(aero.U_grid);

aero.CD_grid = reshape(aero.data(:,3), nU, nAlpha)';
aero.CL_grid = reshape(aero.data(:,4), nU, nAlpha)';
aero.CM_grid = reshape(aero.data(:,5), nU, nAlpha)';

% environment
env.g      = 9.81;              % m/s^2
env.rho    = 1.225;             % air density, kg/m^3
env.wind_v = [0 0 0];           % wind velocity in earth axes, m/s

% throw conditions
x0 = [0; 0; 1.0];               % release 1m above ground
v0     = 20;                  % m/s
roll0_deg  = 0;                % deg
pitch0_deg = 3;                % deg (nose angle in vertical plane)
yaw0_deg   = 0;                % deg (initial launch direction offset)

phi0   = deg2rad(roll0_deg);
theta0 = deg2rad(pitch0_deg);
psi0   = deg2rad(yaw0_deg);
euler0 = [phi0; theta0; psi0];      % [roll; pitch; yaw]

throw_force_angle = deg2rad(5);

u_disc0 = [v0*cos(throw_force_angle); 0; v0*sin(throw_force_angle)];           % all initial speed along disc x-axis
T12_0   = T12_matrix(euler0);
u_earth0 = T12_0' * u_disc0;        % disc axes -> earth axes

spin0 = -105.0;                      % rad/s, from CFD/paper example throws

%% ---------------- Simulation settings ----------------
tspan = [0 6];                      % seconds, integrate until well after landing
opts  = odeset('Events', @(t,y) ground_event(t,y), ...
                'RelTol', 1e-6, 'AbsTol', 1e-8, 'MaxStep', 0.01);

% State vector y = [x; y; z; u; v; w; phi; theta; psi]
% (u,v,w) = velocity components in EARTH axes
y0 = [x0; u_earth0; euler0];

%% Flight solver
odefun = @(t, y) disc_eom(t, y, disc, aero, env, spin0);
[t, y, te, ye, ie] = ode45(odefun, tspan, y0, opts);
y = y*3.28084;

%% 2D Plot
pos = y(:,1:3);
fprintf('Flight time: %.2f s\n', t(end));
fprintf('Drift: %.1f ft\n', pos(end,2));
fprintf('Downrange Distance:   %.1f ft\n', pos(end,1));

figure('Name','Disc golf trajectory (2D views)');
subplot(2,1,1);
plot(pos(:,2), pos(:,1), 'LineWidth', 1.5);
xlabel('Drift, y (ft)'); ylabel('Downrange Distance, x (ft)');
title('Trajectory viewed from above'); axis equal; grid on;

subplot(2,1,2);
plot(pos(:,2), pos(:,3), 'LineWidth', 1.5);
xlabel('Drift, y (ft)'); ylabel('Height, z (ft)');
title('Trajectory side view'); grid on; ylim([0 max(pos(:,3))*1.2]);

%% 3D Plot
figure('Name','Disc golf trajectory (3D)');
plot3(pos(:,1), pos(:,2), pos(:,3), 'LineWidth', 2, 'Color', [0.85 0.33 0.10]);
%comet3(pos(:,1), pos(:,2), pos(:,3));
hold on;

% Mark release and landing points
plot3(pos(1,1), pos(1,2), pos(1,3), 'o', 'MarkerSize', 7, ...
      'MarkerFaceColor', [0.10 0.60 0.35], 'MarkerEdgeColor', 'k');
plot3(pos(end,1), pos(end,2), pos(end,3), 'o', 'MarkerSize', 7, ...
      'MarkerFaceColor', [0.55 0.10 0.10], 'MarkerEdgeColor', 'k');

% Faint ground-projection curve (x-y path traced at z = 0) for depth cues
plot3(pos(:,1), pos(:,2), zeros(size(pos,1),1), '--', ...
      'LineWidth', 0.75, 'Color', [0.6 0.6 0.6]);

xlabel('Downrange Distance, x (ft)');
ylabel('Drift, y (ft)');
zlabel('Height, z (ft)');
title('3D flight trajectory');
legend({'Flight path','Release','Landing','Ground projection'}, ...
       'Location', 'best');
xlim([-10, 90]);
lim = max(abs(ylim)); ylim([-lim, lim])

grid on;
axis equal;
view(-115, 45);
hold off;


%% Local funcs
% MATLAB scripts support local functions below all script code, as long
% as this file is run as a script (not called as a function itself).

function T = T12_matrix(euler)
% T12_MATRIX  Earth axes -> disc axes rotation matrix (paper Eq. A1)
%   euler = [phi; theta; psi] = [roll; pitch; yaw], radians

phi   = euler(1);
theta = euler(2);
psi   = euler(3);

T = [ cos(theta)*cos(psi), ...
      sin(phi)*sin(theta)*cos(psi) - cos(phi)*sin(psi), ...
      cos(phi)*sin(theta)*cos(psi) + sin(phi)*sin(psi); ...
      ...
      cos(theta)*sin(psi), ...
      sin(phi)*sin(theta)*sin(psi) + cos(phi)*cos(psi), ...
      cos(phi)*sin(theta)*sin(psi) - sin(phi)*cos(psi); ...
      ...
      -sin(theta), ...
      sin(phi)*cos(theta), ...
      cos(phi)*cos(theta) ];
end


function T = T23_matrix(beta)
% T23_MATRIX  Disc axes -> zero sideslip axes rotation (paper Eq. A2)
%   beta = sideslip angle, radians

T = [ cos(beta), -sin(beta), 0; ...
      sin(beta),  cos(beta), 0; ...
      0,          0,         1 ];
end


function T = T34_matrix(alpha)
% T34_MATRIX  Zero sideslip axes -> wind axes rotation (paper Eq. A3)
%   alpha = angle of attack, radians

T = [ cos(alpha), 0, -sin(alpha); ...
      0,          1,  0; ...
      sin(alpha), 0,  cos(alpha) ];
end


function dydt = disc_eom(~, y, disc, aero, env, spin)
% DISC_EOM  Right-hand side of the disc trajectory ODE.
%   State y = [x; y; z; u; v; w; phi; theta; psi]
%     (x,y,z)     position, earth axes
%     (u,v,w)     velocity, earth axes
%     (phi,theta,psi)  roll, pitch, yaw, earth-referenced attitude

euler = y(7:9);              % [phi; theta; psi]
u1    = y(4:6);              % velocity in earth axes

u1_rel = u1 - env.wind_v(:);

%% Earth axes to disc axes (Eq. 4)
T12 = T12_matrix(euler);
u2  = T12 * u1_rel;

%% Sideslip angle (Eq. 5), then rotate to zero sideslip axes (Eq. 6)
beta = -atan2(u2(2), u2(1));
T23  = T23_matrix(beta);
u3   = T23 * u2;

%% AoA (Eq. 7), then rotate to wind axes (Eq. 8)
alpha = -atan2(u3(3), u3(1));
T34   = T34_matrix(alpha);
u4    = T34 * u3;   %#ok<NASGU>  % velocity in wind axes (not needed further)

alpha_deg = rad2deg(alpha);

%% Look up aerodynamic coefficients at this angle of attack and velocity
Vrel_for_lookup = norm(u1_rel);   % need velocity for the 2D lookup
Vlookup = min(max(Vrel_for_lookup, min(aero.U_grid)), max(aero.U_grid));
Alookup = min(max(alpha_deg, min(aero.alpha_deg)), max(aero.alpha_deg));

CL = interp2(aero.U_grid, aero.alpha_deg, aero.CL_grid, ...
             Vlookup, Alookup, 'linear');

CD = interp2(aero.U_grid, aero.alpha_deg, aero.CD_grid, ...
             Vlookup, Alookup, 'linear');

CM = interp2(aero.U_grid, aero.alpha_deg, aero.CM_grid, ...
             Vlookup, Alookup, 'linear');

%% Forces in wind axes (Eqs. 1-2, 9)
Vrel = norm(u1_rel);
q    = 0.5 * env.rho * Vrel^2;
FD   = q * CD * disc.S;
FL   = q * CL * disc.S;
M    = q * CM * disc.D * disc.S;    % pitching moment, Eq. 3

F4 = [-FD; 0; FL];                  % force vector in wind axes, Eq. 9

%% Gravity, transformed into wind axes (Eq. 10)
g1 = [0; 0; -disc.m * env.g];
T14full = T34 * T23 * T12;          % Eq. A4: ground -> wind, full chain
g4 = T14full * g1;

F4_total = F4 + g4;

%% Transform force back to earth axes (Eq. 12): T41 = T14'
T41 = T14full';
F1  = T41 * F4_total;
accel = F1 / disc.m;

%% Attitude rate: constant spin, roll from gyroscopic precession only (Eq. 11)
theta3_dot = [ -M / (spin * (disc.Ixy - disc.Iz)); 0; 0 ];  % in zero-sideslip axes

% Transform back to earth axes (Eq. 13): T31 = T23*T12, so T13 = T31' etc.
T31 = T23 * T12;
euler_dot = T31' * theta3_dot;

%% Assemble derivative
dydt = zeros(9,1);
dydt(1:3) = u1;              % position rate = velocity (earth axes)
dydt(4:6) = accel;           % velocity rate = acceleration (earth axes)
dydt(7:9) = euler_dot;       % attitude rate
end


function [value, isterminal, direction] = ground_event(~, y)
% GROUND_EVENT  Stops ode45 integration when the disc's z position
% crosses zero (lands), approaching from above.

value      = y(3);   % z position; triggers when this hits 0
isterminal = 1;       % stop the integration
direction  = -1;      % only trigger when z is decreasing
end