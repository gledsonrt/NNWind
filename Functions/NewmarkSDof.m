function [u1, udot1, u2dot1] = NewmarkSDof(p, u, udot, u2dot, beta, gamma, dt, m, c, k)
% Newmark Method for SDOF Linear Systems - P177 Chopra Structural dynamics (with steps)

% p: Force for i time step;
% u: Displacement from i time step;
% udot: Velocity from i time step;
% u2dot: Acceleration from i time step;
% beta, gamma: Time integration parameters;
% dt: Time step;
% m:  Mass;
% c:  Damping;
% k:  Stifness;


% Constants
a1 = 1/(beta.*dt^2).*m+gamma./(beta.*dt).*c;
a2 = 1/(beta.*dt).*m+(gamma./beta-1).*c;
a3 = (1/(2.*beta)-1).*m+dt.*(gamma./(2.*beta)-1).*c;

% Eq. Force and Stiffness
kbar = k+a1;
pbar = p+a1.*u+a2.*udot+a3.*u2dot;

% Integrated time-steps
u1 = pbar./kbar;
udot1 = gamma./(beta.*dt).*(u1-u)+(1-gamma./beta).*udot+dt.*(1-gamma./(2.*beta)).*u2dot;
u2dot1 = 1./(beta.*dt.^2)*(u1-u)-1./(beta.*dt).*udot-(1./(2.*beta)-1)*u2dot;
end

