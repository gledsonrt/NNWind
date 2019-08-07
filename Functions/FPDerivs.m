function [H1, H2, H3, H4, A1, A2, A3, A4] = FPDerivs(vr)
    % Calculates the aerodynamic derivatives of a flat plate
    % according to the analytical method (Scanlan)
    % Assuming a = 0
    a = 0;
    K = 2*pi/vr; k = K/2;
    C = conj(besselh(1,k))/(conj(besselh(1,k))+ 1i*conj(besselh(0,k)));
    F = real(C);    G = imag(C);
    H1 = -2*pi*K*F/(K^2);
    H2 = (-pi*K/2)*(1 + 4*G/K + 2*(0.5-a)*F)/(K^2);
    H3 = -pi*(2*F - (0.5-a)*G*K + a*K*K/4)/(K^2);
    H4 = 0.5*pi*K*K*(1 + 4*G/K)/(K^2);
    A1 = pi*K*F*(0.5+a)/(K^2);
    A2 = (-pi/2)*(0.5*K*(0.5-a) - 2*G*(0.5+a) + K*F*(a*a-0.25))/(K^2);
    A3 = 0.5*pi*(1/4*K*K*(a*a + 1/8) + 2*F*(0.5+a) + K*G*(a*a-0.25))/(K^2);
    A4 = (-pi/2)*(a*K*K/2 + 2*K*G*(0.5+a))/(K^2);
end