function printCoupledAnalysis()
    set(groot,'defaultAxesTickLabelInterpreter','latex'); 
    set(groot,'defaulttextinterpreter','latex');
    set(groot,'defaultLegendInterpreter','latex');
    
    % For the Newmark-Beta Method
    beta = 1/4;
    gamma = 1/2;
    
    % Air density
    rho = 1.20;
    
    % Lets select the structural parameters...
    % Standards are for the Great Belt Bridge
    dispHeader()
    flags.Exit = 0;
    U = 20; 
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
        disp(['   #1 Wind speed [' num2str(U) 'm/s]']);
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
                if isempty(U); U = 20; end
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
    
    % Load the network model and check if its ok
    dispHeader()
    disp('Select the network model for the buffeting forces...')
    [file, path] = uigetfile('*.mat', 'Select the network model for the buffeting forces.');
    if file ~= 0; netB = load([path file]); else; error('Invalid model file.'); end
    if ~(strcmp(netB.props.modelType, 'Buffeting')); error('Invalid model file.'); end
    
    % Load the two models of the self-excited forces
    dispHeader()
    disp('Select the network model for SE forces in the heave DOF...')
    [fileH, pathH] = uigetfile('*.mat', 'Select the network model for SE forces in the heave DOF.');
    if fileH ~= 0; netHeave = load([pathH fileH]); else; error('Invalid model file.'); end
    
    dispHeader()
    disp('Select the network model for SE forces in the pitch DOF...')
    [fileP, pathP] = uigetfile('*.mat', 'Select the network model for SE forces in the pitch DOF.');
    if fileP ~= 0; netPitch = load([pathP fileP]); else; error('Invalid model file.'); end
    
    % Check the models
    flags.Check = 1;
    if ~(strcmp(netHeave.props.modelType, 'SelfExcited') && strcmp(netHeave.props.wind.movType, 'H')); flags.Check = 0; end
    if ~(strcmp(netPitch.props.modelType, 'SelfExcited') && strcmp(netPitch.props.wind.movType, 'P')); flags.Check = 0; end
        
    % Is everything ok?
    if ~(flags.Check == 1); error('Invalid model files.'); end
    
    % Load the data for the random gust
    dispHeader()
    disp('Select the random gust data file...')
    [fileRND, pathRND] = uigetfile('*.mat', 'Select the random gust data file.');
    if fileRND ~= 0
        rndDisp = load([pathRND fileRND]);
        fnames = fieldnames(rndDisp); 
        if length(fnames) == 1; rndDisp = rndDisp.(fnames{1}); end
        fnames = fieldnames(rndDisp);
        dispHeader()
        Fs = input(strcat('Input the sampling frequency for the data acquisition [Hz]: #'));    Dt = 1/Fs;
        if any(strcmp(fnames,'V'))
            % Get the time derivative, if it doesn't exist
            if ~any(strcmp(fnames,'A'))
                rndDisp.A = gradient(rndDisp.V)./Dt;
            end
            % Force the vectors to have the same length
            minLen = min([length(rndDisp.V) length(rndDisp.A)]);
            rndDisp.V = rndDisp.V(1:minLen);
            rndDisp.A = rndDisp.A(1:minLen);
        else
            error('The selected dataset does not contain all the required fields.');
        end
    else
        error('Invalid dataset file.');
    end
    
    % We don't need any validation data for the prediction
    netB.props.net.trainPerc = 1;
    netHeave.props.net.trainPerc = 1;
    netPitch.props.net.trainPerc = 1;
    
    % The structural parameters are rearranged
    M = [m I];
    F = [fh fa];
    C = [psih psia];    
    K = 4*pi^2*F.^2.*M;
    C = 4*pi*F.*C.*M;
    
    % Allocate vectors for results
    UVec = zeros(minLen,2);
    UVecDot = zeros(minLen,2);
    UVec2Dot = zeros(minLen,2);
    P = zeros(minLen,2);
    SE_L_H = zeros(minLen,1);
    SE_M_H = zeros(minLen,1);
    SE_L_P = zeros(minLen,1);
    SE_M_P = zeros(minLen,1);
    B_L = zeros(minLen,1);
    B_M = zeros(minLen,1);
    
    % Initialize the wait bar for progress
    dispHeader()
    disp('Running analysis...')   
    h = waitbar(0,'Running analysis...'); % Progress bar
    set(findall(h,'type','text'),'Interpreter','none');
    
    % Main loop
    i_0 = ceil(netB.props.net.winLen*netB.props.wind.Nsteps)+1;
    for i = i_0:minLen
        % Select the appropriate range for the buffeting analysis
        if i > ceil(netB.props.net.winLen*netB.props.wind.Nsteps)+1; initB = i-ceil(netB.props.net.winLen*netB.props.wind.Nsteps); 
        else; initB = 1; end 
        dataB.V = rndDisp.V(initB:i, 1); dataB.A = rndDisp.A(initB:i, 1);
        
        % Normalize and arrange into prediction format
        [~, dataBNorm] = normalizeData(netB.props, dataB, false);
        tempBIn = {[dataBNorm.V dataBNorm.A]'};
        
        % predict the coefficients
        preds = predict(netB.net, tempBIn); 
    
        % Now de-normalize and organize the prediction results
        B_L(i) = (preds{1}(1,end).*sum(abs(netB.props.wind.normCL)))-abs(netB.props.wind.normCL(1));
        B_M(i) = (preds{1}(2,end).*sum(abs(netB.props.wind.normCM)))-abs(netB.props.wind.normCM(1));
        
        % Select the appropriate range for the self-excited analysis: heave
        if i > ceil(netHeave.props.net.winLen*netHeave.props.wind.Nsteps)+i_0; initSE = i-ceil(netHeave.props.net.winLen*netHeave.props.wind.Nsteps);  
        else; initSE = i_0-1; end 
            
        % The heave predictions...
        dataSE.D = UVec(initSE:i, 1); dataSE.V = UVecDot(initSE:i, 1);
        
        % Normalize and arrange into prediction format
        [~, dataSEHNorm] = normalizeData(netHeave.props, dataSE, false);
        tempSEHIn = {[dataSEHNorm.D dataSEHNorm.V]'};
        
        % predict the coefficients
        preds = predict(netHeave.net, tempSEHIn); 
        
        % Now de-normalize and organize the prediction results
        SE_L_H(i) = (preds{1}(1, length(preds{1})).*sum(abs(netHeave.props.wind.normCL)))-abs(netHeave.props.wind.normCL(1));
        SE_M_H(i) = (preds{1}(2, length(preds{1})).*sum(abs(netHeave.props.wind.normCM)))-abs(netHeave.props.wind.normCM(1));
        
        % Select the appropriate range for the self-excited analysis: heave
        if i > ceil(netPitch.props.net.winLen*netPitch.props.wind.Nsteps)+i_0; initSE = i-ceil(netPitch.props.net.winLen*netPitch.props.wind.Nsteps);  
        else; initSE = i_0-1; end 
        
        % The pitch predictions...
        dataSE.D = UVec(initSE:i, 2); dataSE.V = UVecDot(initSE:i, 2);
        
        % Normalize and arrange into prediction format
        [~, dataSEPNorm] = normalizeData(netPitch.props, dataSE, false);
        tempSEPIn = {[dataSEPNorm.D dataSEPNorm.V]'};
        
        % predict the coefficients
        preds = predict(netPitch.net, tempSEPIn); 
        
        % Now de-normalize and organize the prediction results
        SE_L_P(i) = (preds{1}(1, length(preds{1})).*sum(abs(netPitch.props.wind.normCL)))-abs(netPitch.props.wind.normCL(1));
        SE_M_P(i) = (preds{1}(2, length(preds{1})).*sum(abs(netPitch.props.wind.normCM)))-abs(netPitch.props.wind.normCM(1));
        
        % Adjusting for VXflow results
        if strcmp(netHeave.props.dataType, 'Numerical') 
            SE_L_H(i) = -SE_L_H(i);
            SE_M_H(i) = -SE_M_H(i);
        end
        if strcmp(netPitch.props.dataType, 'Numerical') 
            SE_L_P(i) = -SE_L_P(i);
            SE_M_P(i) = -SE_M_P(i);
        end
                       
        % Calculate forces and store results
        P(i,1) = -(SE_L_H(i) + SE_L_P(i))*(1/2*rho*U*U*B) - (B_L(i))*(1/2*rho*U*U*B);
        P(i,2) = (SE_M_H(i) + SE_M_P(i))*(1/2*rho*U*U*B*B) + (B_M(i))*(1/2*rho*U*U*B*B);
        
        % Integrate next time-steps
        [UVec(i+1,:),UVecDot(i+1,:),UVec2Dot(i+1,:)] = NewmarkSDof(P(i,:), UVec(i,:), UVecDot(i,:), UVec2Dot(i,:), beta, gamma, Dt, M, C, K);
        
        % Update progress bar
        if mod(i, 100) == 0
            waitbar(i/minLen,h,sprintf('Running analysis: %2.1f%% done',i/minLen*100))
        end
    end
    
    % Close progress bar
    close(h);
    
    % Select the valid range
    idx = i_0:minLen;
    
    % Time vector based on the sampling frequency
    timeVec = linspace(0, length(idx)/Fs, length(idx));
    
    % Should we save the results?
    dispHeader()
    disp('Select a folder to save the results.')
    savePath = uigetdir(pwd, 'Select a folder to save the results...');
    results = struct;
    results.T = timeVec;
    results.DH = UVec(idx, 1);
    results.DP = UVec(idx, 2);
    results.FL = P(idx, 1) - P(i_0, 1);
    results.FM = P(idx, 2) - P(i_0, 2);
    results.CL_B = B_L(idx) - B_L(i_0);
    results.CL_SE_H = SE_L_H(idx) - SE_L_H(i_0);
    results.CL_SE_P = SE_L_P(idx) - SE_L_P(i_0);
    results.CM_B = B_M(idx) - B_M(i_0);
    results.CM_SE_H = SE_M_H(idx) - SE_M_H(i_0);
    results.CM_SE_P = SE_M_P(idx) - SE_M_P(i_0);
    if savePath ~= 0
        saveStr = sprintf('%s\\coupledAnalysisResults', savePath);
        save([saveStr '.mat'], 'results')
    end    
    
    % Plot of forces
    figure();
    subplot(2,1,1); hold on; grid on; box on; ax = gca; ax.GridLineStyle = ':'; ax.GridAlpha = 1;
    plot(timeVec, results.FL./1000, '-k')
    xlabel('$t$ [s]', 'Interpreter', 'latex')
    ylabel('$F_{L}$ k[N]', 'Interpreter', 'latex')
    subplot(2,1,2); hold on; grid on; box on; ax = gca; ax.GridLineStyle = ':'; ax.GridAlpha = 1;
    plot(timeVec, results.FM./1000, '-k')
    xlabel('$t$ [s]', 'Interpreter', 'latex')
    ylabel('$F_{M}$ [kNm]', 'Interpreter', 'latex')
    if savePath ~= 0
        saveStr = sprintf('%s\\coupledAnalysisForces', savePath);
        PaperPos = get(gcf,'PaperPosition'); PaperPos(3) = 16; PaperPos(4) = 10;
        set(gcf,'PaperUnits','centimeters','PaperPosition',PaperPos);
        print(saveStr, '-dpng', '-r300')
    end
    
    % Plot of displacements
    figure();
    subplot(2,1,1); hold on; grid on; box on; ax = gca; ax.GridLineStyle = ':'; ax.GridAlpha = 1;
    plot(timeVec, results.DH, '-k')
    xlabel('$t$ [s]', 'Interpreter', 'latex')
    ylabel('$h$ [m]', 'Interpreter', 'latex')
    subplot(2,1,2); hold on; grid on; box on; ax = gca; ax.GridLineStyle = ':'; ax.GridAlpha = 1;
    plot(timeVec, results.DP, '-k')
    xlabel('$t$ [s]', 'Interpreter', 'latex')
    ylabel('$\alpha$ [rad]', 'Interpreter', 'latex')
    if savePath ~= 0
        saveStr = sprintf('%s\\coupledAnalysisDisplacements', savePath);
        PaperPos = get(gcf,'PaperPosition'); PaperPos(3) = 16; PaperPos(4) = 10;
        set(gcf,'PaperUnits','centimeters','PaperPosition',PaperPos);
        print(saveStr, '-dpng', '-r300')
    end
    
end