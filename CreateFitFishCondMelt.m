function [fitresult, gof] = createFitFishCondMelt(xydataobj)
%  Create a conduction and melting fit for imported TEAPPS data. This fit is designed for the
%  heating curves. 
%  Data for fit:
%      X Input : Time
%      Y Output: Math
%  Output: (if a working metal)
%      fitresult : 2x2 structure with fitresult and gof of conduction and
%      melting.
%           To retrieve conduction's fitresult: fitresult.cond.fitresult
%           To retrieve conduction's gof: fitresult.cond.gof
%           To retrieve melting fitresult: fitresult.melt.fitresult
%           To retrieve melting gof: fitresult.melt.gof
%      gof : empty
%  by Nadine Meister

clear time temp
time = get(xydataobj,'x');
temp = get(xydataobj,'y');
scale = 15; %how much to increment by
%Find when metal theoretically start metling
meltTemp = get(xydataobj, 'materialMeltTemp');
meltIndex = find(temp > meltTemp);
if isempty(meltIndex) || abs(length(temp) - meltIndex(1)) < scale %doesn't even reach melting point
    %meltIndex = 4;
    [fitresult, gof] = CreateFitFish(xydataobj); 
    return;
else
    meltIndex = meltIndex(1);
end
if meltIndex < 150
    meltIndex = 150;%having too low of a meltIndex causes inaccurate comparisons with rsquared
end
meltIndexAr = [meltIndex, meltIndex + scale];
%% Fit: TEAPPS DATA
[xData, yData] = prepareCurveData( time, temp);

% Set up fittype and options.
ft = fittype( 'a*x^b +c', 'independent', 'x', 'dependent', 'y' );
opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
opts.Display = 'Off';

if  strcmp(cell2mat(listinfo(xydataobj,'pulse')),'hot')

    % Initialize arrays to store fits and goodness-of-fit for condction
    % and melting
    gof = struct.empty;
    
%Conduction
    % Set up fittype and options.
    ft = fittype( 'a*x^b +c', 'independent', 'x', 'dependent', 'y' );
    opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
    opts.Display = 'Off';

    excludedPoints = excludedata( xData, yData, 'Indices', [meltIndexAr(1):length(temp)]);
    opts.Exclude = excludedPoints;
    
    opts.Lower = [0 0.1 -20];
    opts.StartPoint = [0.310267049183961 0.5 0.0238233893331793];
    opts.Upper = [Inf 2 60];

    % Fit model to data.
    [TwoGraphs(1).cond.fitresult, TwoGraphs(1).cond.gof] = fit( xData, yData, ft, opts );
    
%Melting
    % Set up fittype and options.
    ft = fittype( 'poly1' );
    excludedPoints = excludedata( xData, yData, 'Indices', [1:meltIndexAr(1)]);
    opts = fitoptions( 'Method', 'LinearLeastSquares' );
    opts.Exclude = excludedPoints;

    % Fit model to data.
    [TwoGraphs(1).melt.fitresult, TwoGraphs(1).melt.gof] = fit( xData, yData, ft, opts );

    count = 1;
    sumArray = zeros(0,10); %arbitary 10
    while count <= 2
        
    %Conduction
        % Set up fittype and options.
        ft = fittype( 'a*x^b +c', 'independent', 'x', 'dependent', 'y' );
        opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
        opts.Display = 'Off';
        
        excludedPoints = excludedata( xData, yData, 'Indices', [meltIndexAr(2):length(temp)]); 
        opts.Exclude = excludedPoints;
        
        opts.Lower = [0 0.1 -20];
        opts.StartPoint = [0.310267049183961 0.5 0.0238233893331793];
        opts.Upper = [Inf 2 60];
        
        % Fit model to data.
        [TwoGraphs(2).cond.fitresult, TwoGraphs(2).cond.gof] = fit( xData, yData, ft, opts );
        
    %Melting
        % Set up fittype and options.
        ft = fittype( 'poly1' );
        excludedPoints = excludedata( xData, yData, 'Indices', [1:meltIndexAr(2)]); 
        opts = fitoptions( 'Method', 'LinearLeastSquares' );
        opts.Exclude = excludedPoints;
        
        % Fit model to data.
        [TwoGraphs(2).melt.fitresult, TwoGraphs(2).melt.gof] = fit( xData, yData, ft, opts );
        
        %comparing Rsquared values and determining whether to increase or
        %decrease meltIndex
        R2Cond = [TwoGraphs(1).cond.gof.rsquare, TwoGraphs(2).cond.gof.rsquare]; 
        R2Melt = [TwoGraphs(1).melt.gof.rsquare, TwoGraphs(2).melt.gof.rsquare];
        if abs(R2Cond(1) - R2Cond(2)) > abs(R2Melt(1) - R2Melt(2))
            [~,indexR2] = max(R2Cond(:));
        else
            [~, indexR2] = max(R2Melt(:));
        end
        TwoGraphs(1) = TwoGraphs(indexR2);
        temporaryMeltIndexAr(1) = meltIndexAr(indexR2);
        if meltIndexAr(indexR2) > meltIndexAr(1:end ~= indexR2)
            temporaryMeltIndexAr(2) = meltIndexAr(indexR2) + scale;
            if temporaryMeltIndexAr(2) > length(temp)
                fitresult = TwoGraphs(indexR2);
                return;
            end
        else
            temporaryMeltIndexAr(2) = meltIndexAr(indexR2) - scale;
            if temporaryMeltIndexAr(2) < 0
                fitresult = TwoGraphs(indexR2);
                return;
            end
        end
        %check if combination of meltIndex was already checked (means that
        %meltIndex is found)
        sum = meltIndexAr(1) + meltIndexAr(2);
        meltIndexAr = temporaryMeltIndexAr;
        temporarySum = temporaryMeltIndexAr(1) + temporaryMeltIndexAr(2);
        sumArray = [sumArray sum];
        if find(sumArray == temporarySum )
            count = count + 1;
        end
    end
    fitresult = TwoGraphs(1);
    %fitresult = {TwoGraphs(1).cond.fitresult, TwoGraphs(1).melt.fitresult};
    %gof = {TwoGraphs(1).cond.gof, TwoGraphs(1).melt.gof};
    %[fitresult, gof] = [{TwoGraphs(1).cond.fitresult, TwoGraphs(1).melt.fitresult} {TwoGraphs(1).cond.gof, TwoGraphs(1).melt.gof}];
elseif strcmp(cell2mat(listinfo(xydataobj,'pulse')),'cold')
    
    % Set up fittype and options.
    ft = fittype( 'a*(x^(-b) - (x-t0)^(-b)) +c', 'independent', 'x', 'dependent', 'y' );
    opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
    opts.Display = 'Off';
    
    opts.Lower = [-1e8 .05 -40 time(1)*.7];
    opts.StartPoint = [-0.310267049183961 .5 0.0238233893331793 time(1)*.99];
    opts.Upper = [0 2 120 time(1)*.9999];
    
    % Fit model to data.
    [fitresult, gof] = fit( xData, yData, ft, opts );
    
elseif strcmp(cell2mat(listinfo(xydataobj,'pulse')),'power')
    
    % Set up fittype and options.
    ft = fittype( 'a*x^(-b)+c', 'independent', 'x', 'dependent', 'y' );
    opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
    opts.Display = 'Off';
    
    opts.Lower = [-1e8 -5 0];
    opts.StartPoint = [-0.310267049183961 .5 0.0238233893331793];
    opts.Upper = [1e8 5 500];
    
    % Fit model to data.
    [fitresult, gof] = fit( xData, yData, ft, opts );
end

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

