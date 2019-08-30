function printPredictionSample(net, props, path)
    % Checks the predictions of a case of Vr and amplitude

    set(groot,'defaultAxesTickLabelInterpreter','latex'); 
    set(groot,'defaulttextinterpreter','latex');
    set(groot,'defaultLegendInterpreter','latex');
    
    % Initialize the path to save results
    savePath = [path '/Figures'];
    if ~exist(savePath,'dir'); mkdir(savePath); end
    newProps = props;
    
    % Now let's choose which Vr and amplitude to get
    % Let's also show the training range, make sure the user knows if he's out
    dispHeader()
    newVr = input(strcat('Select a reduced velocity [', num2str(props.wind.vrs(1)), ',...,', num2str(props.wind.vrs(end)), ']: #'));
    if isempty(newVr); newProps.wind.vrs = mean(props.wind.vrs); else; newProps.wind.vrs = newVr; end
    
    newAmp = input(strcat('Select an amplitude [', num2str(props.wind.amplitudes(1)), ',...,', num2str(props.wind.amplitudes(end)), ']: #'));
    if isempty(newAmp); newProps.wind.amplitudes = mean(props.wind.amplitudes); else; newProps.wind.amplitudes = newAmp; end
    

    % No need for validation dataset...
    newProps.net.trainPerc = 1;
    
    % Which type of data are we actually using here?
    % If it's a bluff body, we use the FP for comparison
    if strcmp(props.modelType, 'SelfExcited')
        [data, newProps] = getSEIOPairs(newProps);
    else
        newProps.wind.Nsteps = 500;
        newProps.wind.deltaT = (props.struct.B*newProps.wind.vrs)/(props.wind.U*newProps.wind.Nsteps);
        [data, newProps] = getBIOPairs(newProps);
    end            
    
    % Now normalize data and arrange into training format
    [newProps, dataNorm] = normalizeData(newProps, data, false);
    [In, ~] = prepareTrainingData(dataNorm, props, false);
    
    % Make the predictions and organize the results
    preds = predict(net, In); 
    predVecCL = zeros(1, length(preds));
    predVecCM = zeros(1, length(preds));
    for k = 1:length(preds)
        predVecCL(k) = preds{k}(1, length(preds{k}));
        predVecCM(k) = preds{k}(2, length(preds{k}));
    end
    
    % Now de-normalize everything
    predVecCL = ((predVecCL.*sum(abs(props.wind.normCL)))-abs(props.wind.normCL(1)));
    predVecCM = ((predVecCM.*sum(abs(props.wind.normCM)))-abs(props.wind.normCM(1)));
    
    % Account for lost values due to moving window
    idx = length(data.CL)-length(predVecCL)+1:length(data.CL);
    
    % Adjusting for VXflow results
    if strcmp(props.dataType, 'Numerical') 
        predVecCL = -predVecCL;
        predVecCM = -predVecCM;
    end
    
    % Calculates the R2 coefficient for each case and display them to user
    R2VecCL = 1 - sum((data.CL(idx)-predVecCL').^2)/sum((data.CL(idx) - mean(data.CL(idx))).^2);
    R2VecCM = 1 - sum((data.CM(idx)-predVecCM').^2)/sum((data.CM(idx) - mean(data.CM(idx))).^2);
    dispHeader()
    if newProps.wind.vrs > props.wind.vrs(end) || newProps.wind.vrs < props.wind.vrs(1); warning('Vr is not within training range. Results might be inaccurate.'); end
    if newProps.wind.amplitudes > props.wind.amplitudes(end) || newProps.wind.amplitudes < props.wind.amplitudes(1); warning('Amplitude is not within training range. Results might be inaccurate.'); end
    disp('R2 Coefficients')
    disp(['    CL: ' num2str(R2VecCL)])
    disp(['    CM: ' num2str(R2VecCM)])
    disp(' ')
    
    % Now let's plot the results
    figure()
    subplot(1,2,1); hold on; grid on; box on; ax = gca; ax.GridLineStyle = ':'; ax.GridAlpha = 1;
    p1 = plot(linspace(0,1,length(idx)), data.CL(idx), '-k');
    p2 = plot(linspace(0,1,length(predVecCL)), predVecCL, '--r');
    legend([p1, p2], {'Analytical', 'Prediction'}, 'Location', 'northoutside');
    xlabel('$tU/B$ [-]'); ylabel('$C_L$ [-]')
    ytickformat('%1.2f'); xtickformat('%1.1f');
    
    subplot(1,2,2); hold on; grid on; box on; ax = gca; ax.GridLineStyle = ':'; ax.GridAlpha = 1;
    p1 = plot(linspace(0,1,length(idx)), data.CM(idx), '-k');
    p2 = plot(linspace(0,1,length(predVecCM)), predVecCM, '--r');
    legend([p1, p2], {'Analytical', 'Prediction'}, 'Location', 'northoutside');
    xlabel('$tU/B$ [-]'); ylabel('$C_M$ [-]')
    ytickformat('%1.3f'); xtickformat('%1.1f');
    
    % And save them
    saveStr = sprintf('%s\\Pred_Vr%1.0f_Amp%1.0f', savePath, newProps.wind.vrs, newProps.wind.amplitudes);
    PaperPos = get(gcf,'PaperPosition'); PaperPos(3) = 16; PaperPos(4) = 6;
    set(gcf,'PaperUnits','centimeters','PaperPosition',PaperPos);
    print(saveStr, '-dpng', '-r300')
    
    % We can also save the numerical results, not only the plots
    savePath = [path '/Data'];
    if ~exist(savePath,'dir'); mkdir(savePath); end
    saveStr = sprintf('%s\\Data_Vr%1.0f_Amp%1.0f', savePath, newProps.wind.vrs, newProps.wind.amplitudes);
    saveData = struct;
    if isfield(data, 'D')
        saveData.D = data.D(idx);
    end
    saveData.V = data.V(idx);
    if isfield(data, 'A')
        saveData.A = data.A(idx);
    end
    saveData.CL = data.CL(idx);
    saveData.CM = data.CM(idx);
    saveData.predCL = predVecCL';
    saveData.predCM = predVecCM';
    save(saveStr, 'saveData')
    
    % Alright, continue...
    dummy = input('<press any key to return>'); 
    
end