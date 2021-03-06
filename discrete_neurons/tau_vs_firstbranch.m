%plot first solution branches for diff tau

%fixed parameters
%params
eps = 2;
c = 1;
I = 0.1;

%results in
K_V_ON = eps/2-I;
K_V_OFF = -eps/2-I;

% tau = [0.01; 0.1; 0.2; 0.3; 0.4; 0.5; 0.6; 0.7; 0.8; 0.9; 1.1; 10;];
tau = 1.1;

for ii = 1:size(tau,1);
   figure(ii); clf;    
   title_plot = strcat('tau = ', num2str(tau(ii)));
   for alpha= -10:0.25:0.5
        B = (K_V_OFF - c + alpha)/(1-1/tau(ii));
        A = K_V_OFF - c - B;
        K = @(t) c + A*exp(-t) + B*exp(-t./tau(ii));
        Kdot = @(t) -A*exp(-t) - B./tau(ii)*exp(-t./tau(ii));
        t = linspace(0, 100, 1000)';
        kk = K(t);
        kprime = Kdot(t);
        plot(kk, kprime); hold on;
%         plot(t, kk); hold on;
   end
   line([K_V_ON,K_V_ON],[-10,10]);
%    line([-3, 2], [0.2,0.2]);
%    line([0,10],[K_V_ON,K_V_ON]);
   title(title_plot);
   xlabel('\kappa'); ylabel('d\kappa/dt');
   hold off
    
    
end