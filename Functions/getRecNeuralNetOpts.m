function [opts, props] = getRecNeuralNetOpts(props, valData)
    % Create the training options for the network
    
    % 0 disables verbose, any other value  should show the training progress plot
    if props.net.verbose > 0
        verbose = 1;
        train_plot = 'training-progress';
    else
        train_plot = 'none';
    end
    
    % The start of training, used also for individual path creation
    props.net.startTime = clock;
    if strcmp(props.modelType, 'Buffeting')
        props.net.savePath = strcat(pwd, '\Model_B__', num2str(props.net.startTime(1)), '_', num2str(props.net.startTime(2)), ... 
                                        '_', num2str(props.net.startTime(3)), '__', num2str(props.net.startTime(4)), ...
                                        '_', num2str(props.net.startTime(5)));
    else
        props.net.savePath = strcat(pwd, '\Model_SE_', props.wind.movType, ...
                                        '__', num2str(props.net.startTime(1)), '_', num2str(props.net.startTime(2)), ... 
                                        '_', num2str(props.net.startTime(3)), '__', num2str(props.net.startTime(4)), ...
                                        '_', num2str(props.net.startTime(5)));
    end

    % Creates the network path and saves the properties
    if ~exist(props.net.savePath,'dir'); mkdir(props.net.savePath); end
    save(strcat(props.net.savePath, '\props.mat'), 'props'); 
    
    % generates the training options
    
    opts = trainingOptions( 'adam', ...                                         % The SGD optimization algorithm
        'plots', train_plot, ...                                                % The follow-up progress plot
        'Verbose', verbose, 'VerboseFrequency', props.net.verbFreq, ...         % Specifies verbose and its frequency
        'MiniBatchSize', props.net.batchSize, ...                               % The batch size is calculated as (length(inputs))^(1/3)
        'InitialLearnRate', props.net.LR, ...                                   % Initial learning rate
        'MaxEpochs', props.net.epochs, ...                                      % The total number of training epochs
        'LearnRateSchedule', 'piecewise', ...                                   % How to decay the learning rate
        'LearnRateDropPeriod', 1, ...                                           % Decay at every epoch
        'LearnRateDropFactor', props.net.LRDrop, ...                            % The decay multiplier
        'Shuffle', 'every-epoch', ...                                           % The sliding window method allows for data shuffling
        'GradientThreshold', 2, ...                                             % To mitigate the chance of exploding gradients
        'ExecutionEnvironment', 'cpu', ...                                      % GPU requires CUDA, and a good graphics card
        'ValidationData', valData, ...                                          % The validation part of the data, as {Inputs, Outputs}
        'ValidationFrequency', props.net.validFreq, ...                         % When to use the validation set, usually once per epoch
        'ValidationPatience', props.net.validPatience, ...                      % To automatically stop training
        'CheckpointPath', props.net.savePath);                                  % To save the checkpoints during training    
end