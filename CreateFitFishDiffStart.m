function [fitresult, gof] = createFitFishDiffStart(xydataobj)
%  Create a fit for imported TEAPPS data. This fit is designed for the
%  heating curves. 
%  Data for fit:
%      X Input : Time
%      Y Output: Math
%  Output:
%      fitresult : a fit object representing the fit.
%      gof : structure with goodness-of fit info.
%  by Nadine Meister

clear time temp
time = get(xydataobj,'x');
temp = get(xydataobj,'y');
%% Fit: TEAPPS DATA
[xData, yData] = prepareCurveData( time, temp);

% Set up fittype and options.
ft = fittype( 'a*x^b +c', 'independent', 'x', 'dependent', 'y' );
opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
opts.Display = 'Off';

if  strcmp(cell2mat(listinfo(xydataobj,'pulse')),'hot')
    
    % Set up fittype and options.
    ft = fittype( 'a*x^b +c', 'independent', 'x', 'dependent', 'y' );
    opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
    opts.Display = 'Off';

    opts.Lower = [0 0.1 -20];
    opts.StartPoint = [0.310267049183961 0.5 15];
    opts.Upper = [Inf 2 100];

elseif strcmp(cell2mat(listinfo(xydataobj,'pulse')),'cold')
    
    % Set up fittype and options.
    ft = fittype( 'a*(x^(-b) - (x-t0)^(-b)) +c', 'independent', 'x', 'dependent', 'y' );
    opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
    opts.Display = 'Off';
    
    opts.Lower = [-1e8 .05 -40 time(1)*.7];
    opts.StartPoint = [-0.310267049183961 0.130167533414825 0.0238233893331793 time(1)*.99];
    opts.Upper = [0 2 120 time(1)*.9999];
    
elseif strcmp(cell2mat(listinfo(xydataobj,'pulse')),'power')
    
    % Set up fittype and options.
    ft = fittype( 'a*x^(-b)+c', 'independent', 'x', 'dependent', 'y' );
    opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
    opts.Display = 'Off';
    
    opts.Lower = [-1e8 -5 0];
    opts.StartPoint = [-0.310267049183961 0.130167533414825 0.0238233893331793];
    opts.Upper = [1e8 5 500];
    
end
% Fit model to data.
[fitresult, gof] = fit( xData, yData, ft, opts );
%{
% Plot fit with data.
figure( 'Name', char(strcat(get(xydataobj,'material'),{' '},{num2str(round(get(xydataobj,'nompower'),3,'significant'))},{'W'})) );
h = plot( fitresult, xData, yData );
legend( h, 'math80 vs. time80', 'Air 80', 'Location', 'NorthEast' );
% Label axes
xlabel 'time [s]'
ylabel 'T-25C [K]'
grid on
%}

