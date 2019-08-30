function props = setBWindProps(props)
    % Sets up wind properties for buffeting
    
    % Default structural values (Great Belt East)
    if not(isfield(props, 'struct'))
        props.struct.m = 22740;
        props.struct.I = 2470000;
        props.struct.fh = 0.100;
        props.struct.fa = 0.278;
        props.struct.psih = 0.003;
        props.struct.psia = 0.003;
        props.struct.B = 31;
    end
    % Default wind values
    if not(isfield(props, 'wind'))
        props.wind.U = 20;
        props.wind.vrs = logspace(log10(0.1), log10(20), 25);
        props.wind.amplitudes = [1:2:5];
        props.wind.samplingFreq = 100;
        props.wind.deltaT = 1/props.wind.samplingFreq;
        props.wind.Nsteps = (props.struct.B*max(props.wind.vrs)/props.wind.U)/props.wind.deltaT;
        props.wind.movType = 'H';        
    end
    
    % Default network values
    if ~isfield(props, 'net'); props.net = struct; end
    if ~isfield(props.net, 'winLen'); props.net.winLen = 0.1; end
    
    % Menu flag
    flags.exitDatasetMenu = 0;
    
    
    while not(flags.exitDatasetMenu)
        % The main menu, let'a user change things
        dispHeader()
        disp('Choose one of the following options:');
        disp(strcat('   #1 Reduced velocities [', num2str(min(props.wind.vrs)), ',...,', num2str(max(props.wind.vrs)), '] (', num2str(length(props.wind.vrs)), ' values)'));
        disp(strcat('   #2 Rotation amplitudes [', num2str(min(props.wind.amplitudes)), ',...,', num2str(max(props.wind.amplitudes)),'] (', num2str(length(props.wind.amplitudes)), ' values)'));
        disp(strcat('   #3 Number of time-steps per sampled signal [', num2str(props.wind.Nsteps), ']'));
        disp(strcat('   #4 Wind speed [', num2str(props.wind.U), 'm/s]'));
        disp(strcat('   #5 Chord length [', num2str(props.struct.B), 'm]'));
        disp(strcat('   #6 Percentage of cycle to use as input [', num2str(100*props.net.winLen), '%]'));
        disp(strcat('   #0 Generate data and return'));
        flags.exitDatasetMenu = input(strcat('Selection [', num2str(flags.exitDatasetMenu), ']: #'));
        if isempty(flags.exitDatasetMenu); flags.exitDatasetMenu = 0; end
        switch flags.exitDatasetMenu
            case 1
                dispHeader()
                props.wind.vrs = input('New reduced velicities, in Matlab array format: ');
                if isempty(props.wind.vrs); props.wind.vrs = logspace(log10(0.1), log10(50), 25); end
                props.wind.Nsteps = (props.struct.B*max(props.wind.vrs)/props.wind.U)/props.wind.deltaT;
                flags.exitDatasetMenu = 0;
            case 2
                dispHeader()
                props.wind.amplitudes = input('New rotation amplitudes, in Matlab array format: ');
                if isempty(props.wind.amplitudes); props.wind.amplitudes = 1:2:5; end
                flags.exitDatasetMenu = 0;
            case 3
                dispHeader()
                props.wind.Nsteps = input('New number of time steps: ');
                if isempty(props.wind.Nsteps)
                    props.wind.Nsteps = (props.struct.B*max(props.wind.vrs)/props.wind.U)/props.wind.deltaT;
                else
                    props.wind.deltaT = (props.struct.B*max(props.wind.vrs)/props.wind.U)/props.wind.Nsteps;
                    props.wind.samplingFreq = 1/props.wind.deltaT;
                end
                flags.exitDatasetMenu = 0;
            case 4
                dispHeader()
                props.wind.U = input('New wind speed [m/s]: ');
                if isempty(props.wind.U); props.wind.U = 20; end
                flags.exitDatasetMenu = 0;
            case 5
                dispHeader()
                props.struct.B = input('New chord length [m]: ');
                if isempty(props.struct.B); props.struct.B = 31; end
                flags.exitDatasetMenu = 0;
            case 6
                dispHeader()
                ansInp = input('New cycle percetage to use as input [%]: ');
                if isempty(ansInp); ansInp = 10; end
                props.net.winLen = ansInp/100;
                flags.exitDatasetMenu = 0;                
            case 0
                flags.exitDatasetMenu = 1;
            otherwise
                flags.exitDatasetMenu = 0;
        end
    end

end
