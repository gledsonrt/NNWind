function printSERandomDisp()
% Response due to random self-excited motion
%
%   After loading the two neural networks, load the random displacement data.
%   The data should be organized in a Matlab structure with the following fields:
%       DH   -  Displacements in the heave DOF 
%       DP   -  Rotations in the pitch DOF
%       VH   -  Velocities in the heave DOF
%       VP   -  Velocities in the pitch DOF
%
%   In case any velocity is abscent, the sampling frequency will be asked
%   in order to numerically calculate the time derivative of the displacement.
%
    
    dispHeader()
    help printSERandomDisp;
    dummy = input('<press any key to continue>');
    
    set(groot,'defaultAxesTickLabelInterpreter','latex'); 
    set(groot,'defaulttextinterpreter','latex');
    set(groot,'defaultLegendInterpreter','latex');
    
    % Load the two models
    dispHeader()
    disp('Select the network model for SE forces in the heave DOF...')
    [fileH, pathH] = uigetfile('*.mat', 'Select the network model for SE forces in the heave DOF.');
    if fileH ~= 0; netHeave = load([pathH fileH]); else; return; end
    
    dispHeader()
    disp('Select the network model for SE forces in the pitch DOF...')
    [fileP, pathP] = uigetfile('*.mat', 'Select the network model for SE forces in the pitch DOF.');
    if fileP ~= 0; netPitch = load([pathP fileP]); else; return; end
    
    % Check the models
    flags.Check = 1;
    if ~(strcmp(netHeave.props.modelType, 'SelfExcited') && strcmp(netHeave.props.wind.movType, 'H')); flags.Check = 0; end
    if ~(strcmp(netPitch.props.modelType, 'SelfExcited') && strcmp(netPitch.props.wind.movType, 'P')); flags.Check = 0; end
        
    % Is everything ok?
    if ~(flags.Check == 1); error('Invalid model files.'); end
    
    % Load the data for the random displacement
    dispHeader()
    disp('Select the random displacement file...')
    [fileRND, pathRND] = uigetfile('*.mat', 'Select the random displacement file.');
    if fileRND ~= 0
        rndDisp = load([pathRND fileRND]);
        fnames = fieldnames(rndDisp); 
        if length(fnames) == 1; rndDisp = rndDisp.(fnames{1}); end
        fnames = fieldnames(rndDisp);
        if any(strcmp(fnames,'DH')) && any(strcmp(fnames,'DP'))
            % Get the velocities in heave, if they do not exist
            if ~any(strcmp(fnames,'VH'))
                dispHeader()
                FsH = input(strcat('Input the sampling frequency for the heave data [Hz]: #'));
                Dt = 1/FsH; rndDisp.VH = gradient(rndDisp.DH)./Dt;
            end
            % Get the velocities in pitch, if they do not exist
            if ~any(strcmp(fnames,'VP'))
                dispHeader()
                FsP = input(strcat('Input the sampling frequency for the pitch data [Hz]: #'));
                Dt = 1/FsP; rndDisp.VP = gradient(rndDisp.DP)./Dt;
            end
            % Force the vectors to have the same length
            minLen = min([length(rndDisp.DH) length(rndDisp.DP) length(rndDisp.VH) length(rndDisp.VP)]);
            rndDisp.DH = rndDisp.DH(1:minLen);
            rndDisp.DP = rndDisp.DP(1:minLen);
            rndDisp.VH = rndDisp.VH(1:minLen);
            rndDisp.VP = rndDisp.VP(1:minLen);
        else
            error('The selected dataset does not contain all the required fields.');
        end
    else
        error('Invalid dataset file.');
    end
    
    % Now split the inputs into a heave and a pitch datasets
    dataH.D = rndDisp.DH;
    dataH.V = rndDisp.VH;
    dataP.D = rndDisp.DP;
    dataP.V = rndDisp.VP;
    
    % Is the data within the training range?
    checkPredictionRange(dataH, netHeave.props)
    checkPredictionRange(dataP, netPitch.props)
    
    % We don't need any validation data for the prediction
    netHeave.props.net.trainPerc = 1;
    netPitch.props.net.trainPerc = 1;
 
    % Normalize the data in the same range used for training
    [~, dataHNorm] = normalizeData(netHeave.props, dataH, false);
    [~, dataPNorm] = normalizeData(netPitch.props, dataP, false);
    
    % And organize the data for testing
    [InH, ~] = prepareTrainingData(dataHNorm, netHeave.props, false);
    [InP, ~] = prepareTrainingData(dataPNorm, netPitch.props, false);
    
    % Get predictions for heave and pitch
    dispHeader()
    disp('Making predictions...')
    predsH = predict(netHeave.net, InH); 
    predsP = predict(netPitch.net, InP); 
    
    % The total analysis length depends also on the network setings, so to
    % be consistent we seelct the smallest possble number of time-steps
    totLen = min([length(predsH), length(predsP)]);
    
    % Now organize the prediction results
    predVecCLH = zeros(1, totLen);
    predVecCMH = zeros(1, totLen);
    predVecCLP = zeros(1, totLen);
    predVecCMP = zeros(1, totLen);
    for k = 1:totLen
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
    
    % Center at 0
    predVecCLH = predVecCLH - predVecCLH(1);
    predVecCMH = predVecCMH - predVecCMH(1);
    predVecCLP = predVecCLP - predVecCLP(1);
    predVecCMP = predVecCMP - predVecCMP(1);
    
    % Adjusting for VXflow results
    if strcmp(netHeave.props.dataType, 'Numerical') 
        predVecCLH = -predVecCLH;
        predVecCMH = -predVecCMH;
    end
    if strcmp(netPitch.props.dataType, 'Numerical') 
        predVecCLP = -predVecCLP;
        predVecCMP = -predVecCMP;
    end
    
    % Let's check if we have information about time
    if exist('FsH', 'var')
        timeVecH = linspace(0, length(predVecCLH)/FsH, length(predVecCLH));
    else
        dispHeader()
        disp('Input the sampling frequency, or leave blank to plot as time-steps.')
        FsH = input(strcat('Sampling frequency [Hz]: #'));
        if ~isempty(FsH) 
            timeVecP = linspace(0, length(predVecCLP)/FsH, length(predVecCLP));
            timeVecH = linspace(0, length(predVecCLH)/FsH, length(predVecCLH));
        else
            timeVecH = 1:length(predVecCLH);
            timeVecP = 1:length(predVecCLP);
        end
    end
    if exist('FsP', 'var')
        timeVecP = linspace(0, length(predVecCLP)/FsP, length(predVecCLP));
    end
    
    % Should we save the results?
    dispHeader()
    disp('Select a folder to save the results.')
    savePath = uigetdir(pwd, 'Select a folder to save the results...');
    if savePath ~= 0
        results = struct;
        results.CLH = predVecCLH;
        results.CMH = predVecCMH;
        results.CLP = predVecCLP;
        results.CMP = predVecCMP;
        saveStr = sprintf('%s\\rndDisplacementResults', savePath);
        save([saveStr '.mat'], 'results')
    end
    
    % Now plot the resulting CM and CL, in heave
    figure();
    subplot(2,1,1); hold on; grid on; box on; ax = gca; ax.GridLineStyle = ':'; ax.GridAlpha = 1;
    plot(timeVecH, predVecCLH, '-k')
    if ~isempty(FsH) 
        xlabel('$t$ [s]', 'Interpreter', 'latex')
    else
        xlabel('Time-Step [-]', 'Interpreter', 'latex')
    end
    ylabel('$C_{L,h}$ [-]', 'Interpreter', 'latex')
    ytickformat('%1.2f');
    subplot(2,1,2); hold on; grid on; box on; ax = gca; ax.GridLineStyle = ':'; ax.GridAlpha = 1;
    plot(timeVecH, predVecCMH, '-k')
    if ~isempty(FsH) 
        xlabel('$t$ [s]', 'Interpreter', 'latex')
    else
        xlabel('Time-Step [-]', 'Interpreter', 'latex')
    end
    ylabel('$C_{M,h}$ [-]', 'Interpreter', 'latex')
    ytickformat('%1.3f');
    if savePath ~= 0
        saveStr = sprintf('%s\\rndDisplacementHeave', savePath);
        PaperPos = get(gcf,'PaperPosition'); PaperPos(3) = 16; PaperPos(4) = 10;
        set(gcf,'PaperUnits','centimeters','PaperPosition',PaperPos);
        print(saveStr, '-dpng', '-r300')
    end
    
    % And the plot in pitch
    figure();
    subplot(2,1,1); hold on; grid on; box on; ax = gca; ax.GridLineStyle = ':'; ax.GridAlpha = 1;
    plot(timeVecP, predVecCLP, '-k')
    if ~isempty(FsH) 
        xlabel('$t$ [s]', 'Interpreter', 'latex')
    else
        xlabel('Time-Step [-]', 'Interpreter', 'latex')
    end
    ylabel('$C_{L,\alpha}$ [-]', 'Interpreter', 'latex')
    ytickformat('%1.2f');
    subplot(2,1,2); hold on; grid on; box on; ax = gca; ax.GridLineStyle = ':'; ax.GridAlpha = 1;
    plot(timeVecP, predVecCMP, '-k')
    if ~isempty(FsH) 
        xlabel('$t$ [s]', 'Interpreter', 'latex')
    else
        xlabel('Time-Step [-]', 'Interpreter', 'latex')
    end
    ylabel('$C_{M,\alpha}$ [-]', 'Interpreter', 'latex')
    ytickformat('%1.3f');
    if savePath ~= 0
        saveStr = sprintf('%s\\rndDisplacementPitch', savePath);
        PaperPos = get(gcf,'PaperPosition'); PaperPos(3) = 16; PaperPos(4) = 10;
        set(gcf,'PaperUnits','centimeters','PaperPosition',PaperPos);
        print(saveStr, '-dpng', '-r300')
    end   
end