clear; clc;

%% Disc Characteristics

% Physical Characteristics
disc.m   = 0.173;               % mass, kg
disc.D   = 0.211;               % diameter, m
disc.S   = pi*(disc.D/2)^2;     % planform area, m^2
disc.Ixy = 0.00125;             % moment of inertia about in-plane axis, kg m^2
disc.Iz  = 0.00235;             % moment of inertia about spin axis, kg m^2

% Aerodynamic Characteristics
%% Aerodynamic Characteristics
aero_table = readtable('../../output.csv');   % adjust filename/path
% expects columns: aoa_deg, beta_deg, velocity, CD, CL, Cm, Cl_roll, Cn_yaw

aero.alpha_deg = unique(aero_table.aoa_deg);
aero.beta_deg  = unique(aero_table.beta_deg);
aero.U_grid    = unique(aero_table.velocity);

nAlpha = numel(aero.alpha_deg);
nBeta  = numel(aero.beta_deg);
nU     = numel(aero.U_grid);

[~, iA] = ismember(aero_table.aoa_deg,  aero.alpha_deg);
[~, iB] = ismember(aero_table.beta_deg, aero.beta_deg);
[~, iU] = ismember(aero_table.velocity, aero.U_grid);
idx = sub2ind([nAlpha, nBeta, nU], iA, iB, iU);

aero.CD_grid      = nan(nAlpha, nBeta, nU);
aero.CL_grid      = nan(nAlpha, nBeta, nU);
aero.CM_grid      = nan(nAlpha, nBeta, nU);
aero.ClRoll_grid  = nan(nAlpha, nBeta, nU);
aero.CnYaw_grid   = nan(nAlpha, nBeta, nU);

aero.CD_grid(idx)     = aero_table.CD;
aero.CL_grid(idx)     = aero_table.CL;
aero.CM_grid(idx)     = aero_table.Cm;
aero.ClRoll_grid(idx) = aero_table.Cl_roll;
aero.CnYaw_grid(idx)  = aero_table.Cn_yaw;

if any(isnan(aero.CD_grid(:)))
    warning('Aero grid has missing combinations — check for failed runs in the CSV.');
end

aero.CD_interp     = griddedInterpolant({aero.alpha_deg, aero.beta_deg, aero.U_grid}, aero.CD_grid,     'linear', 'linear');
aero.CL_interp     = griddedInterpolant({aero.alpha_deg, aero.beta_deg, aero.U_grid}, aero.CL_grid,     'linear', 'linear');
aero.CM_interp     = griddedInterpolant({aero.alpha_deg, aero.beta_deg, aero.U_grid}, aero.CM_grid,     'linear', 'linear');
aero.ClRoll_interp = griddedInterpolant({aero.alpha_deg, aero.beta_deg, aero.U_grid}, aero.ClRoll_grid, 'linear', 'linear');
aero.CnYaw_interp  = griddedInterpolant({aero.alpha_deg, aero.beta_deg, aero.U_grid}, aero.CnYaw_grid,  'linear', 'linear');

%% Environmental Conditions
env.g      = 9.81;              % m/s^2
env.rho    = 1.225;             % air density, kg/m^3
env.wind_v = [0 0 0];           % wind velocity in earth axes, m/s


%% Throw Conditions
x0 = [0; 0; 1.7];               % release 1m above ground
v0 = 29;                        % m/s

roll0_deg  = -10;                 % deg
pitch0_deg = 2;                 % deg (nose angle in vertical plane)
yaw0_deg = 0;                   % deg (initial launch direction offset)

r0 = 550;                 % rpm (spin rate; negative is CW)
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
dt = 0.0005;                      % seconds per step
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

    disp(y_next(1:3))
    if y_next(3) <= 0
        disp("STOP")
        y_hist = y_hist(:,1:i+1);
        t_hist = t_hist(1:i+1);
        break
    end

    % if i == 4
    %     return
    % end
end

t = t_hist';
y = y_hist';

fprintf('Flight time: %.3f s\n', t(end));
fprintf('Range: %.2f m (%.1f ft)\n', y(end,1), y(end,1)*3.28084);
fprintf('Max height: %.2f m (%.1f ft)\n', max(y(:,3)), max(y(:,3))*3.28084);
fprintf('Landing speed: %.2f m/s\n', norm(y(end,4:6)));
fprintf('Max speed: %.2f m/s\n', max(vecnorm(y(:,4:6),2,2)));

V_hist = vecnorm(y(:,4:6), 2, 2);

figure;
plot(t, V_hist, 'LineWidth', 2);
grid on;
xlabel('Time (s)');
ylabel('Speed (m/s)');
title('Disc speed vs time');

figure;
plot(t, y(:,3), 'LineWidth', 2);
grid on;
xlabel('Time (s)');
ylabel('Height (m)');
title('Disc height vs time');

figure;
plot(t, y(:,4), 'LineWidth', 2);
grid on;
xlabel('Time (s)');
ylabel('Downrange velocity (m/s)');
title('Downrange velocity vs time');
%% 3D Plotting
pos = y(:,1:3)*3.28084;
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


%% Animation: trajectory draw + disc orientation
playback_speed = 0.5;      % 1 = real time, >1 = faster than real time
target_fps     = 60;       % animation frame rate
step_stride    = max(1, round((playback_speed/target_fps)/dt));
frame_idx      = 1:step_stride:size(y_hist,2);

pos_ft = y_hist(1:3,:)' * 3.28084;   % ft, matches the static plot above

figAnim = figure('Name','Disc Flight Animation','Position',[80 80 1400 650]);

% --- Left: trajectory (drawn progressively) ---
ax1 = subplot(1,2,1);
hold(ax1,'on'); grid(ax1,'on'); axis(ax1,'equal');
xlabel(ax1,'Downrange, x (ft)'); ylabel(ax1,'Drift, y (ft)'); zlabel(ax1,'Height, z (ft)');
title(ax1,'Flight trajectory');
view(ax1,-115,45);
xlim(ax1,[min(pos_ft(:,1))-2, max(pos_ft(:,1))+2]);
ylim(ax1,[-max(abs(pos_ft(:,2)))-2, max(abs(pos_ft(:,2)))+2]);
zlim(ax1,[0, max(pos_ft(:,3))+2]);

trailLine  = plot3(ax1,NaN,NaN,NaN,'LineWidth',2,'Color',[0.85 0.33 0.10]);
discMarker = plot3(ax1,pos_ft(1,1),pos_ft(1,2),pos_ft(1,3),'o', ...
    'MarkerSize',8,'MarkerFaceColor',[0.10 0.60 0.35],'MarkerEdgeColor','k');

% --- Right: disc orientation (roll/pitch/yaw visualized on a disc icon) ---
ax2 = subplot(1,2,2);
hold(ax2,'on'); grid(ax2,'on'); axis(ax2,'equal');
xlim(ax2,[-1.4 1.4]); ylim(ax2,[-1.4 1.4]); zlim(ax2,[-1.4 1.4]);
xlabel(ax2,'X_{earth}'); ylabel(ax2,'Y_{earth}'); zlabel(ax2,'Z_{earth}');
title(ax2,'Disc orientation');
view(ax2,-30,20);

% reference earth axes for context
plot3(ax2,[0 1.3],[0 0],[0 0],'k--'); text(ax2,1.35,0,0,'X_E');
plot3(ax2,[0 0],[0 1.3],[0 0],'k--'); text(ax2,0,1.35,0,'Y_E');
plot3(ax2,[0 0],[0 0],[0 1.3],'k--'); text(ax2,0,0,1.35,'Z_E');

% flat circular disc drawn in the disc body frame (lies in body xy-plane)
nEdge = 40;
th = linspace(0,2*pi,nEdge);
discEdge_body = [cos(th); sin(th); zeros(1,nEdge)];

discPatch = patch(ax2,'XData',discEdge_body(1,:),'YData',discEdge_body(2,:), ...
    'ZData',discEdge_body(3,:),'FaceColor',[0.20 0.50 0.80],'FaceAlpha',0.6,'EdgeColor','k');

% spin-axis (disc normal) arrow
normalLine = plot3(ax2,[0 0],[0 0],[0 1],'r-','LineWidth',2);
normalHead = plot3(ax2,0,0,1,'^','MarkerFaceColor','r','MarkerEdgeColor','r','MarkerSize',6);

angText = text(ax2,-1.3,-1.3,1.3,'','FontSize',10,'FontName','FixedWidth');

nFrames = numel(frame_idx);

% bundle everything the update/play callbacks need to redraw a frame
handles = struct('trailLine',trailLine,'discMarker',discMarker, ...
    'discPatch',discPatch,'normalLine',normalLine,'normalHead',normalHead, ...
    'angText',angText,'pos_ft',pos_ft,'y_hist',y_hist,'t_hist',t_hist, ...
    'discEdge_body',discEdge_body,'frame_idx',frame_idx);

% --- slider: drag to scrub through the flight ---
sld = uicontrol(figAnim,'Style','slider','Min',1,'Max',nFrames,'Value',1, ...
    'SliderStep',[1/(nFrames-1), 10/(nFrames-1)], ...
    'Units','normalized','Position',[0.12 0.02 0.62 0.04]);
set(sld,'Callback',@(src,~) updateAnimFrame(round(get(src,'Value')), handles));
% Note: the plain uicontrol slider only fires its Callback when you
% release the mouse. If you're on R2022a+ you can get live updates while
% dragging by adding: addlistener(sld,'ContinuousValueChange', ...
%   @(src,~) updateAnimFrame(round(get(src,'Value')), handles));

% --- play/pause toggle ---
playBtn = uicontrol(figAnim,'Style','togglebutton','String','Play', ...
    'Units','normalized','Position',[0.78 0.02 0.10 0.05]);
set(playBtn,'Callback',@(src,~) playAnimation(src, sld, handles));

% draw the first frame so something is visible immediately
updateAnimFrame(1, handles);

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
    alpha = atan2(-vrel_D(3), vrel_D(1));        % the signs are correct here; validated through testing!
    alpha_deg = rad2deg(alpha);

    beta = asin(vrel_D(2) / norm(vrel_D));
    beta_deg = rad2deg(beta);

    % interpolate aerodynamic coefficients
    Alookup = min(max(alpha_deg, min(aero.alpha_deg)), max(aero.alpha_deg));
    Blookup = min(max(beta_deg,  min(aero.beta_deg)),  max(aero.beta_deg));
    Vlookup = min(max(norm(vrel_E), min(aero.U_grid)), max(aero.U_grid));
    
    CD        = aero.CD_interp(Alookup, Blookup, Vlookup);
    CL        = aero.CL_interp(Alookup, Blookup, Vlookup);
    CM_static        = aero.CM_interp(Alookup, Blookup, Vlookup);
    Cl_static = aero.ClRoll_interp(Alookup, Blookup, Vlookup);
    Cn_static = aero.CnYaw_interp(Alookup, Blookup, Vlookup);
    
    V_mag = max(norm(vrel_E), 0.1);
    Sp = (angvel(3) * disc.D) / (2 * V_mag);
    p_hat = (angvel(1) * disc.D) / (2 * V_mag);
    q_hat = (angvel(2) * disc.D) / (2 * V_mag);

    % UNVERIFIED, need to get better numbers
    Clr =  0.014;
    Clp = -0.015;
    Cnr = -0.000034;
    Cmq = -0.015;

    Cl = Cl_static + (Clr * Sp) + (Clp * p_hat);
    Cn = Cn_static + (Cnr * Sp);
    CM = CM_static + Cmq * q_hat;

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

    % Mx = 0;
    % My = 0;
    % Mz = 0;

    % calculate body forces
    Fg_E = [0; 0; -disc.m * env.g];

    % total forces
    Ftotal_E = Fg_E + Fd_E + Fl_E;
    accel_E = Ftotal_E / disc.m;

    % calculate euler angle rates
    % euler_dot = [angvel(1) + angvel(2)*sin(euler(1))*tan(euler(2)) + angvel(3)*cos(euler(1))*tan(euler(2)); ...
    %              angvel(2)*cos(euler(1)) - angvel(3)*sin(euler(1)); ...
    %              angvel(2)*sin(euler(1))/cos(euler(2)) + angvel(3)*cos(euler(1))/cos(euler(2))];
    euler_dot = [(angvel(1)*cos(euler(3)) - angvel(2)*sin(euler(3))) / cos(euler(2)); ...
                 -angvel(1)*sin(euler(3)) - angvel(2)*cos(euler(3)); ...
                 angvel(3) + (angvel(1)*cos(euler(3)) - angvel(2)*sin(euler(3))) * tan(euler(2))];


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

    Ry = [cos(theta) 0 -sin(theta); ...
          0 1 0; ...
          sin(theta) 0 cos(theta)];

    Rz = [cos(psi) -sin(psi) 0; ...
          sin(psi) cos(psi) 0; ...
          0 0 1];

    T = (Rx * Ry * Rz)';

end

function updateAnimFrame(sliderIdx, h)
    % Redraws both animation panels for a given position in frame_idx.
    % sliderIdx indexes into h.frame_idx; k is the actual row/column
    % index into y_hist / t_hist / pos_ft.
    sliderIdx = max(1, min(sliderIdx, numel(h.frame_idx)));
    k = h.frame_idx(sliderIdx);

    % --- trajectory panel: redraw the trail up through frame k ---
    kk = h.frame_idx(1:sliderIdx);
    set(h.trailLine,'XData',h.pos_ft(kk,1),'YData',h.pos_ft(kk,2),'ZData',h.pos_ft(kk,3));
    set(h.discMarker,'XData',h.pos_ft(k,1),'YData',h.pos_ft(k,2),'ZData',h.pos_ft(k,3));

    % --- orientation panel ---
    euler_k = h.y_hist(7:9,k);
    R = R_DE(euler_k)';   % R_DE maps earth->disc, so its transpose maps disc(body)->earth

    discEdge_earth = R * h.discEdge_body;
    set(h.discPatch,'XData',discEdge_earth(1,:),'YData',discEdge_earth(2,:),'ZData',discEdge_earth(3,:));

    normal_earth = R * [0;0;1];
    set(h.normalLine,'XData',[0 normal_earth(1)],'YData',[0 normal_earth(2)],'ZData',[0 normal_earth(3)]);
    set(h.normalHead,'XData',normal_earth(1),'YData',normal_earth(2),'ZData',normal_earth(3));

    set(h.angText,'String',sprintf('t = %5.2f s\nroll  (\\phi)  = %6.1f^\\circ\npitch (\\theta) = %6.1f^\\circ\nyaw   (\\psi)  = %6.1f^\\circ', ...
        h.t_hist(k), rad2deg(euler_k(1)), rad2deg(euler_k(2)), rad2deg(euler_k(3))));

    drawnow limitrate;
end

function playAnimation(btn, sld, h)
    % Toggle button callback: steps the slider forward automatically
    % (~30 fps) until it reaches the end, is paused, or the figure closes.
    if get(btn,'Value') == 0
        set(btn,'String','Play');
        return
    end
    set(btn,'String','Pause');

    nFrames = numel(h.frame_idx);
    while ishandle(btn) && get(btn,'Value') == 1
        idx = round(get(sld,'Value')) + 1;
        if idx > nFrames
            set(btn,'Value',0,'String','Play');
            break
        end
        set(sld,'Value',idx);
        updateAnimFrame(idx, h);
        pause(1/30);
    end
end
