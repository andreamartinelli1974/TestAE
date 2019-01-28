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

close all

prompt = ['There are ', num2str(invariants),...
    ' invariants. Which one do you like to examine? ',...
    '(Enter a number, blank or Camcel to randomly select)'];
title = 'Input';
answer = inputdlg(prompt,title);

if isempty(answer)
    i = unidrnd(invariants);
elseif isempty(answer{1})
    i = unidrnd(invariants);
elseif str2num(answer{1}) < 1 || str2num(answer{1}) > invariants
    msgbox('the number you enter was out of range. A randomly selected one was used');
    i = unidrnd(invariants);
else
    i = str2num(answer{1});
end

t = unidrnd(times);

samplesI = sort(unidrnd(maxsamplesI,500,1));
samplesP = sort(unidrnd(maxsamplesP,500,1));

% plot the runningtime
figure('Name','Time to compute (for any t)','NumberTitle','off');
hold on
grid on
running = bar(cell2mat([(AEdataWITHOUT.runningtime)',...
        AEdataWITH(1).runningtime',...
        AEdataWITH(2).runningtime']),'FaceColor','flat');
legend('Original','With Encoder case 1','With Encoder case 2','Location','southwest')

running(1).CData = [0.4 0 1];
running(2).CData = [0.2 1 0.8];

% plot the autocorrelation
%figure('Name',['X_Simulated: invariant nr ',num2str(i),' ',names{i},...
%    ' at time t, whole data'],'NumberTitle','off');
% hold on
for i = 1:size(AEdataWITHOUT.X_simulated{t},2);
    figure
    autocorr(AEdataWITHOUT.X_simulated{t}(:,i))
end
figure
autocorr(AEdataWITH(1).X_simulated{t}(:,i))
figure
autocorr(AEdataWITH(2).X_simulated{t}(:,i))

a=1;
% % ***** PLOT X_SIMULATED **********************************************
% % plot a sample of data
% figure('Name',['X_Simulated: invariant nr ',num2str(i),' ',names{i},...
%     ' at time t, 1000 randomly selected occurrencies'],'NumberTitle','off');
% hold on
% grid on
% plot(AEdataWITHOUT.X_simulated{t}(samplesI,i),'.','Color',[0.3 0 0.8])
% plot(AEdataWITH(1).X_simulated{t}(samplesI,i),'o','Color',[0.1 0.8 0.2])
% plot(AEdataWITH(2).X_simulated{t}(samplesI,i),'o','Color',[0.2 0.7 0.1])
% legend('Original','With Encoder case 1','With Encoder case 2','Location','southwest')
% 
% % plot the distributions
% figure('Name',['X_Simulated: invariant nr ',num2str(i),' ',names{i},...
%     ' at time t, whole data'],'NumberTitle','off');
% hold on
% grid on
% histogram(AEdataWITHOUT.X_simulated{t}(:,i),'FaceColor',[0.3 0 0.8])
% histogram(AEdataWITH(1).X_simulated{t}(:,i),'FaceColor',[0.1 0.8 0.2])
% histogram(AEdataWITH(2).X_simulated{t}(:,i),'FaceColor',[0.2 0.7 0.1])
% legend('Original','With Encoder case 1','With Encoder case 2','Location','southwest')
% 
% % plot mu, std, kurt
% statsWITH30 = [];
% statsWITH60 = [];
% statsWITHOUT = [];
% 
% for tt = 1:times
%     statsWITH30 = [statsWITH30,AEdataWITH(1).X_simulated{tt}(:,i)];
%     statsWITH60 = [statsWITH60,AEdataWITH(2).X_simulated{tt}(:,i)];
%     statsWITHOUT = [statsWITHOUT,AEdataWITHOUT.X_simulated{tt}(:,i)];
% end
% 
% % mu
% figure('Name',['X_Simulated: invariant nr ',num2str(i),' ',names{i},...
%     ' mean at any time'],'NumberTitle','off');
% hold on
% grid on
% mu = bar([mean(statsWITHOUT)',mean(statsWITH30)',mean(statsWITH60)'],'FaceColor','flat');
% mu(1).CData = [0.3 0 0.8];
% mu(2).CData = [0.1 0.8 0.2];
% mu(3).CData = [0.2 0.7 0.1];
% legend('Original','With Encoder case 1','With Encoder case 2','Location','southwest')
% 
% % std
% figure('Name',['X_Simulated: invariant nr ',num2str(i),' ',names{i},...
%     ' std at any time'],'NumberTitle','off');
% hold on
% grid on
% sigma = bar([std(statsWITHOUT)',std(statsWITH30)',std(statsWITH60)'],'FaceColor','flat');
% sigma(1).CData = [0.3 0 0.8];
% sigma(2).CData = [0.1 0.8 0.2];
% sigma(3).CData = [0.2 0.7 0.1];
% legend('Original','With Encoder case 1','With Encoder case 2','Location','southwest')
% 
% % kurt
% figure('Name',['X_Simulated: invariant nr ',num2str(i),' ',names{i},...
%     ' kurtosis at any time'],'NumberTitle','off');
% hold on
% grid on
% kurt = bar([kurtosis(statsWITHOUT)',kurtosis(statsWITH30)',kurtosis(statsWITH60)'],'FaceColor','flat');
% kurt(1).CData = [0.3 0 0.8];
% kurt(2).CData = [0.1 0.8 0.2];
% kurt(3).CData = [0.2 0.7 0.1];
% legend('Original','With Encoder case 1','With Encoder case 2','Location','southwest')
% 


% ***** PLOT X_PROJECTED **********************************************
% plot a sample of data
figure('Name',['X_projected: invariant nr ',num2str(i),' ',names{i},...
    ' at time t, 1000 randomly selected occurrencies'],'NumberTitle','off');
hold on
grid on
plot(AEdataWITHOUT.X_Projected{t}(samplesP,i),'.','Color',[0.8 0 0.3])
plot(AEdataWITH(1).X_Projected{t}(samplesP,i),'o','Color',[0.4 0.4 0.2])
plot(AEdataWITH(2).X_Projected{t}(samplesP,i),'o','Color',[0.3 0.3 0.3])
legend('Original','With Encoder case 1','With Encoder case 2','Location','southwest')

% plot the distributions
figure('Name',['X_projected: invariant nr ',num2str(i),' ',names{i},...
    ' at time t, whole data'],'NumberTitle','off');
hold on
grid on
histogram(AEdataWITHOUT.X_Projected{t}(:,i),'FaceColor',[0.8 0 0.3])
histogram(AEdataWITH(1).X_Projected{t}(:,i),'FaceColor',[0.4 0.4 0.2])
histogram(AEdataWITH(2).X_Projected{t}(:,i),'FaceColor',[0.3 0.3 0.3])
legend('Original','With Encoder case 1','With Encoder case 2','Location','southwest')

% plot mu, std, kurt
statsWITH30 = [];
statsWITH60 = [];
statsWITHOUT = [];

for tt = 1:times
    statsWITH30 = [statsWITH30,AEdataWITH(1).X_Projected{tt}(:,i)];
    statsWITH60 = [statsWITH60,AEdataWITH(2).X_Projected{tt}(:,i)];
    statsWITHOUT = [statsWITHOUT,AEdataWITHOUT.X_Projected{tt}(:,i)];
end

% mu
figure('Name',['X_projected: invariant nr ',num2str(i),' ',names{i},...
    ' mean at any time'],'NumberTitle','off');
hold on
grid on
mu = bar([mean(statsWITHOUT)',mean(statsWITH30)',mean(statsWITH60)'],'FaceColor','flat');
mu(1).CData = [0.8 0 0.3];
mu(2).CData = [0.4 0.4 0.2];
mu(3).CData = [0.3 0.3 0.3];
legend('Original','With Encoder case 1','With Encoder case 2','Location','southwest')

% std
figure('Name',['X_projected: invariant nr ',num2str(i),' ',names{i},...
    ' std at any time'],'NumberTitle','off');
hold on
grid on
sigma = bar([std(statsWITHOUT)',std(statsWITH30)',std(statsWITH60)'],'FaceColor','flat');
sigma(1).CData = [0.8 0 0.3];
sigma(2).CData = [0.4 0.4 0.2];
sigma(3).CData = [0.3 0.3 0.3];
legend('Original','With Encoder case 1','With Encoder case 2','Location','southwest')

% kurt
figure('Name',['X_projected: invariant nr ',num2str(i),' ',names{i},...
    ' kurtosis at any time'],'NumberTitle','off');
hold on
grid on
kurt = bar([kurtosis(statsWITHOUT)',kurtosis(statsWITH30)',kurtosis(statsWITH60)'],'FaceColor','flat');
kurt(1).CData = [0.8 0 0.3];
kurt(2).CData = [0.4 0.4 0.2];
kurt(3).CData = [0.3 0.3 0.3];
legend('Original','With Encoder case 1','With Encoder case 2','Location','southwest')



