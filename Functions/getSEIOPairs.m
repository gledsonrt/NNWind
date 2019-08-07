function [data, props] = getSEIOPairs(props)
    % Calculates the self-excited response for every Vr-amplitude pair

    % Check the direction of motion
    if contains(props.wind.movType, 'H'); direction = 0;
    elseif contains(props.wind.movType, 'P'); direction = 1;
    end
    
    dispHeader()
    disp('Generating analytical IO pairs...')
    
    % Start variable that will store the results
    data = struct;
    counter = 1;
    
    % Looping over Vr-amplitude pairs
    for j = 1:length(props.wind.amplitudes)
        amplitude = props.wind.amplitudes(j);
        for i = 1:length(props.wind.vrs)
            vr = props.wind.vrs(i);
            
            % If we only have one Vr and one amplitude, means we're
            % predicting something, and the Nsteps is just loaded
            if length(props.wind.vrs)==1 && length(props.wind.amplitudes)==1
                Nstep = props.wind.Nsteps;
                if strcmp(props.dataType, 'Numerical')
                    Nstep = floor(Nstep/props.net.numCycle);
                end
            else
                % If we're not predicting, then the Nstep is a function of
                % the smallest reduced velocity, unless a higher value was
                % set by the user before...
                if j == 1 && i == 1
                    f0 = props.wind.U/(props.struct.B*vr);    T0=1/f0; 
                    Nstep = max([props.wind.Nsteps ceil((T0/props.wind.deltaT))]);
                    props.wind.Nsteps = Nstep;
                else
                    % If we already calculated the Nstep, then just use it
                    Nstep = props.wind.Nsteps;
                end
            end
            % The Delta T is adjusted according to the Vr and the Nstep
            dt = (props.struct.B*vr)/(props.wind.U*Nstep);
            % We adjust the value to account for the sliding window method
            Nstep = ceil(Nstep*(1+props.net.winLen+0.05));
            % Get and store the results
            [~, ~, CL, CM, D, V, ~, ~] = getSEFlatPlateData(props.wind.U, props.struct.B, vr, amplitude, dt, Nstep, direction);
            data(counter).vr = vr;
            data(counter).amplitude = amplitude;
            data(counter).D = D;
            data(counter).V = V;
            data(counter).CL = CL;
            data(counter).CM = CM;
            counter = counter+1;
        end
    end
    
    % Set the data type for analytic
    props.dataType = 'Analytical';
end
