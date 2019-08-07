function runAnalysis()
    % Initializes menu for specific analysis
    flags.Exit = 0;
    while not(flags.Exit)
        flags.mainMenu = 0;
        dispHeader()
        disp('Choose one of the following options:');
        disp('   #1 Aerodynamic derivatives');
        disp('   #2 Flutter analysis');
        disp('   #3 Self-excited forces due to random displacement');
        disp('   #4 Buffeting forces due to random displacement');
        disp('   #5 Coupled Analysis');
        disp('   #0 Back');
        flags.mainMenu = input(strcat('Selection [', num2str(flags.mainMenu), ']: #'));
        if isempty(flags.mainMenu); flags.mainMenu = 0; end
        switch flags.mainMenu
            case 1
                [derivs] = printFlutterDerivatives();
            case 2
                % In case we just got the derivatives, we don't need to
                % load them from file...
                if ~exist('derivs', 'var')
                    dispHeader()
                    disp('Select a derivative result file...')
                    [file, path] = uigetfile('*.mat', 'Select a derivative result file.');
                    if file ~= 0; derivs = load([path file]); derivs = derivs.results.derivatives; end
                end
                printFlutterAnalysis(derivs);
            case 3
                printSERandomDisp()
            case 4
                printBRandomDisp()
            case 5
                printCoupledAnalysis()
            case 0
                flags.Exit = 1;
            otherwise
        end
    end
end