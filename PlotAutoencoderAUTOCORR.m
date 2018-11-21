%%   PLOT SECTION *********************************************************
clear all
clc
close all

datapath = 'C:\Program Files\MATLAB\R2018a\work\IMI\AutoEncoderData\';


load ([datapath,'AEdataWITH20181115.mat']);
load ([datapath,'AEdataWITHOUT20181115.mat']);
load ([datapath,'AssetLegend.mat']);

%%
[none,times] = size(AEdataWITH(1).X_simulated);
[maxsamplesI,invariants] = size(AEdataWITH(1).X_simulated{1});
[maxsamplesP,invariants] = size(AEdataWITH(1).X_Projected{1});
names = Universe_1.AllInvariants.NamesSet;
WithoutFlag = 0;

close all

% prompt = ['There are ', num2str(invariants),...
%     ' invariants. Which one do you like to examine? ',...
%     '(Enter a number, blank or Camcel to randomly select)'];
% title = 'Input';
% answer = inputdlg(prompt,title);
% 
% if isempty(answer)
%     i = unidrnd(invariants);
% elseif isempty(answer{1})
%     i = unidrnd(invariants);
% elseif str2num(answer{1}) < 1 || str2num(answer{1}) > invariants
%     msgbox('the number you enter was out of range. A randomly selected one was used');
%     i = unidrnd(invariants);
% else
%     i = str2num(answer{1});
% end

t = unidrnd(times);

% plot the autocorrelation
%figure('Name',['X_Simulated: invariant nr ',num2str(i),' ',names{i},...
%    ' at time t, whole data'],'NumberTitle','off');
% hold on
if WithoutFlag == 1
    for i = 1:size(AEdataWITHOUT.X_simulated{t},2)
        figure
        autocorr(AEdataWITHOUT.X_simulated{t}(:,i))
    end
end

% for i = 1:size(AEdataWITH(1).X_simulated{t},2)
%     if(AEdataWITH(1).AutoCorrFlag{t}(i,1)) == 1
%         figure
%         autocorr(AEdataWITH(1).X_simulated{t}(:,i))
%     end
% end

for i = 1:size(AEdataWITH(2).X_simulated{t},2)
    if(AEdataWITH(2).AutoCorrFlag{t}(i,1)) == 1
        figure
        autocorr(AEdataWITH(2).X_simulated{t}(:,i))
    end
end

a=1;





