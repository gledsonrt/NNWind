function [In, Out, Val] = getTVData(inputs, outputs, props)
    % Splits the IO pairs into training and validation data
    trainPerc = props.net.trainPerc;
    totalL = length(inputs);
    idx = 1:totalL;
    In = inputs(idx(1:round(trainPerc*totalL)));
    InV = inputs(idx(round(trainPerc*totalL)+1:end));   
    Out = outputs(idx(1:round(trainPerc*totalL)));
    OutV = outputs(idx(round(trainPerc*totalL)+1:end));  
    Val = {InV, OutV};
end