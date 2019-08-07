function printWindModelInfo(props)
    % Prints model information about wind-related things
    dispHeader()
    if contains(props.modelType, 'SelfExcited')
        if contains(props.wind.movType, 'H')
            disp('Target forces: self-excited. Oscillation DOF: heave.');
        else
            disp('Target forces: self-excited. Oscillation DOF: pitch.');
        end
    else
        disp('Target forces: buffeting.');
    end
    disp(['Reduced velocities (' num2str(length(props.wind.vrs)) ' values): [' num2str(props.wind.vrs(1)) ',...,' num2str(props.wind.vrs(end)), ']']);
    disp(['Amplitudes (' num2str(length(props.wind.amplitudes)) ' values): [' num2str(props.wind.amplitudes(1)) '°,...,' num2str(props.wind.amplitudes(end)), '°]']);
    disp(['Sampling frequency: ' num2str(props.wind.samplingFreq) 'Hz'])
    disp(['Fixed number of time-steps: ' num2str(props.wind.Nsteps)])     
    disp(' ')
    dummy = input('<press any key to return>');
end