%simpler_simplemodel
%2-spring unit oscillator

tic

% I_AVB_array = [0.46:0.01:0.54];
I_AVB_array = [0.5];
% I_AVB_array = [0.3:0.01:0.7];
cycles = [];
periods = [];
amps = [];
for jj = 1:size(I_AVB_array,2)
    I_AVB = I_AVB_array(jj);

%timescales
t_f = 10; %mechanical force timescale
t_m = 100; %muscular activity timescale

%assume neural dynamics occur on a fast timescale compared to
%muscle+mechanics s.t. always at steady state - 0 or 1
SD_init = 1;
SV_init = 0;
% I_AVB = 0.48; %driving AVB current
k_SR = 0.01; %stretch receptor weight
eps_h = 0.2; %hysteresis window

I = @(m) I_AVB - k_SR*m;
S = @(I,s) 1*(I>=0.5+eps_h*(0.5-s)) + 0*(I<=0.5+eps_h*(0.5-s));
S_D = @(m) S(I(m), SD_init);
S_V = @(m) S(I(-m), SV_init);

%driving torque- depends pw-linearly on muscle activities AD, AV
pw_lin = @(A) 0*(A<=0) + A*(0<A & A<=1) + 1*(A>=1);
% m0 = @(AD, AV) pw_lin(AD) - pw_lin(AV);
m0 = @(AD, AV) 1*(AD - AV);


%muscle and mechanical ODEs
m_rhs = @(m, AD, AV) -(1/t_f)*(m-m0(AD,AV));
AD_rhs = @(m, AD, AV) (1/t_m)*(S_D(m) - S_V(m) - AD);
AV_rhs = @(m, AD, AV) (1/t_m)*(S_V(m) - S_D(m) - AV);

system = @(t,x) [m_rhs(x(1), x(2), x(3)); AD_rhs(x(1), x(2), x(3)); AV_rhs(x(1), x(2), x(3));];

%integrate
dt = (1/t_m)*10;
tspan = 1:dt:1000;
m_init = -0.6;
AD_init= 0;
AV_init = 0;

y_temp = [m_init; AD_init; AV_init;];
m_temp = y_temp(1);
AD_temp = y_temp(2);
AV_temp = y_temp(3);

%holders for ODE solve data
y=[y_temp];
m = [m_temp];
AD = [AD_temp];
AV = [AV_temp];
sd = [SD_init];
sv = [SV_init];


for i=1:size(tspan,2)-1

     %use analytic solution of ODEs for time step dt
     m_temp = m0(AD_temp, AV_temp) + (m_temp - m0(AD_temp, AV_temp))*exp(-dt/t_f);
     AD_temp = (SD_init- SV_init) + (-(SD_init- SV_init)  + AD_temp)*exp(-dt/t_m);
     AV_temp = (SV_init- SD_init) + (-(SV_init- SD_init)  + AV_temp)*exp(-dt/t_m);
%     %solve ODE w/ fixed neural state - use forward Euler
%     y_temp = y_temp + system(i*dt, y_temp)*dt;
    
    %save ODE data
%     y = [y y_temp;];
    m = [m m_temp;];
    AD = [AD AD_temp;];
    AV = [AV AV_temp;];
    
    %update neural states
%     SD_init = S_D(y_temp(1,end)); 
%     SV_init = S_V(y_temp(1,end));
    SD_init = S_D(m_temp); 
    SV_init = S_V(m_temp);
    sd = [sd SD_init;];
    sv = [sv SV_init;];
%     
%     %remake ODE equations
    S_D = @(m) S(I(m), SD_init);
    S_V = @(m) S(I(-m), SV_init);
%     AD_rhs = @(m, AD, AV) (1/t_m)*(S_D(m) - S_V(m) - AD);
%     AV_rhs = @(m, AD, AV) (1/t_m)*(S_V(m) - S_D(m) - AV);
%     system = @(t,x) [m_rhs(x(1), x(2), x(3)); AD_rhs(x(1), x(2), x(3)); AV_rhs(x(1), x(2), x(3));];
end

y = [m; AD; AV;];

figure(1);
for i=1:3
    plot(tspan,y(i,:)); hold on
end
xlabel('t'); hold off;
legend('m', 'AD', 'AV');

figure(2);
plot(tspan, sd, 'o'); hold on
plot(tspan,sv, 'o'); hold off;
xlabel('t')
legend('SD', 'SV');

toc
%attempt to capture limit cycle and its properties
try
    [cycle, period, amp, mean_c] = extract_cycle(m(2000:end), tspan(2000:end), 10^(-2), 10^2);
    % cycles = [[cycles]; [cycle];];
    periods = [periods; period];
    amps = [amps; amp];
catch
    display('error in finding cycle for ');
    display(I_AVB);
    periods = [periods; 0];
    amps = [amps; 0];
end

end

figure(3);
plot(I_AVB_array, periods, 'o-');
title('periods of torque cycles vs. AVB input current')
xlabel('I_{AVB}'); ylabel('period (in time units)');
figure(4);
plot(I_AVB_array, amps, 'o-')
title('amplitudes of torque cycles vs. AVB input current')
xlabel('I_{AVB}'); ylabel('amp');

