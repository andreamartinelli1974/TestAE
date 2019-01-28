function plotBarChart(~, ~, vector4BarChart, titParam, xParam, yParam, legParam)

% This function allows to plot bar charts
% Input (example):
% --> figure param and data for bar chart
% figParam.pos  = 'OuterPosition'
% figParam.coord = [230 230 850 610]
% vector4BarChart = [CurrentWeights]
% --> title param
% titParam.name  = {[Label.universeName,' Analysis as of ',ReferenceDate]}
% titParam.fontSize = 12
% titParam.fontWeight = 'Bold'
% titParam.units = 'normalized'
% titParam.alignementH = 'center'
% titParam.alignementV = 'bottom'
% --> x axis param
% xParam.axisLabels        = AssetNames
% xParam.tickLabelRotation = 90
% xParam.fontSize          = 8
% xParam.lineWidth         = 3
% xParam.edgeColor         = 'red'
% xParam.barParam          = 2
% --> y axis param
% yParam.axisLabels = '% Allocations'
% yParam.fontSize   = 12
% --> legend param
% legParam.title    = 'Current AA'
% legParam.fontSize = 8
% legParam.location = 'best';

figParam.pos   = 'OuterPosition';
figParam.coord = [230 230 850 610];
figure(figParam.pos, figParam.coord);

% dist = 1 ;    % give the distance you want >0
% x = 1:dist:(1+(size(vector4BarChart,1)-1)*dist) ;
% bar(x,vector4BarChart)

barChart = bar(vector4BarChart,'BarWidth',0.7);
grid on;
% name_x = xParam.axisLabels;
% xpos(1) = 0.8;
% for k=2:numel(name_x)
%     xpos(k) = xpos(k-1)+0.8; 
% end
% set(gca,'XTickLabel',name_x','XTickLabelRotation',45,'FontSize',10,'FontWeight','bold');

% X axis
if isfield(xParam,'barParam')
    barParam = xParam.barParam;
else
    barParam = 1;
end
xParam.axisLabels = strrep(strrep(strrep(xParam.axisLabels,'_',' '),',', ''),'-',' ');
xParam.tickLabelRotation = 90;
xParam.fontSize          = 8;
barChart(barParam).Parent.XTick              = 1:1:numel(xParam.axisLabels);
barChart(barParam).Parent.XTickLabel         = xParam.axisLabels;
barChart(barParam).Parent.XTickLabelRotation = xParam.tickLabelRotation;
barChart(barParam).Parent.FontSize           = xParam.fontSize;
if isfield(xParam,'lineWidth')
    barChart(barParam).LineWidth = xParam.lineWidth;
    barChart(barParam).EdgeColor = xParam.edgeColor;
end
% Y axis
yParam.fontSize   = 12;
ylabel(yParam.axisLabels, 'FontSize', yParam.fontSize);

% Legend
legParam.fontSize = 10;
if ~isfield(legParam,'location')
    legParam.location = 'best';
end
l = legend(legParam.title, 'Location', legParam.location);
l.FontSize = legParam.fontSize;

% Title
titParam.fontSize    = 12;
titParam.fontWeight  = 'Bold';
titParam.units       = 'normalized';
titParam.alignementH = 'center';
titParam.alignementV = 'bottom';

title(titParam.name, 'FontSize', titParam.fontSize, 'FontWeight', titParam.fontWeight, ...
    'Units', titParam.units, 'HorizontalAlignment', titParam.alignementH, 'VerticalAlignment', titParam.alignementV);

end
