function [dRcenterustd, Rcenterustd] = uncertainties(offsetArray, Ch1, Ch3) %there's definetly a faster way to do this
%calculates the uncertainties of the oscilloscope of each point using the 'Average Acquisition
%mode' and the 'Sample Acquisition mode'

%Output: standard uncertainty of center resistor measurement between each
%point (ustddRcenter) and the total uncertainty of each point (ustdRcenter)

%Extracting data from Offset array
Rref = 124.07;
Ch1Offset = offsetArray(1,1);
Ch3Offset = offsetArray(1,3);
Ch1Scale = offsetArray(2,1);
Ch3Scale = offsetArray(2,3);

%partial derivatives
dRdCh1 = Rref ./ Ch3;
dRdCh3 = Rref .* Ch1 ./ Ch3.^2;
dRdRref = Ch1 ./ Ch3 - 1;


%Between Points - delta, 'Average Acquisition mode' (no +1.2mV)

%calculate difference between points
Ch1diff = diff(Ch1);
Ch3diff = diff(Ch3);

%%V1, V3, Rb uncertainty: calculate DC Gain Accuracy, extra divisions,
dCh1DCGain = 0.015*abs(Ch1diff);
dCh3DCGain = 0.015*abs(Ch3diff);

dCh1extraDiv = 0.05*Ch1Scale;
dCh3extraDiv = 0.05*Ch3Scale;

uTotaldCh1 = dCh1DCGain + dCh1extraDiv;
uTotaldCh3 = dCh3DCGain + dCh3extraDiv;
uTotaldRref = 0.03; %use actual value

ustddCh1 = uTotaldCh1./sqrt(3);
ustddCh3 = uTotaldCh3./sqrt(3);
ustddRref = uTotaldRref./sqrt(3);

%Propogation of uncertainty
dRcenterustd = rssq([dRdCh1(1:end-1).*ustddCh1 dRdCh3(1:end-1).*ustddCh3 dRdRref(1:end-1).*ustddRref],2); %difference uses deriv of pervious ?


%total uncertainty in Rcenter - single sample, 'sample acquistion mode'

%V1, V3, Rb uncertainty
Ch1DCGain = 0.015*abs(Ch1 - Ch1Offset);
Ch3DCGain = 0.015*abs(Ch3 - Ch3Offset);

Ch1extraDiv = 0.35*Ch1Scale; %0.2 from offset, 0.15 from other
Ch3extraDiv = 0.35*Ch3Scale;

Ch1OffsetAcc = 0.005*Ch1Offset;
Ch3OffsetAcc = 0.005*Ch3Offset;

uTotalCh1 = Ch1DCGain + Ch1extraDiv + Ch1OffsetAcc + 0.0006;
uTotalCh3 = Ch3DCGain + Ch3extraDiv + Ch3OffsetAcc + 0.0006;
uTotalRref = 0.6; %change

ustdCh1 = uTotalCh1./sqrt(3);
ustdCh3 = uTotalCh3./sqrt(3);
ustdRref = uTotalRref./sqrt(3);

%Propogation of Uncertainty
Rcenterustd = rssq([dRdCh1.*ustdCh1 dRdCh3.*ustdCh3 dRdRref.*ustdRref],2); 




end