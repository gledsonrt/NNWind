function [FL, FM, CL, CM, D, V, A, T] = getSEFlatPlateData(U,B,vr,amplitude,DeltaT,Nstep,HeavePitch)
    % Calculates the self-excited response due to harmonic oscillations
    % based on Theodorsen theory
    
    % Assume air density
    % Calculate parameters
    rho=1.20;           b=B/2;
    f0=U/(B*vr);        T0=1/f0;        omega=2*pi/T0;
    k=2*pi*(1/T0)*b/U;  K=2*pi*(1/T0)*B/U;
    
    % Initialize the time vector
    time=(1:Nstep)'*DeltaT;
    
    % The amplitudes are given in angle, change to radians
    amplitude = amplitude*pi/180;
    
    if HeavePitch == 1
        % For pitch, consider directly the angle
        dp = amplitude;
        dh=0;
    else
        % For heave, calculate the equivalent motion
        dh = atan(amplitude)*U/omega; 
        dp=0;
    end 
    
    % Theodorsen circulation function
    i=sqrt(-1);
    C=conj(besselh(1,k))/(conj(besselh(1,k))+ i*conj(besselh(0,k)));
    
    % Forced vibration signal, for heave and pitch motions
    hh = +(dh*i)*exp(i*omega*time);
    vh = -(dh*omega)*exp(i*omega*time);
    ah = -(dh*i*omega*omega)*exp(i*omega*time);
        
    hp = -(dp*i)*exp(i*omega*time);
    vp = +(dp*omega)*exp(i*omega*time);
    ap = +(dp*i*omega*omega)*exp(i*omega*time);
    
    
    % Calculate the forces
    FL =real(-0.5*rho*U*U*B*2*pi*C*(hp+vh/U+0.25*B*vp/U)); 
    FM =real(0.5*rho*U*U*B*B*(pi/2)*C*(hp+vh/U+0.25*B*vp/U)); 
    if true 
        % Includes the apparent mass terms
        FL = FL + real(-(pi/4)*rho*B*B*(ah+U*vp));
        FM = FM + real(-(pi/8)*rho*B*B*B*(U*vp/2+(B/16)*ap));
    end
    
    % Flip lift forces (Theodorsen defines lift downwards)
    FL = -FL;
   
    % Calculates the wind coefficients
    CL = FL/(0.5*rho*U*U*B);
    CM = FM/(0.5*rho*U*U*B*B);
    
    % Returns the displacements, velocities and accelerations
    if HeavePitch==1    %pitch
        D = real(hp);
        V = real(vp);
        A = real(ap);
    else                %heave
        D = real(hh);
        V = real(vh);
        A = real(ah);
    end 
    
    % Returns the time
    T = time;
    
end