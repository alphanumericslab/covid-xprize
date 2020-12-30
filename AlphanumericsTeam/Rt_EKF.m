function [S_MINUS, S_PLUS, P_MINUS, P_PLUS, K_GAIN, S_SMOOTH, P_SMOOTH, innovations, rho] = Rt_EKF(x, s_init, params, w_bar, v_bar, Ps_init, Q_w, R_v, beta, gamma, inv_monitor_len)
% Estimates the parameters of an exponential fit using an Extended Kalman
% Filter (EKF) and Extended Kalman Smoother (EKS) over the number of new cases
%
% Reza Sameni
% Dec 2020
% Email: reza.sameni@gmail.com

T = size(x, 2); % number of time samples
n = size(x, 1); % number of observations
m = length(s_init); % number of state variables
% l = length(w_bar); % number of process noises
% p = length(v_bar); % number of observation noises

%//////////////////////////////////////////////////////////////////////////
S_MINUS = zeros(m, T);
S_PLUS = zeros(m, T);
P_MINUS = zeros(m, m, T);
P_PLUS = zeros(m, m, T);
K_GAIN = zeros(m, n, T);
innovations = zeros(n, T);
rho = zeros(n, n, T);
InnovationsMean = zeros(n, inv_monitor_len);
InnovationsCovNormalized = zeros(n, n, inv_monitor_len);
InnovationsCov = zeros(n, n, inv_monitor_len);

% Initialization
sk_minus = s_init(:);
Pk_minus = Ps_init;
Q = Q_w;
R = R_v;

% Forward Kalman Filtering Stage
for k = 1 : T
    % Store results of s_minus from previous iteration
    S_MINUS(:, k) = sk_minus;
    P_MINUS(:, :, k) = Pk_minus;
    
    % Calculate s(k|k) and P(k|k)
    Ck_minus = ObsJacobian(sk_minus, v_bar, params);
    xk_minus = NlinObsUpdate(sk_minus, v_bar, params);
    innovations(:, k) = x(:, k) - xk_minus;
    Kgain = Pk_minus * Ck_minus' / (Ck_minus * Pk_minus * Ck_minus' + gamma * R); % Kalman gain
    Pk_plus = (eye(m) - Kgain * Ck_minus) * Pk_minus / gamma;
    sk_plus = sk_minus + Kgain * innovations(:, k);                 % As posteriori state estimate
    
    % Calculate s(k+1|k) and P(k+1|k) for k+1
    sk_minus = NlinStateUpdate(sk_plus, w_bar, params); % State update
    Ak_plus = StateJacobian(sk_plus, w_bar, params);
    Pk_minus = (Ak_plus * Pk_plus * Ak_plus') + Q; % Cov. matrix update
    
    % Store results of s_plus
    S_PLUS(:, k) = sk_plus;
    P_PLUS(:, :, k) = Pk_plus;
    K_GAIN(:, :, k) = Kgain;
    
    % Monitoring the innovation variance and update the observation noise
    stats_counter = min(k, inv_monitor_len);
    InnovationsMean = cat(2, innovations(:, k), InnovationsMean(:, 1 : inv_monitor_len - 1));
    mu_k = sum(InnovationsMean, 2)/stats_counter;
    %     cc = innovations(:, k)*innovations(:, k)'; % without mean cancellation
    cc = (innovations(:, k) - mu_k) * (innovations(:, k) - mu_k)'; % with mean cancellation
    InnovationsCov = cat(3, cc, InnovationsCov(:, :, 1 : inv_monitor_len - 1));
    InnovationsCovNormalized = cat(3, cc / R, InnovationsCovNormalized(:, :, 1 : inv_monitor_len - 1));
    rho(:, :, k) = sum(InnovationsCovNormalized, 3) / stats_counter;
    if(~isequal(beta, 1))
        R = beta * R + (1 - beta) * sum(InnovationsCov, 3) / stats_counter;
    end
end

% Backward Kalman Smoothing Stage
S_SMOOTH = zeros(size(S_PLUS));
S_SMOOTH(:, T) = S_PLUS(:, T);
P_SMOOTH = zeros(size(P_PLUS));
P_SMOOTH(:, :, T) = P_PLUS(:, :, T);
for k = T - 1 : -1 : 1
    sk_plus = S_PLUS(:, k);
    Ak_plus = StateJacobian(sk_plus, w_bar, params);
    J = (P_PLUS(:, :, k) * Ak_plus') / (P_MINUS(:, :, k + 1));
    S_SMOOTH(:, k) = S_PLUS(:, k) + J * (S_SMOOTH(:, k + 1) - S_MINUS(:, k + 1));
    P_SMOOTH(:, :, k) = P_PLUS(:, :, k) - J * (P_MINUS(:, :, k+1) - P_SMOOTH(:, :, k+1)) * J';
end

% Squeeze excess dimensions if applicable
rho = squeeze(rho);
end

% Nonlinear state update
function s_k_plus_one = NlinStateUpdate(s_k, w_bar, params)
time_scale = params(1);
alpha = params(2);
sigma = params(3);
s_k_plus_one = zeros(2, 1);
s_k_plus_one(1) = s_k(1) * exp(time_scale * s_k(2)) + w_bar(1);
s_k_plus_one(2) = sigma * tanh((alpha * s_k(2) + w_bar(2))/sigma);
end

% Nonlinear observation update
function x_k = NlinObsUpdate(s_k, v_bar, params)
x_k = s_k(1) + v_bar;
end

% State-equation Jacobian
function A = StateJacobian(s_k, w_bar, params)
time_scale = params(1);
alpha = params(2);
sigma = params(3);
A = zeros(2);
A(1, 1) = exp(time_scale * s_k(2));
A(1, 2) = time_scale * s_k(1) * exp(time_scale * s_k(2));
A(2, 1) = 0;
A(2, 2) = alpha * (1 - tanh((alpha * s_k(2) + w_bar(2))/sigma)^2);
end

% Observation-equation Jacobian
function C = ObsJacobian(s_k, v_bar, params)
C = [1, 0];
end