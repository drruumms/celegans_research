function [ T, cycle, tees, fs ] =get_period_mech_coupling( tau_f, c_MA, tau_m )
%get_period_mech_coupling
%gets the period and limit cycle of the uncoupled oscillator

%simulation runtime
TF = 1e2;

%mechanical params
Gamma = 0; %parameter sweep this - Coupling strength
% tau_f = 5; %mu/k
% c_MA = 10; %muscle activity mechanical feedback strength
%timescale of muscle activation
% tau_m = 1;

% % Mechanically coupled system 
LHS_matrix = tau_f.*[(Gamma/tau_f)+1, (Gamma/tau_f)+1; 1, -1;];
RHS_matrix = [-1, -1; -1, +1;];
%R*[theta1'; theta2;] = L[theta1; theta2;] - c_MA*[M1+M2; M1-M2;]
kappa_dot = @(t,kappa, A) LHS_matrix\(RHS_matrix*[kappa(1); kappa(2);]...
    -c_MA.*[(A(2)-A(1))+(A(4)-A(3));(A(2)-A(1))-(A(4)-A(3));]); 
%GAMMA = 0:
% kappa_dot = @(t,kappa,A) (1/tau_f).*[-kappa(1) - c_MA*(A(2)-A(1));...
%     -kappa(2) - c_MA*(A(4)-A(3));];
   
%neural params
eps = 2;   %%-] These two determine thresholds together
I = 0.01;  %%-]

%results in the thresholds
K_V_ON = eps/2-I;   %K_D_ON is negative of this
K_V_OFF = -eps/2-I; %K_D_OFF is negative of this

%IC - only one is oscillating
K(1) = K_V_OFF;
K(2) = 0;
A(1) = 1; % A_1^D
A(2) = 0; % A_1^V
A(3) = 0;% A_2^D
A(4) = 0;% A_2^V


%neural functions
state_d_1 = discrete_neural_state_init(K(1), K_V_OFF, K_V_ON, 0);
state_v_1 = discrete_neural_state_init(K(1), K_V_OFF, K_V_ON, 1);
state_d_2 = discrete_neural_state_init(K(2), K_V_OFF, K_V_ON, 0);
state_v_2 = discrete_neural_state_init(K(2), K_V_OFF, K_V_ON, 1);

%muscle eqns:
muscle_activity = @(t, K,A) (1/tau_m).*[-A(1) + (state_d_1(K(1)) - state_v_1(K(1))); ...
                -A(2) + (state_v_1(K(1)) - state_d_1(K(1)));...
                -A(3) + (state_d_2(K(2)) - state_v_2(K(2))); ...
                -A(4) + (state_v_2(K(2)) - state_d_2(K(2)));];

ode_rhss = @(t,X) [kappa_dot(t,X(1:2),X(3:6)); muscle_activity(t,X(1:2),X(3:6));];
init_cond = [K(1); K(2); A(1);A(2);A(3);A(4);];

max_step = 1e-2;
options = odeset('RelTol',1e-8,'AbsTol',1e-10,  'MaxStep', max_step);
[t,y] = ode23(ode_rhss,[0,TF], init_cond, options);            
% figure(1); clf;
% subplot(3,2,1); plot(t,y(:,1), '-'); ylabel('\kappa_1'); xlabel('t');%ylim([-1 1]);
% subplot(3,2,2); plot(t,y(:,2), '-'); ylabel('\kappa_2'); xlabel('t');%ylim([-1 1]);
% subplot(3,2,3); plot(t,y(:,3), '-'); ylabel('A_1^D'); xlabel('t');
% subplot(3,2,5); plot(t,y(:,4), '-'); ylabel('A_1^V'); xlabel('t');
% subplot(3,2,4); plot(t,y(:,5), '-'); ylabel('A_2^D'); xlabel('t');
% subplot(3,2,6); plot(t,y(:,6), '-'); ylabel('A_2^V'); xlabel('t');

start_flag = 0;
tol = 1e-3;
for ii=round((3/4)*size(t,1)):size(t,1)
   if abs(y(ii,1)) < tol && start_flag == 0 
       start_time = t(ii);
       start_ind = ii;
       start_flag = 1;
       if y(ii,1)>y(ii-1,1)
           upward_flag = 1;
       else
           upward_flag = 0;
       end
   elseif abs(y(ii,1)) < tol && start_flag == 1 && y(ii,1)>y(ii-1,1) && upward_flag == 1
           end_time = t(ii);
           end_ind = ii;
           break
   elseif abs(y(ii,1)) < tol && start_flag == 1 && y(ii,1)<y(ii-1,1) && upward_flag == 0
            end_time = t(ii);
            end_ind = ii;
            break
   end
end

T = end_time - start_time;
tees = t(start_ind:end_ind) - start_time;
return_inds = [1 3 4];
cycle = y(start_ind:end_ind,return_inds);

% %sample cycle at even intervals
% t0 = 0:max_step:T;
% cycle = interp1(tees,cycle,t0);
% tees = t0;

fs = 1/max_step;

figure(1); clf;
subplot(2,2,1); plot(tees, cycle(:,1), '.'); ylabel('\kappa_1'); xlabel('t');%ylim([-1 1]);
subplot(2,2,3); plot(tees, cycle(:,2), '-'); ylabel('A_1^D'); xlabel('t');
subplot(2,2,4); plot(tees, cycle(:,3), '-'); ylabel('A_1^V'); xlabel('t');

end

