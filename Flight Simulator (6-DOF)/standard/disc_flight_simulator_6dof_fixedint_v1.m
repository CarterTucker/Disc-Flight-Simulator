clear; clc;

%% Disc Characteristics

% Physical Characteristics
disc.m   = 0.175;               % mass, kg
disc.D   = 0.211;               % diameter, m
disc.S   = pi*(disc.D/2)^2;     % planform area, m^2
disc.Ixy = 0.00125;             % moment of inertia about in-plane axis, kg m^2
disc.Iz  = 0.00235;             % moment of inertia about spin axis, kg m^2

% Aerodynamic Characteristics
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


%% Environmental Conditions
env.g      = 9.81;              % m/s^2
env.rho    = 1.225;             % air density, kg/m^3
env.wind_v = [0 0 0];           % wind velocity in earth axes, m/s


%% Throw Conditions
x0 = [0; 0; 1.0];               % release 1m above ground
v0 = 25;                        % m/s

roll0_deg  = 0;                 % deg
pitch0_deg = 0;                 % deg (nose angle in vertical plane)
yaw0_deg = 0;                   % deg (initial launch direction offset)

r0 = 0;                 % rpm (spin rate; negative is CW)
p0 = 0;
q0 = 0;

% convert degrees to radians
phi0 = deg2rad(roll0_deg);
theta0 = deg2rad(pitch0_deg);
psi0 = deg2rad(yaw0_deg);

% convert rpm to rad/s
r0 = pi*r0/30;

% translational pitch
% throw_force_angle = deg2rad(5);

% initial spin vector
euler0 = [phi0; theta0; psi0];

% initial velocity vector
u_earth0 = [v0; 0; 0];           % all initial speed along disc x-axis

% initial body-axis angular rates
angvel0 = [p0; q0; r0];


%% Simulation Solver (fixed-step RK4)
tspan = [0 4];
dt = 0.001;                      % seconds per step
N  = ceil(diff(tspan)/dt) + 1;

y0 = [x0; u_earth0; euler0; angvel0];

y_hist = zeros(12, N);
t_hist = zeros(1, N);

y_hist(:,1) = y0;
t_hist(1)   = tspan(1);

for i = 1:N-1
    yi = y_hist(:,i);
    ti = t_hist(i);

    k1 = disc_eom(ti,        yi,          disc, aero, env);
    k2 = disc_eom(ti+dt/2,   yi+dt/2*k1,  disc, aero, env);
    k3 = disc_eom(ti+dt/2,   yi+dt/2*k2,  disc, aero, env);
    k4 = disc_eom(ti+dt,     yi+dt*k3,    disc, aero, env);

    [~, diag] = disc_eom(ti, yi, disc, aero, env);
    fprintf(' V = %.3f,\n alpha = %.3f,\n beta = %.3f,\n CD = %.3f,\n CL = %.3f,\n CM = %.3f,\n q_dyn = %.3f,\n FD = %.3f,\n FL = %.3f,\n Mx = %.3f,\n My = %.3f,\n Mz = %.3f,\n p = %.3f,\n q = %.3f,\n r = %.3f\n\n', ...
             diag.V, diag.alpha, diag.beta, diag.CD, diag.CL, diag.CM, diag.q_dyn, diag.FD, diag.FL, diag.Mx, diag.My, diag.Mz, diag.p, diag.q, diag.r)

    y_next = yi + dt/6*(k1 + 2*k2 + 2*k3 + k4);

    y_hist(:,i+1) = y_next;
    t_hist(i+1)   = ti + dt;

    if y_next(3) <= 0
        y_hist = y_hist(:,1:i+1);
        t_hist = t_hist(1:i+1);
        break
    end

    % if i == 4
    %     return
    % end
end


%% 3D Plotting
pos = y_hist(:,1:3)*3.28084;
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
lim = max(abs(ylim)); ylim([-lim, lim])

grid on;
axis equal;
view(-115, 45);
hold off;


%% Derivative of the State Vector -- Equations of Motion
function [dydt, diag] = disc_eom(~, y, disc, aero, env)

    % disc motion from state vector
    v_E = y(4:6);
    euler = y(7:9);
    angvel = y(10:12);

    % relative velocity
    vrel_E = v_E - env.wind_v(:);
    vrel_D = R_DE(euler) * vrel_E;

    % angle of attack and sideslip angle
    alpha = atan2(vrel_D(3), vrel_D(1));        % the signs are correct here; validated through testing!
    alpha_deg = rad2deg(alpha);

    beta = asin(vrel_D(2) / norm(vrel_D));
    beta_deg = rad2deg(beta);

    % interpolate aerodynamic coefficients
    Vlookup = min(max(norm(vrel_E), min(aero.U_grid)), max(aero.U_grid));
    Alookup = min(max(alpha_deg, min(aero.alpha_deg)), max(aero.alpha_deg));

    CL = interp2(aero.U_grid, aero.alpha_deg, aero.CL_grid, ...
             Vlookup, Alookup, 'linear');
    CD = interp2(aero.U_grid, aero.alpha_deg, aero.CD_grid, ...
                 Vlookup, Alookup, 'linear');
    CM = interp2(aero.U_grid, aero.alpha_deg, aero.CM_grid, ...
                 Vlookup, Alookup, 'linear');
    Cl = 0;
    Cn = 0;

    % calculate aerodynamic forces and moments
    q_dyn = 0.5 * env.rho * norm(vrel_E)^2;
    
    Fd_mag = q_dyn * disc.S * CD;            % drag force
    Fd_E = -Fd_mag * vrel_E / norm(vrel_E);

    Fl_mag = q_dyn * disc.S * CL;            % lift force
    n_D = [0; 0; 1];
    n_E = R_DE(euler)' * n_D;
    n_perp = n_E - dot(n_E, vrel_E/norm(vrel_E)) * vrel_E/norm(vrel_E);
    l_hat = n_perp / norm(n_perp);
    Fl_E = Fl_mag * l_hat;

    Mx = q_dyn * disc.S * disc.D * Cl;          % roll moment
    My = q_dyn * disc.S * disc.D * CM;          % pitch moment
    Mz = q_dyn * disc.S * disc.D * Cn;          % yaw moment

    % calculate body forces
    Fg_E = [0; 0; -disc.m * env.g];

    % total forces
    Ftotal_E = Fg_E + Fd_E + Fl_E;
    accel_E = Ftotal_E / disc.m;

    % calculate euler angle rates
    euler_dot = [angvel(1) + angvel(2)*sin(euler(1))*tan(euler(2)) + angvel(3)*cos(euler(1))*tan(euler(2)); ...
                 angvel(2)*cos(euler(1)) - angvel(3)*sin(euler(1)); ...
                 angvel(2)*sin(euler(1))/cos(euler(2)) + angvel(3)*cos(euler(1))/cos(euler(2))];


    % calculate angular accelerations
    angvel_dot = [(Mx - (disc.Iz - disc.Ixy)*angvel(2)*angvel(3))/disc.Ixy; ...
                  (My - (disc.Ixy - disc.Iz)*angvel(3)*angvel(1))/disc.Ixy; ...
                  Mz/disc.Iz];

    dydt = zeros(12, 1);
    dydt(1:3) = y(4:6);
    dydt(4:6) = accel_E;
    dydt(7:9) = euler_dot;
    dydt(10:12) = angvel_dot;

    % store diagnostics
    diag.V = norm(vrel_E);
    diag.alpha = alpha_deg;
    diag.beta = beta_deg;
    diag.CD = CD;
    diag.CL = CL;
    diag.CM = CM;
    diag.q_dyn = q_dyn;
    diag.FD = norm(Fd_E);
    diag.FL = norm(Fl_E);
    diag.Mx = Mx;
    diag.My = My;
    diag.Mz = Mz;
    diag.p = angvel(1);
    diag.q = angvel(2);
    diag.r = angvel(3);

end

function T = R_DE(euler)
    % rotation matrix, Earth frame -> Disc frame
    phi = euler(1); theta = euler(2); psi = euler(3);

    Rx = [1 0 0; ...
          0 cos(phi) -sin(phi); ...
          0 sin(phi) cos(phi)];

    Ry = [cos(theta) 0 sin(theta); ...
          0 1 0; ...
          -sin(theta) 0 cos(theta)];

    Rz = [cos(psi) -sin(psi) 0; ...
          sin(psi) cos(psi) 0; ...
          0 0 1];

    T = (Rx * Ry * Rz)';

end