function [derivs] = printFlutterDerivatives()
    set(groot,'defaultAxesTickLabelInterpreter','latex'); 
    set(groot,'defaulttextinterpreter','latex');
    set(groot,'defaultLegendInterpreter','latex');
    
    % Load the two models
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
    
    % Establish the valid Vr & Amplitude range
    vrLims = [max([min(netHeave.props.wind.vrs) min(netPitch.props.wind.vrs)]), ...
               min([max(netHeave.props.wind.vrs) max(netPitch.props.wind.vrs)])];
    ampLims = [max([min(netHeave.props.wind.amplitudes) min(netPitch.props.wind.amplitudes)]), ...
                min([max(netHeave.props.wind.amplitudes) max(netPitch.props.wind.amplitudes)])];

    % Vr range is now fixed, but one amplitude must be selected for the analysis
    % Since the R2 changes with amplitude, let the user seelct it
    dispHeader()
    newAmp = input(strcat('Select an amplitude [', num2str(ampLims(1)), ',...,', num2str(ampLims(2)), ']: #'));
    if isempty(newAmp)
        netHeave.props.wind.amplitudes = mean(ampLims); 
        netPitch.props.wind.amplitudes = mean(ampLims); 
    else
        netHeave.props.wind.amplitudes = newAmp; 
        netPitch.props.wind.amplitudes = newAmp;  
    end
    
    % And now let's select the structural parameters of the model
    U = 20; B = 31; rho = 1.20;
    
    % Now let's create the sampled Vrs that will be used for the analysis
    vrRange = linspace(vrLims(1), vrLims(2), 15);
    
    % And initialize the variables that will store the derivatives for the
    % neural network and for the flat plate model
    derivs = zeros(length(vrRange), 9);
    derivsAS = zeros(length(vrRange), 9);
    derivsAF = zeros(length(vrRange), 9);
    
    % Prevent some Matlab warning messages temporarily
    warning('off','all')
    
    % The loop makes predictions for each vr, and calculates the
    % derivatives at each case
    for i = 1:length(vrRange)
        % Update the current Vr of the model
        netHeave.props.wind.vrs = vrRange(i);
        netPitch.props.wind.vrs = vrRange(i);
        
        % We don't need any validation data for the prediction
        netHeave.props.net.trainPerc = 1;
        netPitch.props.net.trainPerc = 1;
        
        % Now get the D and V vectors, and also the analytical results
        [dataH, ~] = getSEIOPairs(netHeave.props); 
        [dataP, ~] = getSEIOPairs(netPitch.props); 
        
        % Normalize the data in the same range used for training
        [~, dataHNorm] = normalizeData(netHeave.props, dataH, false);
        [~, dataPNorm] = normalizeData(netPitch.props, dataP, false);
        
        % And organize the data for testing
        [InH, ~] = prepareTrainingData(dataHNorm, netHeave.props, false);
        [InP, ~] = prepareTrainingData(dataPNorm, netPitch.props, false);
        
        % Get predictions for heave and pitch
        predsH = predict(netHeave.net, InH); 
        predsP = predict(netPitch.net, InP); 
        
        % Now organize the prediction results
        predVecCLH = zeros(1, length(predsH));
        predVecCMH = zeros(1, length(predsH));
        predVecCLP = zeros(1, length(predsP));
        predVecCMP = zeros(1, length(predsP));
        for k = 1:length(predsH)
            predVecCLH(k) = predsH{k}(1, length(predsH{k}));
            predVecCMH(k) = predsH{k}(2, length(predsH{k}));
            predVecCLP(k) = predsP{k}(1, length(predsP{k}));
            predVecCMP(k) = predsP{k}(2, length(predsP{k}));
        end
        
        % Now de-normalize the predictions
        predVecCLH = (predVecCLH.*sum(abs(netHeave.props.wind.normCL)))-abs(netHeave.props.wind.normCL(1));
        predVecCMH = (predVecCMH.*sum(abs(netHeave.props.wind.normCM)))-abs(netHeave.props.wind.normCM(1));
        predVecCLP = (predVecCLP.*sum(abs(netPitch.props.wind.normCL)))-abs(netPitch.props.wind.normCL(1));
        predVecCMP = (predVecCMP.*sum(abs(netPitch.props.wind.normCM)))-abs(netPitch.props.wind.normCM(1));
        
        % Due to the window method, initial values are lost in prediction
        idxH = length(dataH.CL)-length(predVecCLH)+1:length(dataH.CL);
        dataH.CL = dataH.CL(idxH);
        dataH.CM = dataH.CM(idxH);
        idxP = length(dataP.CL)-length(predVecCLP)+1:length(dataP.CL);
        dataP.CL = dataP.CL(idxP);
        dataP.CM = dataP.CM(idxP);
        
    
        % Adjusting for VXflow results
        if strcmp(netHeave.props.dataType, 'Numerical') 
            predVecCLH = -predVecCLH;
            predVecCMH = -predVecCMH;
        end
        if strcmp(netPitch.props.dataType, 'Numerical') 
            predVecCLP = -predVecCLP;
            predVecCMP = -predVecCMP;
        end
        
        
        % Now let's organize everything for the NN model
        vr = vrRange(i);
        LH = -1/2*rho*U*U*B*predVecCLH;
        MH = 1/2*rho*U*U*B*B*predVecCMH;
        LP = -1/2*rho*U*U*B*predVecCLP;
        MP = 1/2*rho*U*U*B*B*predVecCMP;
        DH = dataH.D(idxH);
        VH = dataH.V(idxH);
        DP = dataP.D(idxP);
        VP = dataP.V(idxP);
        
        % Get the derivatives of the neural network model
        derivs(i,1) = vr;
        [derivs(i,2), derivs(i,3), derivs(i,4), derivs(i,5), derivs(i,6), ...
         derivs(i,7), derivs(i,8), derivs(i,9)] = LSFit(U, B, rho, vr, LH, MH, LP, MP, DH, VH, DP, VP);
        
        % Re-organize and get results for the analytical signal
        LH = -1/2*rho*U*U*B*dataH.CL;
        MH = 1/2*rho*U*U*B*B*dataH.CM;
        LP = -1/2*rho*U*U*B*dataP.CL;
        MP = 1/2*rho*U*U*B*B*dataP.CM;
        derivsAS(i,1) = vr;
        [derivsAS(i,2), derivsAS(i,3), derivsAS(i,4), derivsAS(i,5), derivsAS(i,6), ...
         derivsAS(i,7), derivsAS(i,8), derivsAS(i,9)] = LSFit(U, B, rho, vr, LH, MH, LP, MP, DH, VH, DP, VP);
     
        % Get the analytical formula results
        [derivsAF(i,2), derivsAF(i,3), derivsAF(i,4), derivsAF(i,5), derivsAF(i,6), ...
         derivsAF(i,7), derivsAF(i,8), derivsAF(i,9)] = FPDerivs(vr);

    end
    
    % Plot the results
    figure(); hold on;
    yLabels = {'$H_1^*$', '$H_2^*$', '$H_3^*$', '$H_4^*$', '$A_1^*$', '$A_2^*$', '$A_3^*$', '$A_4^*$'};
    for i = 1:8
        subplot(4,2,i); hold on; grid on; box on; ax = gca; ax.GridLineStyle = ':'; ax.GridAlpha = 1;
        vrs = derivs(:,1);
        theoS = derivsAS(:,i+1);
        theoF = derivsAF(:,i+1);
        pred = derivs(:,i+1);
        plot(vrs, theoS, '-k');
%         plot(vrs, theoF, '--b');
        plot(vrs, pred, '--r');
        ylabel([yLabels{i} ' [-]'], 'interpreter', 'latex', 'fontsize', 10);        
        ytickformat('%1.1f'); 
        xlim([min(vrs) max(vrs)])
        if i < 7
            set(gca,'xticklabel',{[]});
        else
            xlabel('$v_r$ [-]', 'interpreter', 'latex', 'fontsize', 10)
            xtickformat('%1.0f');
            xlim(vrLims)
        end
    end
    
    % Reseting Matlab warnings 
    warning('on','all')
    
    % And now let's save the results in a structure
    dispHeader()
    disp('Select a folder to save the results...');
    results = struct;
    results.ModelH = [pathH fileH];
    results.ModelP = [pathP fileP];
    results.amplitude = newAmp;
    results.derivatives = derivs;
    savePath = uigetdir(pwd, 'Select a folder to save the results...');
    if savePath ~= 0
        saveStr = sprintf('%s\\Derivatives', savePath);
        PaperPos = get(gcf,'PaperPosition'); PaperPos(3) = 16; PaperPos(4) = 10;
        set(gcf,'PaperUnits','centimeters','PaperPosition',PaperPos);
        print(saveStr, '-dpng', '-r300')
        save([saveStr '.mat'], 'results') 
    end
    
end



