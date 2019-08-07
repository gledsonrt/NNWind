function [inputs, outputs] = prepareTrainingData(data, props, shuffleData)
    % We need to change the data into a format that Matlab understands
   
    % First we allocate the empty cell arrays for inputs and outputs
    counter = 0; winLen = ceil(props.wind.Nsteps*props.net.winLen);
    for i = 1:length(data)
        for j = 1:length(data(i).V)-winLen-1
            counter = counter+1;
        end
    end
    inputs = cell(counter, 1);
    outputs = cell(counter, 1);
    totalSteps = counter;
    counter = 1;
    
    % If we're preparing for training, then data should be shuffled
    % Here we use that information to create a progress bar
    % If we're making predictions, this process is a lot faster and we
    % don't really need the progress bar...
    if shuffleData
        dispHeader()
        disp('Preparing data for training...')   
        h = waitbar(0,'iteration'); % Progress bar
        set(findall(h,'type','text'),'Interpreter','none');
    end
    
    % Now for the arranging of the data
    % We first loop over the IO pairs
    for i = 1:length(data)
        % And the inner loop controls the moving window
        for j = 1:length(data(i).V)-winLen-1
            % We start a vector that stores the inputs
            % This is necessary because we don't know if we're talking
            % about SE forces (D and V needed) or buffeting (V and A).
            % Also, if the data is numerical more problems can arise, so
            % better make sure...
            tempImp = [];
            if isfield(data, 'D'); tempImp = [tempImp data(i).D(j:j+winLen-1)]; end
            if isfield(data, 'V'); tempImp = [tempImp data(i).V(j:j+winLen-1)]; end
            if isfield(data, 'A'); tempImp = [tempImp data(i).A(j:j+winLen-1)]; end
            inputs{counter} = tempImp';
            
            % If we're predicting random displacements, we might not have CL and CM
            % Skip them in case they don't exist
            if isfield(data, 'CL') && isfield(data, 'CM')
                outputs{counter} = [data(i).CL(j+1:j+winLen) data(i).CM(j+1:j+winLen)]';
            end
            
            % Update the progress bar from time to time...
            if mod(counter, round(totalSteps/100))==0 && shuffleData
                waitbar(counter/totalSteps,h,sprintf('Preparing data for training: %2.1f%% done',counter/totalSteps*100));
            end
            counter = counter + 1;
        end
    end   
    
    % Closing progress bar
    if shuffleData; close(h); end
        
    % Shuffle the data pairs
    if shuffleData
        idx = randperm(length(inputs));
        inputs = inputs(idx);
        outputs = outputs(idx);
    end
end