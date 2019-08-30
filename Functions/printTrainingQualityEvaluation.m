function printTrainingQualityEvaluation(net, props, path)
    % Plots a quality evaluation of the trained model
    % Compares trained model to analytical FP results
    
    % Check if there's more than 1 value for Vrs and amplitudes
    if length(props.wind.vrs) > 1 && length(props.wind.amplitudes) > 1

        % Where to save results?
        savePath = [path '/Figures'];
        if ~exist(savePath,'dir'); mkdir(savePath); end

        % The evaluation is done only for values within training range...
        vrRange = linspace(props.wind.vrs(1), props.wind.vrs(end), 20);
        ampRange = linspace(props.wind.amplitudes(1), props.wind.amplitudes(end), 10);


        % Let's initialize the result storage
        R2VecCL = zeros(length(vrRange), length(ampRange));
        R2VecCM = zeros(length(vrRange), length(ampRange));

        dispHeader()
        disp(['Evaluating sample cases whithin training range...'])

        % Start the progress bar, it's rather slow...
        totSamples = length(vrRange)*length(ampRange); c = 0;    
        h = waitbar(0,'iteration'); % Progress bar
        set(findall(h,'type','text'),'Interpreter','none');

        % Loop over the Vr and amplitudes
        for i = 1:length(vrRange)
            vr = vrRange(i);
            for j = 1:length(ampRange)
                amp = ampRange(j);
                tempProps = props;
                tempProps.wind.vrs = vr;
                tempProps.wind.amplitudes = amp;

                % No validation set required...
                tempProps.net.trainPerc = 1;

                % Get analytical data, for comparison
                % This function, of course, makes not much sense for bluff bodies
                if strcmp(props.modelType, 'SelfExcited')
                    [data, tempProps] = getSEIOPairs(tempProps);
                else
                    [data, tempProps] = getBIOPairs(tempProps);
                end            

                % Normalize data and put into NN format
                [~, dataNorm] = normalizeData(tempProps, data, false);
                [In, ~] = prepareTrainingData(dataNorm, props, false);

                % Make the predictions and re-organize
                preds = predict(net, In); 
                predVecCL = zeros(1, length(preds));
                predVecCM = zeros(1, length(preds));
                for k = 1:length(preds)
                    predVecCL(k) = preds{k}(1, length(preds{k}));
                    predVecCM(k) = preds{k}(2, length(preds{k}));
                end

                % De-normalizing the predictions...
                predVecCL = (predVecCL.*sum(abs(props.wind.normCL)))-abs(props.wind.normCL(1));
                predVecCM = (predVecCM.*sum(abs(props.wind.normCM)))-abs(props.wind.normCM(1));

                % Adjusting for VXflow results
                if strcmp(props.dataType, 'Numerical') 
                    predVecCL = -predVecCL;
                    predVecCM = -predVecCM;
                end

                % Accounting for moving-window procedure
                idx = length(data.CL)-length(predVecCL)+1:length(data.CL);

                % Calculate and store the results of the R2
                R2VecCL(i,j) = max([1 - sum((data.CL(idx)-predVecCL').^2)/sum((data.CL(idx) - mean(data.CL(idx))).^2) 0]);
                R2VecCM(i,j) = max([1 - sum((data.CM(idx)-predVecCM').^2)/sum((data.CM(idx) - mean(data.CM(idx))).^2) 0]);

                % And update the progress bar
                waitbar(c/totSamples, h, sprintf('Evaluating cases: %2.1f%% done',c/totSamples*100));
                c = c + 1;
            end
        end

        % Closes the progress bar
        close(h)

        % Plots and saves results for CL
        figure()
        surf(vrRange, ampRange, R2VecCL', 'EdgeAlpha', 0);
        xlabel('$v_r$ [-]'); ylabel('$\hat{\alpha}$ [$^{\circ}$]')
        colormap('gray');
        h = colorbar; set(get(h,'label'),'string','$R^2$ [-]', 'Interpreter', 'latex'); 
        view(2);
        saveStr = sprintf('%s\\R2ComparisonCL', savePath);
        PaperPos = get(gcf,'PaperPosition'); PaperPos(3) = 12; PaperPos(4) = 5;
        set(gcf,'PaperUnits','centimeters','PaperPosition',PaperPos);
        print(saveStr, '-dpng', '-r300')
        title('$C_L$ Comparison');

        % Plots and saves results for CM
        figure()
        surf(vrRange, ampRange, R2VecCM', 'EdgeAlpha', 0);
        xlabel('$v_r$ [-]'); ylabel('$\hat{\alpha}$ [$^{\circ}$]');
        colormap('gray');
        h = colorbar; set(get(h,'label'),'string','$R^2$ [-]', 'Interpreter', 'latex'); 
        view(2);    
        saveStr = sprintf('%s\\R2ComparisonCM', savePath);
        PaperPos = get(gcf,'PaperPosition'); PaperPos(3) = 12; PaperPos(4) = 5;
        set(gcf,'PaperUnits','centimeters','PaperPosition',PaperPos);
        print(saveStr, '-dpng', '-r300')
        title('$C_M$ Comparison');
        
        dispHeader()
    else
        dispHeader()
        warning('Insufficient range of reduced velocities or amplitudes.')
    end
     
    % All done, continue
    dummy = input('<press any key to return>');   

end