function [data, props] = getBIOPairs(props)
    % Calculates the inputs and outputs for all Vr and amplitude cases
    dispHeader()
    disp('Generating analytical IO pairs...')
    
    data = struct;
    counter = 1;
    
    % Loop over cases
    for j = 1:length(props.wind.amplitudes)
        amplitude = props.wind.amplitudes(j);
        for i = 1:length(props.wind.vrs)
            vr = props.wind.vrs(i);
            % Delta T is calculated according to selected number of time-steps
            dt = (props.struct.B*vr)/(props.wind.U*props.wind.Nsteps);
            % We add a few time-steps to account for the network's sliding window procedure
            Nstep = ceil(props.wind.Nsteps*(1+props.net.winLen+0.05));
            [~, ~, CL, CM, V, A, ~] = getBFlatPlateData(props.wind.U, props.struct.B, vr, amplitude, dt, Nstep);
            data(counter).vr = vr;
            data(counter).amplitude = amplitude;
            data(counter).V = V;
            data(counter).A = A;
            data(counter).CL = CL;
            data(counter).CM = CM;
            counter = counter+1;
        end
    end
    
    % Set the dataType as analytically generated
    props.dataType = 'Analytical';
end
