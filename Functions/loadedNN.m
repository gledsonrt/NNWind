function loadedNN(net, props, netInfo, path, file)
    % The main menu for checking the performance of a trained model
    flags.Exit = 0;
    while not(flags.Exit)
        flags.mainMenu = 1;
        dispHeader()
        disp('Choose one of the following options:');
        disp('   #1 Print model information (wind)');
        disp('   #2 Print model information (network)');
        disp('   #3 Print training information');
        disp('   #4 Print training quality evaluation');
        disp('   #5 Print a prediction sample');
        if strcmp(props.modelType, 'SelfExcited')
            disp('   #6 Calculate aerodynamic derivatives');
        end
        disp('   #0 Back');
        flags.mainMenu = input(strcat('Selection [', num2str(flags.mainMenu), ']: #'));
        if isempty(flags.mainMenu); flags.mainMenu = 1; end
        switch flags.mainMenu
            case 1
                printWindModelInfo(props);
            case 2
                printNetModelInfo(props);
            case 3
                printTrainingInfo(props, netInfo, path);
            case 4
                printTrainingQualityEvaluation(net, props, path);
            case 5
                printPredictionSample(net, props, path);
            case 6
                if strcmp(props.modelType, 'SelfExcited')
                    printPartialFlutterDerivatives(net, props, path);
                end
            case 0
                flags.Exit = 1;
            otherwise
        end
    end
end