function printBRandomDisp()
% Response due to a random gust profile
%
%   After loading the neural networks, select the gust data.
%   The data should be organized in a Matlab structure with the following fields:
%       V   -  The gust velocity in vertical direction.
%       A   -  The first time derivative.
%
%   In case the time derivative is abscent, the sampling frequency will be asked
%   in order to numerically calculate the signal.
%
    dispHeader()
    help printBRandomDisp;
    dummy = input('<press any key to continue>');

    set(groot,'defaultAxesTickLabelInterpreter','latex'); 
    set(groot,'defaulttextinterpreter','latex');
    set(groot,'defaultLegendInterpreter','latex');
    
    % Load the network model and check if its ok
    dispHeader()
    disp('Select the network model for the buffeting forces...')
    [file, path] = uigetfile('*.mat', 'Select the network model for the buffeting forces.');
    if file ~= 0; netB = load([path file]); else; return; end
    if ~(strcmp(netB.props.modelType, 'Buffeting')); error('Invalid model file.'); end
    
    % Load the data for the random displacement
    dispHeader()
    disp('Select the random gust data file...')
    [fileRND, pathRND] = uigetfile('*.mat', 'Select the random gust data file.');
    if fileRND ~= 0
        rndDisp = load([pathRND fileRND]);
        fnames = fieldnames(rndDisp); 
        if length(fnames) == 1; rndDisp = rndDisp.(fnames{1}); end
        fnames = fieldnames(rndDisp);
        if any(strcmp(fnames,'V'))
            % Get the time derivative, if it doesn't exist
            if ~any(strcmp(fnames,'A'))
                dispHeader()
                Fs = input(strcat('Input the sampling frequency for the data acquisition [Hz]: #'));
                Dt = 1/Fs; rndDisp.A = gradient(rndDisp.V)./Dt;
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
    
    % Is the data within the training range?
    checkPredictionRange(rndDisp, netB.props)
    
    % We don't need any validation data for the prediction
    netB.props.net.trainPerc = 1;
    
    % Normalize the data in the same range used for training
    [~, dataNorm] = normalizeData(netB.props, rndDisp, false);
    
    % And organize the data for testing
    [In, ~] = prepareTrainingData(dataNorm, netB.props, false);
    
    % Get predictions for the coefficients
    dispHeader()
    disp('Making predictions...')
    preds = predict(netB.net, In); 
    
    % Now organize the prediction results
    predVecCL = zeros(1, length(preds));
    predVecCM = zeros(1, length(preds));
    for k = 1:length(preds)
        predVecCL(k) = preds{k}(1, length(preds{k}));
        predVecCM(k) = preds{k}(2, length(preds{k}));
    end
    
    % Now de-normalize the predictions
    predVecCL = (predVecCL.*sum(abs(netB.props.wind.normCL)))-abs(netB.props.wind.normCL(1));
    predVecCM = (predVecCM.*sum(abs(netB.props.wind.normCM)))-abs(netB.props.wind.normCM(1));
    
    % Center predictions
    predVecCL = predVecCL - predVecCL(1);
    predVecCM = predVecCM - predVecCM(1);
    
    % Let's check if we have information about time
    if exist('Fs', 'var')
        timeVec = linspace(0, length(predVecCL)/Fs, length(predVecCL));
    else
        dispHeader()
        disp('Input the sampling frequency, or leave blank to plot as time-steps.')
        Fs = input(strcat('Sampling frequency [Hz]: #'));
        if ~isempty(Fs) 
            timeVec = linspace(0, length(predVecCL)/Fs, length(predVecCL));
        else
            timeVec = 1:length(predVecCL);
        end
    end
    
    % Should we save the results?
    dispHeader()
    disp('Select a folder to save the results, or cancel to avoid saving...')
    savePath = uigetdir(pwd, 'Select a folder to save the results.');
    if savePath ~= 0
        results = struct;
        results.CL = predVecCL;
        results.CM = predVecCM;
        saveStr = sprintf('%s\\rndDisplacementResults', savePath);
        save([saveStr '.mat'], 'results')
    end
    
    % Now plot the resulting CM and CL, in heave
    figure();
    subplot(2,1,1); hold on; grid on; box on; ax = gca; ax.GridLineStyle = ':'; ax.GridAlpha = 1;
    plot(timeVec, predVecCL, '-k')
    if ~isempty(Fs) 
        xlabel('$t$ [s]', 'Interpreter', 'latex')
    else
        xlabel('Time-Step [-]', 'Interpreter', 'latex')
    end
    ylabel('$C_{L}$ [-]', 'Interpreter', 'latex')
    ytickformat('%1.2f');
    subplot(2,1,2); hold on; grid on; box on; ax = gca; ax.GridLineStyle = ':'; ax.GridAlpha = 1;
    plot(timeVec, predVecCM, '-k')
    if ~isempty(Fs) 
        xlabel('$t$ [s]', 'Interpreter', 'latex')
    else
        xlabel('Time-Step [-]', 'Interpreter', 'latex')
    end
    ylabel('$C_{M}$ [-]', 'Interpreter', 'latex')
    ytickformat('%1.3f');
    if savePath ~= 0
        saveStr = sprintf('%s\\rndDisplacementResults', savePath);
        PaperPos = get(gcf,'PaperPosition'); PaperPos(3) = 16; PaperPos(4) = 10;
        set(gcf,'PaperUnits','centimeters','PaperPosition',PaperPos);
        print(saveStr, '-dpng', '-r300')
    end
    
    % If we have information about frequency, we can plot the PSD
    if ~isempty(Fs)
        % Get the length of the vector, make sure it's even
        N = length(predVecCL);
        if rem(N,2)~=0; N=N+1; end
        
        % The frequency vector...
        freqVec = linspace(0, Fs, N);
        
        % And we cut to show the first 10Hz only
        fCut = ceil(N*10/Fs);
        
        % Calculate the PSD of the lift forces
        PSD = fft(predVecCL);
        PSD = PSD(1:N/2+1);
        PSD = (1/(Fs^2*N)) * abs(PSD).^2;
        PSD(2:end-1) = 2*PSD(2:end-1);
        
        % Plot them
        figure();
        subplot(2,1,1); hold on; grid on; box on; ax = gca; ax.GridLineStyle = ':'; ax.GridAlpha = 1;
        plot(freqVec(2:fCut), 10*log10(PSD(2:fCut)), '-k', 'LineWidth', 0.6);
        xlabel('$f$ [Hz]', 'interpreter', 'latex')
        ylabel('$PSD_{CL}$ [dB/Hz]', 'interpreter', 'latex')
        
        % Repeat for the moment forces
        PSD = fft(predVecCM);
        PSD = PSD(1:N/2+1);
        PSD = (1/(Fs^2*N)) * abs(PSD).^2;
        PSD(2:end-1) = 2*PSD(2:end-1);
        subplot(2,1,2); hold on; grid on; box on; ax = gca; ax.GridLineStyle = ':'; ax.GridAlpha = 1;
        plot(freqVec(2:fCut), 10*log10(PSD(2:fCut)), '-k', 'LineWidth', 0.6);
        xlabel('$f$ [Hz]', 'interpreter', 'latex')
        ylabel('$PSD_{CM}$ [dB/Hz]', 'interpreter', 'latex')
        
        if savePath ~= 0
            saveStr = sprintf('%s\\rndDisplacementResults_PSD', savePath);
            PaperPos = get(gcf,'PaperPosition'); PaperPos(3) = 16; PaperPos(4) = 10;
            set(gcf,'PaperUnits','centimeters','PaperPosition',PaperPos);
            print(saveStr, '-dpng', '-r300')
        end
        
    end
    
end