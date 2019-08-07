function printTrainingInfo(props, netInfo, path)
    % Prints some information about the training procedure
    
    % Where to save the results?
    savePath = [path '/Figures'];
    if ~exist(savePath,'dir'); mkdir(savePath); end

    % Get the validation loss, learning rates, epochs...
    valLoss = netInfo.ValidationLoss(~isnan(netInfo.ValidationLoss)); 
    LR = netInfo.BaseLearnRate(~isnan(netInfo.ValidationLoss)); 
    trainLoss = netInfo.TrainingLoss; 
    epochs = 1:length(valLoss);
    
    % Print the results
    dispHeader()
    disp(['Training epochs: ' num2str(epochs(end-1)) '' num2str(props.net.epochs)])
    disp(['Minimum validation loss: ' num2str(min(valLoss))])
    disp(['Final learning rate: ' num2str(LR(end))])
    
    % Plots the training and validation losses
    figure(); hold on; grid on; box on; ax = gca; ax.GridLineStyle = ':'; ax.GridAlpha = 1; 
    p1 = plot(linspace(0, epochs(end-1), length(trainLoss)), trainLoss, '-k', 'Color', [0 0 0 0.2]);
    p2 = plot(epochs-1, valLoss, '-r');
    legend([p1, p2], {'Training', 'Validation'});
    set(gca, 'YScale', 'log')
    xlabel('Epochs [-]')
    ylabel('Loss [-]')
    saveStr = sprintf('%s\\TrainingLosses', savePath);
    PaperPos = get(gcf,'PaperPosition'); PaperPos(3) = 12; PaperPos(4) = 6;
    set(gcf,'PaperUnits','centimeters','PaperPosition',PaperPos);
    print(saveStr, '-dpng', '-r300')
    
    % We can also plot the learning rate throughout the analysis
    figure(); hold on; grid on; box on; ax = gca; ax.GridLineStyle = ':'; ax.GridAlpha = 1; 
    p2 = plot(epochs-1, LR, '-k');
    legend([p1, p2], {'Training', 'Validation'});
    xlabel('Epochs [-]')
    ylabel('Learning Rate [-]')
    saveStr = sprintf('%s\\LearningRate', savePath);
    PaperPos = get(gcf,'PaperPosition'); PaperPos(3) = 12; PaperPos(4) = 6;
    set(gcf,'PaperUnits','centimeters','PaperPosition',PaperPos);
    print(saveStr, '-dpng', '-r300')
    
    % Done, we can return
    disp(' ')
    dummy = input('<press any key to return>');

end