function [props, dataNorm] = normalizeData(props, data, genNorm)
    % Normalizes the data in a range of [0,1] to stabilize training
    
    dispHeader()
    disp('Normalizing IO pairs...')

    % Should we generate the minimum and maximum points as well?
    % This is set to false during predictions...
    if genNorm
        if isfield(data, 'D')
            minD = min(min([data.D]));
            maxD = max(max([data.D]));
            props.wind.normD = [minD maxD];
        end
        if isfield(data, 'V')
            minV = min(min([data.V]));
            maxV = max(max([data.V]));
            props.wind.normV = [minV maxV];
        end
        if isfield(data, 'A')
            minA = min(min([data.A]));
            maxA = max(max([data.A]));
            props.wind.normA = [minA maxA];
        end
        if isfield(data, 'CL')
            minCL = min(min([data.CL]));
            maxCL = max(max([data.CL]));
            props.wind.normCL = [minCL maxCL];
        end
        if isfield(data, 'CM')
            minCM = min(min([data.CM]));
            maxCM = max(max([data.CM]));
            props.wind.normCM = [minCM maxCM];
        end
    end
    
    % Now normalize everything
    dataNorm = data;
    for i = 1:length(dataNorm)
        if isfield(dataNorm, 'D')
            dataNorm(i).D = (dataNorm(i).D-props.wind.normD(1))./sum(abs(props.wind.normD));
        end
        if isfield(dataNorm, 'V')
            dataNorm(i).V = (dataNorm(i).V-props.wind.normV(1))./sum(abs(props.wind.normV));
        end
        if isfield(dataNorm, 'A')
            dataNorm(i).A = (dataNorm(i).A-props.wind.normA(1))./sum(abs(props.wind.normA));
        end
        if isfield(dataNorm, 'CL')
            dataNorm(i).CL = (dataNorm(i).CL-props.wind.normCL(1))./sum(abs(props.wind.normCL));
        end
        if isfield(dataNorm, 'CM')
            dataNorm(i).CM = (dataNorm(i).CM-props.wind.normCM(1))./sum(abs(props.wind.normCM));
        end
    end
end