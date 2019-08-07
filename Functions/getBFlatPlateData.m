function [FL, FM, CL, CM, V, A, T] = getBFlatPlateData(U, B, vr, amplit, DeltaT, Nstep)
    % Calculate the buffeting forces for harmonical oscillations
    
    % Assumed air density
    rho=1.20;
    
    % Calculate frequencies according to provided data
    f0 = U/(vr*B); 
    omega = 2*pi*f0;
    K = 2*pi/vr; k = K/2;
    
    % Create time, harmonic gust and derivative vectors
    T = (1:Nstep)'*DeltaT;
    W = amplit*exp(1i*omega*T);
    Wdot = amplit*1i*omega*exp(1i*omega*T);
    
    % The implementation of Sears Admittance
    Sears = @(k) (besselj(0,k).*conj(besselh(1,k)) - besselj(1,k).*conj(besselh(0,k)))./(conj(besselh(1,k)) + 1i.*conj(besselh(0,k)));
    
    % Admittance in the front tip of the flat plate
    % Introduces a lag of t = B/(2U)
%     Sears = @(k) (1 - 0.5./(k - 0.13i) - 0.5./(k-1i));

    % Calculate forces according to Sears
    FL = real(1/2*rho*B*U*pi*W*Sears(k));
    FM = real(1/8*rho*B*B*U*pi*W*Sears(k));
    
    % Transform to coefficients
    CL = FL/(1/2*rho*U*U*B);
    CM = FM/(1/2*rho*U*U*B*B);
    
    % Return the real parts of velocity and acceleration
    V = real(W);
    A = real(Wdot);
end