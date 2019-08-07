function printNetModelInfo(props)
    % Prints some information about the network model
    dispHeader()
    disp(['Network trained on: ' num2str(props.net.startTime(3)) '/' num2str(props.net.startTime(2)) '/' num2str(props.net.startTime(1)) ' - ' num2str(sprintf('%02d', props.net.startTime(4))) ':' num2str(sprintf('%02d', props.net.startTime(5)))]);
    disp(['Recurrent layer type: ' props.net.type])
    disp(['Number of neurons: ' num2str(props.net.hiddenLayerNeurons)])
    disp(['Learning rate: ' num2str(props.net.LR)])
    disp(['Decay rate: ' num2str(100*(1-props.net.LRDrop)) '%/epoch'])
    disp(['Data division: training (' num2str(100*(props.net.trainPerc)) '%), validation (' num2str(100*(1-props.net.trainPerc)) '%)'])
    disp(['Maximum epochs & training patience: ' num2str(props.net.epochs) ', ' num2str(props.net.validPatience)])    
    disp(' ')
    dummy = input('<press any key to return>');
end