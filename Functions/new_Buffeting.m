function new_Buffeting()
    % Creates a model for the buffeting forces
    flags.Exit = 0;
    props = struct;
    props.modelType = 'Buffeting';
    flags.readyToTrain = 0;
    
    % Starts the menu
    while not(flags.Exit)
        flags.mainMenu = 1;
        dispHeader()
        disp('Choose one of the following options:');
        disp('   #1 Set up dataset');
        if exist('dataNorm', 'var')
            % Only set net properties if data is generated
            flags.mainMenu = 2;
            disp('   #2 Set up network properties'); 
        end
        if flags.readyToTrain
            % Only show training option if everything is ok
            flags.mainMenu = 3;
            disp('   #3 Start training');
        end
        disp('   #0 Back');
        choice = flags.mainMenu;
        flags.mainMenu = input(strcat('Selection [', num2str(flags.mainMenu), ']: #'));
        if isempty(flags.mainMenu); flags.mainMenu = choice; end
        switch flags.mainMenu
            case 1
                flags.datasetChoice = 1;
                dispHeader()
                disp('Choose one of the following options:');
                disp('   #1 Use analytical data (Sears Admittance)');
                disp('   #2 Load training data');   
                disp('   #0 Back');
                flags.datasetChoice = input(strcat('Selection [', num2str(flags.datasetChoice), ']: #'));
                if isempty(flags.datasetChoice); flags.datasetChoice = 1; end
                switch flags.datasetChoice
                    case 1
                        % We generate the training data anlytically
                        % Also normalize and prepare for training
                        props = setBWindProps(props);
                        [data, props] = getBIOPairs(props);
                        [props, dataNorm] = normalizeData(props, data, true);
                        [In, Out] = prepareTrainingData(dataNorm, props, true);
                    case 2
                        % We load the training data from file
                        % Also normalize and prepare for training
                        dispHeader()
                        [data, props] = checkLoadedData(props);
                        [props, dataNorm] = normalizeData(props, data, true);
                        [In, Out] = prepareTrainingData(dataNorm, props, true);
                    otherwise
                end
            case 2
                % If there's data, then set net properties
                if exist('dataNorm', 'var')
                    dispHeader()
                    props = setRecNNProperties(props, length(In));
                    netLayers = getRecNeuralNetLayers(size(In{1}, 1), size(Out{1}, 1), props);
                    [InT, OutT, ValT] = getTVData(In, Out, props);
                    flags.readyToTrain = 1;
                end
            case 3
                if flags.readyToTrain
                    % Now to training part
                    [netOpts, props] = getRecNeuralNetOpts(props, ValT);
                    warning off backtrace
                    [net, info] = trainNetwork(InT, OutT, netLayers, netOpts); 
                    warning on backtrace
                    % And after training, save the model
                    save(strcat(props.net.savePath, '\finalModel.mat'), 'props', 'net', 'info', 'netOpts');
                    % Should we keep training checkpoints?
                    dispHeader();
                    disp('Training finished.'); disp('');
                    disp(['Model saved as ' props.net.savePath '\finalModel.mat']); disp('');
                    keepChecks = input(strcat('Keep model checkpoints (Y/N) [N]: '), 's');
                    if isempty(keepChecks) || (not(strcmpi(keepChecks, 'n')) && not(strcmpi(keepChecks, 'y'))); keepChecks = 'n'; end
                    if strcmpi(keepChecks, 'n')
                        files = dir([props.net.savePath '/*.mat']); files = {files.name};
                        pos = find(strcmp(files,'finalModel.mat'));
                        for i = 1:numel(files)
                            if i ~= pos
                                delete([props.net.savePath '\' files{i}])
                            end
                        end
                    end
                    % Also save the training data, just in case
                    dataDir = [props.net.savePath '\Data'];
                    if ~exist(dataDir,'dir'); mkdir(dataDir); end
                    save(strcat(dataDir, '\trainingData.mat'), 'data'); 
                    flags.Exit = 1;
                end
            case 0
                flags.Exit = 1;
            otherwise
        end
    end    
end