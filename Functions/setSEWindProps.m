function props = setSEWindProps(props)
    % Sets up wind properties for self-exciting forces
   
    % Default wind values
    if not(isfield(props, 'wind'))
        props.wind.vrs = 2:1:50;
        props.wind.amplitudes = 1:6;
        props.wind.samplingFreq = 200;
        props.wind.deltaT = 1/props.wind.samplingFreq;
        props.wind.Nsteps = 500;
        props.wind.movType = 'H';
        props.wind.U = 20;
    end
    % Default network values
    if ~isfield(props, 'net'); props.net = struct; end
    if ~isfield(props.net, 'winLen'); props.net.winLen = 0.1; end
    % Default structural values (default is Great Belt East Bridge)
    if not(isfield(props, 'struct'))
        props.struct.m = 22740;
        props.struct.I = 2470000;
        props.struct.fh = 0.100;
        props.struct.fa = 0.278;
        props.struct.psih = 0.003;
        props.struct.psia = 0.003;
        props.struct.B = 31;
    end
    flags.exitDatasetMenu = 0;
    
    
    while not(flags.exitDatasetMenu)
        dispHeader()
        disp('Choose one of the following options:');
        disp(strcat('   #1 Reduced velocities [', num2str(min(props.wind.vrs)), ',...,', num2str(max(props.wind.vrs)), '] (', num2str(length(props.wind.vrs)), ' values)'));
        disp(strcat('   #2 Rotation amplitudes [', num2str(min(props.wind.amplitudes)), ',...,', num2str(max(props.wind.amplitudes)),'] (', num2str(length(props.wind.amplitudes)), ' values)'));
        disp(strcat('   #3 Signal sampling frequency [', num2str(props.wind.samplingFreq), 'Hz]'));
        disp(strcat('   #4 Wind speed [', num2str(props.wind.U), 'm/s]'));
        disp(strcat('   #5 Chord length [', num2str(props.struct.B), 'm]'));
        disp(strcat('   #6 Forced vibration direction [', props.wind.movType, ']'));
        disp(strcat('   #7 Percentage of cycle to use as input [', num2str(100*props.net.winLen), '%]'));
        disp(strcat('   #0 Generate data and return'));
        flags.exitDatasetMenu = input(strcat('Selection [', num2str(flags.exitDatasetMenu), ']: #'));
        if isempty(flags.exitDatasetMenu); flags.exitDatasetMenu = 0; end
        switch flags.exitDatasetMenu
            case 1
                dispHeader()
                props.wind.vrs = input('New reduced velicities, in Matlab array format: ');
                if isempty(props.wind.vrs); props.wind.vrs = 2:2:50; end
                flags.exitDatasetMenu = 0;
            case 2
                dispHeader()
                props.wind.amplitudes = input('New rotation amplitudes, in Matlab array format: ');
                if isempty(props.wind.amplitudes); props.wind.amplitudes = 1:6; end
                flags.exitDatasetMenu = 0;
            case 3
                dispHeader()
                props.wind.samplingFreq = input('New signal sampling frequency: ');
                if isempty(props.wind.samplingFreq); props.wind.samplingFreq = 200; end
                props.wind.deltaT = 1/props.wind.samplingFreq;
                flags.exitDatasetMenu = 0;
            case 4
                dispHeader()
                props.wind.U = input('New wind speed: ');
                if isempty(props.wind.U); props.wind.U = 20; end
                flags.exitDatasetMenu = 0;
            case 5
                dispHeader()
                props.struct.B = input('New chord length: ');
                if isempty(props.struct.B); props.struct.B = 31; end
                flags.exitDatasetMenu = 0;
            case 6
                dispHeader()
                props.wind.movType = input('New cycle forced movement type (H/P): ', 's');
                if isempty(props.wind.movType) || (not(strcmp(props.wind.movType, 'H')) && not(strcmp(props.wind.movType, 'P'))); props.wind.movType = 'H'; end
                flags.exitDatasetMenu = 0;
            case 7
                dispHeader()
                props.wind.winLen = input('New cycle percetage to use as input: ');
                if isempty(props.wind.winLen); props.wind.winLen = 10; end
                if ansInp > 1
                    props.net.winLen = ansInp/100;
                else
                    props.net.winLen = ansInp;
                end 
                flags.exitDatasetMenu = 0;                
            case 0
                flags.exitDatasetMenu = 1;
            otherwise
                flags.exitDatasetMenu = 0;
        end
    end

end
