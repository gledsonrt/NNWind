function printFlutterAnalysis(derivs)
    set(groot,'defaultAxesTickLabelInterpreter','latex'); 
    set(groot,'defaulttextinterpreter','latex');
    set(groot,'defaultLegendInterpreter','latex');
    
    % Lets select the structural parameters...
    % Standards are for the Great Belt Bridge
    dispHeader()
    flags.Exit = 0;
    U = 40; 
    B = 31;
    m = 22740;
    I = 2470000;
    fh = 0.100;
    fa = 0.278;
    psih = 0.003;
    psia = 0.003;
    while not(flags.Exit)
        flags.mainMenu = 0;
        dispHeader()
        disp('Specify the following parameters:');
        disp(['   #1 Initial analysis wind speed [' num2str(U) 'm/s]']);
        disp(['   #2 Chord length [' num2str(B) 'm]']);
        disp(['   #3 Mass per meter [' num2str(m) 'kg/m]']);
        disp(['   #4 Mass moment of inertia per meter [' num2str(I) 'kgm²/m]']);
        disp(['   #5 First bending natural frequency [' num2str(fh) 'Hz]']);
        disp(['   #6 First torsional natural frequency [' num2str(fa) 'Hz]']);
        disp(['   #7 Damping ratio in the first bending mode [' num2str(psih) ']']);
        disp(['   #8 Damping ratio in the first torsional mode [' num2str(psia) ']']);
        disp('   #0 Proceed with the analysis');
        flags.mainMenu = input(strcat('Selection [', num2str(flags.mainMenu), ']: #'));
        if isempty(flags.mainMenu); flags.mainMenu = 0; end
        switch flags.mainMenu
            case 1
                dispHeader()
                U = input(strcat('New wind speed [', num2str(U), 'm/s]: #'));
                if isempty(U); U = 40; end
            case 2
                dispHeader()
                B = input(strcat('New chord length [', num2str(B), 'm]: #'));
                if isempty(B); B = 31; end
            case 3
                dispHeader()
                m = input(strcat('New mass per meter [', num2str(m), 'kg/m]: #'));
                if isempty(m); m = 22740; end
            case 4
                dispHeader()
                I = input(strcat('New mass moment of inertia per meter [', num2str(I), 'kgm²/m]: #'));
                if isempty(I); I = 2470000; end
            case 5
                dispHeader()
                fh = input(strcat('New bending natural frequency [', num2str(fh), 'Hz]: #'));
                if isempty(fh); fh = 0.100; end
            case 6
                dispHeader()
                fa = input(strcat('New torsional natural frequency [', num2str(fa), 'Hz]: #'));
                if isempty(fa); fa = 0.278; end
            case 7
                dispHeader()
                psih = input(strcat('New damping ratio in the first bending mode [', num2str(psih), ']: #'));
                if isempty(psih); psih = 0.003; end
            case 8
                dispHeader()
                psia = input(strcat('New damping ratio in the first torsional mode [', num2str(psia), ']: #'));
                if isempty(psia); psia = 0.003; end
            case 0
                flags.Exit = 1;
            otherwise
        end
    end
    
    % Once all is set we can start the eigenvalue analysis
    % So assume the air density and calculate the mean circular frequency
    rho = 1.20;  
    omegah = 2*pi*fh;  
    omegaa = 2*pi*fa;  
    omega = (omegah+omegaa)/2; 

    % Numerical setup
    Ustep = 0.5;
    Umax = 200;
    convLimit = 0.001;
    oldDamp = 0;
    flags.DampZero = 0;
    
    % A variable to store the iterative eigenvalue results
    results = [];
    
    % We iterate until the damping is zero
    while ~flags.DampZero
        flags.OmegaStable = 0;
        % And also iterate until the omega value converges
        while ~flags.OmegaStable
            % Calculate the reduced frequency and velocity based on omega
            K = B*omega/U;
            vrInt = 2*pi*U/(B*omega);
            
            % Interpolate the derivatives from input
            H1_int = interp1(derivs(:,1), derivs(:,2), vrInt, 'pchip', 'extrap');
            H2_int = interp1(derivs(:,1), derivs(:,3), vrInt, 'pchip', 'extrap');
            H3_int = interp1(derivs(:,1), derivs(:,4), vrInt, 'pchip', 'extrap');
            H4_int = interp1(derivs(:,1), derivs(:,5), vrInt, 'pchip', 'extrap');
            A1_int = interp1(derivs(:,1), derivs(:,6), vrInt, 'pchip', 'extrap');
            A2_int = interp1(derivs(:,1), derivs(:,7), vrInt, 'pchip', 'extrap');
            A3_int = interp1(derivs(:,1), derivs(:,8), vrInt, 'pchip', 'extrap');
            A4_int = interp1(derivs(:,1), derivs(:,9), vrInt, 'pchip', 'extrap');
            
            % Calculating 'aij'
            a21 = 1/(2*m)*rho*U*U*B*K*K*H4_int/B - m/m*omegah*omegah;
            a22 = 1/(2*m)*rho*U*U*B*K*H1_int/U - 2*m*psih*omegah/m;
            a23 = 1/(2*m)*rho*U*U*B*K*K*H3_int;
            a24 = 1/(2*m)*rho*U*U*B*K*H2_int*B/U;
            a41 = 1/(2*I)*rho*U*U*B*B*K*K*A4_int/B;
            a42 = 1/(2*I)*rho*U*U*B*B*K*A1_int/U;
            a43 = 1/(2*I)*rho*U*U*B*B*K*K*A3_int - I/I*omegaa*omegaa;
            a44 = 1/(2*I)*rho*U*U*B*B*K*A2_int*B/U - 2*I/I*psia*omegaa;
            
            % Assemble matrix 'A'
            A = [0 1 0 0;a21 a22 a23 a24;0 0 0 1;a41 a42 a43 a44];
            
            % Run the eigenvalue analysis
            eigenv = eig(A);
            
            % Check for maximum omega value from eigenvalue analysis
            [omegaMax, numberMax] = max(imag(eigenv));
            omegaOld = omega;
            omega = omegaMax;
            
            % Check if omega converged
            if abs((omegaOld - omegaMax)/omegaOld) < convLimit
                flags.OmegaStable = 1;      
            end 
        end  
        
        % Update the result matrix with the new eigenvalue solutions
        results = [results; [U; eigenv]'];
        
        % Now we check if the maximum wind speed was reached, and if the
        % damping value is still higher than 0.
        % If that's the case, interpolate to find final velocity
        if (real(eigenv(numberMax)) > 0) || (U+Ustep > Umax)
            flags.DampZero = 1; 
            Uflutter = U - Ustep/(real(eigenv(numberMax))-oldDamp)*real(eigenv(numberMax));
        else
            U = U + Ustep;
        end
        oldDamp = real(eigenv(numberMax));
    end
    
    % Now organize damping, frequenci and velocity values
    zetaVec = -real(results(:,2:5))./(real(results(:,2:5)).^2 + imag(results(:,2:5)).^2).^(1/2);
    omegaVec = imag(results(:,2:5));
    velVec = results(:,1);
    
    % Should we save results somewhere?
    dispHeader()
    disp('Select a folder to save the results...')
    savePath = uigetdir(pwd, 'Select a folder to save the results...');       
    
    % Plots the relation of damping and frequency
    figure(); hold on; grid on; box on; ax = gca; ax.GridLineStyle = ':'; ax.GridAlpha = 1;
    plot(zetaVec(:,1), omegaVec(:,1), '--k');
    p1 = plot(zetaVec(:,2), omegaVec(:,2), '--k');
    p2 = plot(zetaVec(:,3), omegaVec(:,3), '-k');
    plot(zetaVec(:,4), omegaVec(:,4), '-k');
    legend([p1, p2], {'Heave', 'Pitch'})
    xlabel('$\zeta$ [-]', 'Interpreter', 'latex')
    ylabel('$\omega$ [rad/s]', 'Interpreter', 'latex')
    if savePath ~= 0
        saveStr = sprintf('%s\\Flutter01', savePath);
        PaperPos = get(gcf,'PaperPosition'); PaperPos(3) = 12; PaperPos(4) = 5;
        set(gcf,'PaperUnits','centimeters','PaperPosition',PaperPos);
        print(saveStr, '-dpng', '-r300')
    end
    
    % And also plot the development of each according to the velocity
    figure(); 
    subplot(1,2,1); hold on; grid on; box on; ax = gca; ax.GridLineStyle = ':'; ax.GridAlpha = 1;
    p1 = plot(velVec, omegaVec(:,2), '--k');
    p2 = plot(velVec, omegaVec(:,4), '-k');
    legend([p1, p2], {'Heave', 'Pitch'}, 'Location', 'best')
    xlabel('$U_{\infty}$ [m/s]', 'Interpreter', 'latex')
    ylabel('$\omega$ [rad/s]', 'Interpreter', 'latex')
    subplot(1,2,2); hold on; grid on; box on; ax = gca; ax.GridLineStyle = ':'; ax.GridAlpha = 1;
    p1 = plot(velVec, zetaVec(:,2), '--k');
    p2 = plot(velVec, zetaVec(:,4), '-k');
    legend([p1, p2], {'Heave', 'Pitch'}, 'Location', 'best')
    xlabel('$U_{\infty}$ [m/s]', 'Interpreter', 'latex')
    ylabel('$\zeta$ [-]', 'Interpreter', 'latex')
    if savePath ~= 0
        saveStr = sprintf('%s\\Flutter02', savePath);
        PaperPos = get(gcf,'PaperPosition'); PaperPos(3) = 16; PaperPos(4) = 5;
        set(gcf,'PaperUnits','centimeters','PaperPosition',PaperPos);
        print(saveStr, '-dpng', '-r300')
    end
    
    % Now let's display the final results
    dispHeader()
    disp(['Flutter velocity: ' num2str(Uflutter) ' m/s   (vr = ' num2str(round(2*pi*Uflutter/(B*omega), 2)) ')']);
    disp(['Circular frequency: ' num2str(omega) ' rad/s']);
    disp(' ')
    dummy = input('<press any key to return>');
end