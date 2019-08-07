function [H1, H2, H3, H4, A1, A2, A3, A4] = LSFit(U, B, rho, vr, LH, MH, LP, MP, DH, VH, DP, VP)
    % Calculating the aerodynamic derivatives using the least squares fit method
    K = 2*pi/vr;
    
    temp = size(LH); if temp(1) < temp(2); LH = LH'; end
    temp = size(MH); if temp(1) < temp(2); MH = MH'; end
    temp = size(LP); if temp(1) < temp(2); LP = LP'; end
    temp = size(MP); if temp(1) < temp(2); MP = MP'; end
    
    Ss = zeros(length(DH), 2);
    Ss(:,1) = 0.5*rho*U*U*B*real(VH)*K/U; 
    Ss(:,2) = 0.5*rho*U*U*B*real(DH)*K*K/B;
    StF = Ss'*LH;
    StS = Ss'*Ss;
    HH = StS\StF;
    H1 = HH(1); H4 = HH(2);
    
    Ss = zeros(length(DH), 2);
    Ss(:,1) = 0.5*rho*U*U*B*B*real(VH)*K/U;
    Ss(:,2) = 0.5*rho*U*U*B*B*real(DH)*K*K/B;
    StF = Ss'*MH;
    StS = Ss'*Ss;
    HH = StS\StF;
    A1 = HH(1); A4 = HH(2);
    
    Ss = zeros(length(DH), 2);
    Ss(:,1) = 0.5*rho*U*U*B*B*real(VP)*K/U;
    Ss(:,2) = 0.5*rho*U*U*B*real(DP)*K*K;
    StF = Ss'*LP;
    StS = Ss'*Ss;
    HH = StS\StF;
    H2 = HH(1); H3 = HH(2);
    
    Ss = zeros(length(DH), 2);
    Ss(:,1) = 0.5*rho*U*U*B*B*B*real(VP)*K/U;
    Ss(:,2) = 0.5*rho*U*U*B*B*real(DP)*K*K;
    StF = Ss'*MP;
    StS = Ss'*Ss;
    HH = StS\StF;
    A2 = HH(1); A3 = HH(2);
end