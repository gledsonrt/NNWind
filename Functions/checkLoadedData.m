function [data, props] = checkLoadedData(props)
% README - Loading the dataset for training.
%
% The dataset should be organized as a Matlab structure with the following fields:
%   'vr'            - the reduced velocity
%   'amplitude'     - the amplitude of vibration, in degrees
%   'D'             - the displacement or rotation (for SE forces)
%   'V'             - the velocity (for SE and B forces)
%   'A'             - the acceleration (for B forces)
%   'CL'            - the coefficient of lift
%   'CM'            - the coefficient of moment
%
% An example of dataset can be found in './Examples/Analytical Self-Excited/Heave/Data/trainingData.mat'

    dispHeader()
    help checkLoadedData;
    dummy = input(strcat('<press any key to load the dataset>'));
    data = NaN;
        
    dispHeader()
    disp('Select a dataset file to load...')
    
    % Loads the data file to matlab
    [file, path] = uigetfile('*.mat', 'Select a dataset to be loaded.');
    if file ~= 0
        data = load([path file]);   
        fnames = fieldnames(data); 
        if length(fnames) == 1; data = data.(fnames{1}); end

        % Data file should be a structure and contain at least the
        % following fields: vr, amplitude, V, (D or A), CL, CM
        fnames = fieldnames(data);
        assert(any(strcmp(fnames,'vr')), 'Loaded structure does not contain a "vr" field.')
        assert(any(strcmp(fnames,'amplitude')), 'Loaded structure does not contain an "amplitude" field.')
        assert(any(strcmp(fnames,'CL')), 'Loaded structure does not contain a "CL" field.')
        assert(any(strcmp(fnames,'CM')), 'Loaded structure does not contain a "CL" field.')
        assert((any(strcmp(fnames,'D')) || any(strcmp(fnames,'A'))), 'Loaded structure must contain a "D" field for SE forces, or an "A" field for buffeting forces.')

        
        % Since we loaded data from file, let's assume it's numerical/experimental
        props.dataType = 'Numerical';
        
        % Initialize the main window properties
        if not(isfield(props, 'wind'))
            props.wind.vrs = unique([data(:).vr]);
            props.wind.amplitudes = unique([data(:).amplitude]);
            props.wind.samplingFreq = 1;
            props.wind.deltaT = 1/props.wind.samplingFreq;
            props.wind.Nsteps = length(data(1).CL);
            if any(strcmp(fnames,'D'))
                props.modelType = 'SelfExcited';
                props.wind.movType = 'H';
            else
                props.modelType = 'Buffeting';
            end
            props.wind.U = 20;
        end
        
        % Initialize the main network properties
        if ~isfield(props, 'net'); props.net = struct; end
        if ~isfield(props.net, 'winLen'); props.net.winLen = 0.1; end
        if ~isfield(props.net, 'winumCyclenLen'); props.net.numCycle = 1; end
        
        % Initialize the main structural properties
        % Default is the Great Belt East Bridge
        if not(isfield(props, 'struct'))
            props.struct.m = 22740;
            props.struct.I = 2470000;
            props.struct.fh = 0.100;
            props.struct.fa = 0.278;
            props.struct.psih = 0.003;
            props.struct.psia = 0.003;
            props.struct.B = 31;
        end
        
        % Let the user change some parameters
        flags.exitDatasetMenu = 0;
        while not(flags.exitDatasetMenu)
            dispHeader()
            disp('Set up the following parameters:');
            disp(strcat('   #1 Original sampling frequency [', num2str(props.wind.samplingFreq), 'Hz]'));
%             disp(strcat('   #2 Sampled steps for training [', num2str(props.wind.Nsteps), ']'));
            disp(strcat('   #2 Wind speed [', num2str(props.wind.U), 'm/s]'));
            disp(strcat('   #3 Chord length [', num2str(props.struct.B), 'm]'));
            disp(strcat('   #4 Percentage of data to use as input [', num2str(100*props.net.winLen), '%]'));
%             disp(strcat('   #5 Number of cycles in the data [', num2str(props.net.numCycle), ']'));
            if any(strcmp(fnames,'D')) && strcmp(props.modelType, 'SelfExcited')
                disp(strcat('   #5 Forced vibration direction [', props.wind.movType, ']'));
            end
            disp(strcat('   #0 Generate data and return'));
            flags.exitDatasetMenu = input(strcat('Selection [', num2str(flags.exitDatasetMenu), ']: #'));
            if isempty(flags.exitDatasetMenu); flags.exitDatasetMenu = 0; end
            switch flags.exitDatasetMenu
                case 1
                    dispHeader()
                    props.wind.samplingFreq = input('New signal sampling frequency: ');
                    if isempty(props.wind.samplingFreq); props.wind.samplingFreq = 200; end
                    props.wind.deltaT = 1/props.wind.samplingFreq;
                    flags.exitDatasetMenu = 0;
%                 case 2
%                     dispHeader()
%                     props.wind.Nsteps = input('New number of sampled steps: ');
%                     if isempty(props.wind.Nsteps); props.wind.Nsteps = 500; end
%                     flags.exitDatasetMenu = 0;
                case 2
                    dispHeader()
                    props.wind.U = input('New wind speed: ');
                    if isempty(props.wind.U); props.wind.U = 20; end
                    flags.exitDatasetMenu = 0;
                case 3
                    dispHeader()
                    props.struct.B = input('New chord length: ');
                    if isempty(props.struct.B); props.struct.B = 31; end
                    flags.exitDatasetMenu = 0;
                case 4
                    dispHeader()
                    ansInp = input('New cycle percetage to use as input: ');
                    if isempty(ansInp); ansInp = 10; end
                    props.net.winLen = ansInp/100;
                    flags.exitDatasetMenu = 0;      
%                 case 6
%                     dispHeader()
%                     props.net.numCycle = input('Number of cycles in the input: ');
%                     if isempty(props.net.numCycle); props.net.numCycle = 1; end
%                     flags.exitDatasetMenu = 0;
                case 5
                    if any(strcmp(fnames,'D')) && strcmp(props.modelType, 'SelfExcited')
                        dispHeader()
                        props.wind.movType = input('New cycle forced movement type (H/P): ', 's');
                        if isempty(props.wind.movType) || (not(strcmp(props.wind.movType, 'H')) && not(strcmp(props.wind.movType, 'P'))); props.wind.movType = 'H'; end
                    end
                    flags.exitDatasetMenu = 0;   
                case 0
                    flags.exitDatasetMenu = 1;
                otherwise
                    flags.exitDatasetMenu = 0;
            end
        end

% Assuming that the pre-processing of the data is carried out before
%         % If the data was loaded, we proceed with resampling
%         % We add additional 29 steps for the resampled version, in order to
%         % remove influence of aliasing due to filtering in the resample function
%         if isstruct(data) && props.wind.Nsteps ~= length(data(1).CL)
%             dispHeader()
%             disp('Resampling dataset...')
%             h = waitbar(0,'Starting...'); % Progress bar
%             set(findall(h,'type','text'),'Interpreter','none');
%             for i = 1:length(data)
%                 if isfield(data, 'D')
%                     data(i).D = resample(data(i).D, props.wind.Nsteps+29, length(data(i).D));
%                     data(i).D = data(i).D(15:end-15);
%                 end
%                 if isfield(data, 'A')
%                     data(i).A = resample(data(i).A, props.wind.Nsteps+29, length(data(i).A));
%                     data(i).A = data(i).A(15:end-15);
%                 end
%                 data(i).V = resample(data(i).V, props.wind.Nsteps+29, length(data(i).V));
%                 data(i).V = data(i).V(15:end-15);
%                 data(i).CL = resample(data(i).CL, props.wind.Nsteps+29, length(data(i).CL));
%                 data(i).CL = data(i).CL(15:end-15);
%                 data(i).CM = resample(data(i).CM, props.wind.Nsteps+29, length(data(i).CM));
%                 data(i).CM = data(i).CM(15:end-15);
%                 waitbar(i/length(data),h,sprintf('Resampling dataset: %2.1f%% done',i/length(data)*100));
%             end
%             close(h);
%         end
    
    
    end 
end