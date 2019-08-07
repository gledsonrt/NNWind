function printPartialFlutterDerivatives(net, props, path)
    % Calculates the aerodynamic derivatives of a trained model

    set(groot,'defaultAxesTickLabelInterpreter','latex'); 
    set(groot,'defaulttextinterpreter','latex');
    set(groot,'defaultLegendInterpreter','latex');
    
    % Where to save the results
    savePath = [path '/Figures'];
    if ~exist(savePath,'dir'); mkdir(savePath); end
    newProps = props;
        
    % Predictions might change quality with amplitude, so let the user choose
    dispHeader()
    newAmp = input(strcat('Select an amplitude [', num2str(props.wind.amplitudes(1)), ',...,', num2str(props.wind.amplitudes(end)), ']: #'));
    if isempty(newAmp); newProps.wind.amplitudes = mean(props.wind.amplitudes); else; newProps.wind.amplitudes = newAmp; end
    
    % Sample 15 values from the training Vr range to estimate the derivatives
    vrRange = linspace(props.wind.vrs(1), props.wind.vrs(end), 15);
    
    % We store the vr and 4 derivatives of the model
    derivs = zeros(length(vrRange), 5);
    derivsAnalytic = zeros(length(vrRange), 5);
    
    % Avoids some Matlab warnings
    warning('off','all')
    
    % Loop over the Vr range
    for i = 1:length(vrRange)
        newProps.wind.vrs = vrRange(i);
        
        % We don't need a validation set
        newProps.net.trainPerc = 1;
        
        % Gets the data for the Vr, normalize and prepare into NN format
        [data, newProps] = getSEIOPairs(newProps);         
        [newProps, dataNorm] = normalizeData(newProps, data, false);
        [In, ~] = prepareTrainingData(dataNorm, newProps, false);
        
        % Make the predictions and re-organize vector
        preds = predict(net, In); 
        predVecCL = zeros(1, length(preds));
        predVecCM = zeros(1, length(preds));
        for k = 1:length(preds)
            predVecCL(k) = preds{k}(1, length(preds{k}));
            predVecCM(k) = preds{k}(2, length(preds{k}));
        end
        
        % De-normalize the predictions
        predVecCL = (predVecCL.*sum(abs(props.wind.normCL)))-abs(props.wind.normCL(1));
        predVecCM = (predVecCM.*sum(abs(props.wind.normCM)))-abs(props.wind.normCM(1));
        
        % Account for the loss of values due to moving window
        idx = length(data.CL)-length(predVecCL)+1:length(data.CL);
        
        % Adjusting for VXflow results
        if strcmp(props.dataType, 'Numerical') 
            predVecCL = -predVecCL;
            predVecCM = -predVecCM;
        end
        
        data.CL = data.CL(idx);
        data.CM = data.CM(idx);
        
        if strcmp(props.wind.movType, 'H')
            % For heave direction, no oscillations/forces in pitch
            U = props.wind.U;
            B = props.struct.B;
            rho = 1.20;
            LH = -1/2*rho*U*U*B*predVecCL;
            MH = 1/2*rho*U*U*B*B*predVecCM;
            LP = zeros(size(LH));
            MP = zeros(size(MH));
            DH = data.D(idx);
            VH = data.V(idx);
            DP = zeros(size(DH));
            VP = zeros(size(VH));
            vr = newProps.wind.vrs;
            % Use least squares to estimate derivatives
            derivs(i,1) = vr;
            [derivs(i,2), ~, ~, derivs(i,3), derivs(i,4), ~, ~, derivs(i,5)] = LSFit(U, B, rho, vr, LH, MH, LP, MP, DH, VH, DP, VP);
            % And get the analytical flat plate counterpart
            derivsAnalytic(i,1) = vr;
            [derivsAnalytic(i,2), ~, ~, derivsAnalytic(i,3), derivsAnalytic(i,4), ~, ~, derivsAnalytic(i,5)] = FPDerivs(vr);
            % The label for the derivatives
            yLabels = {'$H_1^*$', '$H_4^*$', '$A_1^*$', '$A_4^*$'};
        else
            % For pitch direction, no oscillations/forces in heave
            U = props.wind.U;
            B = props.struct.B;
            rho = 1.20;
            LP = -1/2*rho*U*U*B*predVecCL;
            MP = 1/2*rho*U*U*B*B*predVecCM;
            LH = zeros(size(LP));
            MH = zeros(size(MP));
            DP = data.D(idx);
            VP = data.V(idx);
            DH = zeros(size(DP));
            VH = zeros(size(VP));
            vr = newProps.wind.vrs;
            % Use least squares to estimate derivatives
            derivs(i,1) = vr;
            [~, derivs(i,2), derivs(i,3), ~, ~, derivs(i,4), derivs(i,5), ~] = LSFit(U, B, rho, vr, LH, MH, LP, MP, DH, VH, DP, VP);
            % And get the analytical flat plate counterpart
            derivsAnalytic(i,1) = vr;
            [~, derivsAnalytic(i,2), derivsAnalytic(i,3), ~, ~, derivsAnalytic(i,4), derivsAnalytic(i,5), ~] = FPDerivs(vr);
            % The label for the derivatives
            yLabels = {'$H_2^*$', '$H_3^*$', '$A_2^*$', '$A_3^*$'};
        end
    end
    
    % Now plot the results
    figure(); hold on;
    for i = 1:4
        subplot(2,2,i); hold on; grid on; box on; ax = gca; ax.GridLineStyle = ':'; ax.GridAlpha = 1;
        vrs = derivs(:,1);
        theo = derivsAnalytic(:,i+1);
        pred = derivs(:,i+1);
        plot(vrs, theo, '-k');
        plot(vrs, pred, '--r');
        ylabel([yLabels{i} ' [-]'], 'interpreter', 'latex', 'fontsize', 10);        
        ytickformat('%1.1f'); 
        xlim([min(vrs) max(vrs)])
        if i < 3
            set(gca,'xticklabel',{[]});
        else
            xlabel('$v_r$ [-]', 'interpreter', 'latex', 'fontsize', 10)
            xtickformat('%1.0f');
        end
    end
    
    % Save the results
    saveStr = sprintf('%s\\Derivatives', savePath);
    PaperPos = get(gcf,'PaperPosition'); PaperPos(3) = 16; PaperPos(4) = 8;
    set(gcf,'PaperUnits','centimeters','PaperPosition',PaperPos);
    print(saveStr, '-dpng', '-r300')
    
    % Let Matlab display warnings again...
    warning('on','all')

end