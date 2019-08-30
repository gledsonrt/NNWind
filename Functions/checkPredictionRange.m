function checkPredictionRange(data, props)
    % Checks if the provided input data is within the range of the trained
    % network. If it's not, just issues a warning, but continues anyway.
    
    flags.Alerted = 0;
    
    % Checks for the displacement
    if isfield(data, 'D')
        if max(abs(data.D)) > props.wind.normD
            warning('Input displacement is out of training range. Results might be innacurate.'); 
            flags.Alerted = 1;
        end
    end
    if isfield(data, 'V')
        if max(abs(data.V)) > props.wind.normV
            warning('Input velocitiy is out of training range. Results might be innacurate.'); 
            flags.Alerted = 1;
        end
    end
    if isfield(data, 'A')
        if max(abs(data.A)) > props.wind.normA
            warning('Input acceleration is out of training range. Results might be innacurate.'); 
            flags.Alerted = 1;
        end
    end
    if flags.Alerted
        dummy = input('<press any key to continue>'); 
    end
end