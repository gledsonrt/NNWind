function NNWind(varargin)
    % Start and add the functions to the path
    clc; clear; close all; flags = struct; addpath(genpath('Functions'));
    set(0,'defaulttextInterpreter','latex')
    warning off backtrace
    
    % Initialize main flag
    flags.Exit = 0;
    
    % Get the Matlab version
    ver = version; ver = str2double(ver(1:3));
    assert(ver >= 9.5, sprintf('Your Matlab version is too old!\nVersion required: R2018b.'));
    
    while not(flags.Exit)
        % Initialize main menu
        flags.mainMenu = 1;
        dispHeader()
        disp('Choose one of the following options:');
        disp('   #1 Create new network model');
        disp('   #2 Evaluate existing network model');   
        disp('   #3 Run analysis');   
        disp('   #0 Exit');
        flags.mainMenu = input(strcat('Selection [', num2str(flags.mainMenu), ']: #'));
        if isempty(flags.mainMenu); flags.mainMenu = 1; end
        switch flags.mainMenu
            case 1
                % Initialize menu for new model
                dispHeader()
                disp('Choose one of the following options:');
                disp('   #1 Self-excited forces');
                disp('   #2 Buffeting forces');   
                disp('   #0 Back');
                flags.newNet = input(strcat('Selection [', num2str(1), ']: #'));
                if isempty(flags.newNet); flags.newNet = 1; end
                switch flags.newNet
                    case 1
                        new_SelfExcited();
                    case 2
                        new_Buffeting();
                    otherwise
                        flags.mainMenu = 1;
                end
            case 2
                % To verify the performance of a model
                dispHeader()
                disp('Select a trained model from the directory...')
                [file, path] = uigetfile('*.mat', 'Select a saved neural network model.');
                % Check if file exists
                if file ~= 0; load([path file]); end
                if exist('net', 'var') && exist('props', 'var') && exist('info', 'var')
                    % If is a valid model file we proceed
                    netInfo = load([path file], 'info'); netInfo = netInfo.info;
                    loadedNN(net, props, netInfo, path, file);
                end
            case 3
                % Initialize the analysis menu
                runAnalysis()
            case 0
                % Exit the program
                dispHeader(); disp('Goodbye.'); rmpath(genpath('Functions')); flags.Exit = 1;
            otherwise
        end
    end
end