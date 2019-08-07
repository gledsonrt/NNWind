function layers = getRecNeuralNetLayers(inDim, outDim, props)   
    % Create the layers for the analysis
    % We differentiate between SE and bufeting by the 
    % Bi-Directional LSTM layer
    if strcmp(props.modelType, 'Buffeting')
        layers = [sequenceInputLayer(inDim)
              bilstmLayer(props.net.hiddenLayerNeurons, 'OutputMode', 'sequence')
              dropoutLayer(0.1)
              fullyConnectedLayer(outDim)
              regressionLayer()];
    else
        layers = [sequenceInputLayer(inDim)
              lstmLayer(props.net.hiddenLayerNeurons, 'OutputMode', 'sequence')
              dropoutLayer(0.1)
              fullyConnectedLayer(outDim)
              regressionLayer()];
    end
    
end
