function props = setRecNNProperties(props, totalSamples)
    % Setting up the properties for the recurrent network
    
    % Initializes defaults for SE and Buffeting
    if not(isfield(props.net, 'type'))
        if strcmp(props.modelType, 'Buffeting')
            props.net.type = 'Bi-Directional LSTM';
            props.net.LR = 1e-4;
            props.net.LRDrop = 0.975;
            props.net.epochs = 500;
            props.net.hiddenLayerNeurons = 100;
        else
            props.net.type = 'LSTM';
            props.net.LR = 7.5e-4;
            props.net.LRDrop = 0.985;
            props.net.hiddenLayerNeurons = 50;
            props.net.epochs = 100;
        end
        props.net.verbose = 1;
        props.net.verbFreq = 1;
        props.net.rngNum = 1;
        props.net.trainPerc = 0.9;
        props.net.batchSize = ceil((props.net.trainPerc*totalSamples)^(1/3));
        props.net.validPatience = 10;
        props.net.validFreq = floor(props.net.trainPerc*totalSamples/props.net.batchSize);
        props.net.hiddenLayerNumber = 1;
    end
    flags.exitFCNNMenu = 0;
    
    while not(flags.exitFCNNMenu)
        dispHeader()
        disp('Choose one of the following options:');
        disp(strcat('   #1 Verbose [', num2str(props.net.verbose), ']'));
        disp(strcat('   #2 Seed for random number [', num2str(props.net.rngNum), ']'));
        disp(strcat('   #3 Learning rate [', num2str(props.net.LR), ']'));
        disp(strcat('   #4 Learning rate attenuation per epoch [', num2str(props.net.LRDrop), ']'));
        disp(strcat('   #5 Training percentage [', num2str(props.net.trainPerc), ']'));
        disp(strcat('   #6 Batch size [', num2str(props.net.batchSize), ']'));
        disp(strcat('   #7 Number of epochs [', num2str(props.net.epochs), ']'));
        disp(strcat('   #8 Validation patience [', num2str(props.net.validPatience), ']'));
        disp(strcat('   #9 Number of LSTM neurons [', num2str(props.net.hiddenLayerNeurons), ']'));
        disp(strcat('   #0 Setup network and return'));
        flags.exitFCNNMenu = input(strcat('Selection [', num2str(flags.exitFCNNMenu), ']: #'));
        if isempty(flags.exitFCNNMenu); flags.exitFCNNMenu = 0; end
        
        switch flags.exitFCNNMenu
            case 1
                dispHeader()
                disp('Choose verbose frequency:');
                disp('   #0 Disable');
                disp('   #1 Every Iteration');
                disp('   #2 Every Epoch');
                props.net.verbose = input(strcat('Selection [', num2str(1), ']: #'));
                if isempty(props.net.verbose); props.net.verbose = 1; end
                if props.net.verbose ~= 0 && props.net.verbose ~= 1 && props.net.verbose ~= 2 && props.net.verbose ~= 3; props.net.verbose = 1; end
                if props.net.verbose == 1; props.net.verbFreq = 1; end
                if props.net.verbose == 2; props.net.verbFreq = ceil(props.net.trainPerc*totalSamples); end
                flags.exitFCNNMenu = 0;
            case 2
                dispHeader()
                props.net.rngNum = input('New seed for random numbers: ');
                if isempty(props.net.rngNum); props.net.rngNum = 1; end
                flags.exitFCNNMenu = 0;
            case 3
                dispHeader()
                tmp = props.net.LR;
                props.net.LR = input('New learning rate: ');
                if isempty(props.net.LR); props.net.LR = tmp; end
                flags.exitFCNNMenu = 0;
            case 4
                dispHeader()
                tmp = props.net.LRDrop;
                props.net.LRDrop = input('New learning rate drop: ');
                if isempty(props.net.LRDrop); props.net.LRDrop = tmp; end
                flags.exitFCNNMenu = 0;
            case 5
                dispHeader()
                tmp = props.net.trainPerc;
                props.net.trainPerc = input('Percentage of training data (Remaining is used for validation): ');
                if isempty(props.net.trainPerc); props.net.trainPerc = tmp; end
                flags.exitFCNNMenu = 0;
            case 6
                dispHeader()
                props.net.batchSize = input('New batch size: ');
                if isempty(props.net.batchSize); props.net.batchSize = ceil((props.net.trainPerc*totalSamples)^(1/3)); end
                flags.exitFCNNMenu = 0;
            case 7
                dispHeader()
                tmp = props.net.epochs;
                props.net.epochs = input('Maximum number of epochs: ');
                if isempty(props.net.epochs); props.net.epochs = tmp; end
                flags.exitFCNNMenu = 0;
            case 8
                dispHeader()
                tmp = props.net.validPatience;
                props.net.validPatience = input('Validation patience criteria: ');
                if isempty(props.net.validPatience); props.net.validPatience = tmp; end
                flags.exitFCNNMenu = 0;
            case 9
                dispHeader()
                tmp = props.net.hiddenLayerNeurons;
                props.net.hiddenLayerNeurons = input('Number of LSTM neurons: ');
                if isempty(props.net.hiddenLayerNeurons); props.net.hiddenLayerNeurons = tmp; end
                flags.exitFCNNMenu = 0;
            case 0
                flags.exitFCNNMenu = 1;
            otherwise
                flags.exitFCNNMenu = 0;
        end
    end
    
end