classdef SubjectiveViews < handle
    % the purpose of this class is to generate a structure SubjViews
    % containing the subjective views properties that will be used within
    % objects of class Universe
    
    properties (SetAccess = immutable)
        ScenariosToRun;
    end
    
    methods
        function S = SubjectiveViews(AllSingleViews,ScenariosStructures) % SubjViewSpecifications)
            
            NumberOfScenarios = numel(ScenariosStructures);
            
            for scenario=1:NumberOfScenarios % FOR EACH SCENARIO THAT WE WANT TO RUN (AND GET RELATED OUTPUT)
                % AllViewsLabel is a strjoin of all single assets views, used for reports (Enrico).
                AllViewsLabel = '';
                % Label coming from GUI (or from AA_main)
                ScenarioLabel = fieldnames(ScenariosStructures{scenario}); 
                ScenarioLabel = ScenarioLabel{1};
                Scenarios{scenario} = ScenariosStructures{scenario}.(ScenarioLabel);
                %tmpLabel = '';
                clear SubjViews;
                
                Subjects = fieldnames(Scenarios{scenario});
				% Subjects contains "FieldsFromUser" field coming from scenario, here it is removed
                Subjects(find(strcmp(Subjects,'FieldsFromUser'),1))=[];
                NumberOfSubjects = numel(Subjects);
                
                for subj=1:NumberOfSubjects % FOR EACH ONE OF THE SUBJECTS EXPRESSING VIEWS within the scenario-th scenario
                    viewName = fieldnames(Scenarios{scenario}.(Subjects{subj}));
                    viewName = viewName{1};
                    noOfViews = numel(Scenarios{scenario}.(Subjects{subj}).(viewName));
                    %tmpLabel=strjoin([{tmpLabel},strjoin(views)]); %strjoin(tmpLabel{:},strjoin(views));
                    
                    for k=1:noOfViews % FOR EACH VIEW GIVEN BY THE subj-th subject the scenario-th scenario
                        currentView = strtrim(Scenarios{scenario}.(Subjects{subj}).(viewName){k});
                        AllViewsLabel = strjoin({currentView,AllViewsLabel},', ');
                        Observable = cell2mat( AllSingleViews{ currentView,'Observable' } );
                        
                        try
                            nextView = size(SubjViews.(Subjects{subj}).(Observable),1) + 1;
                        catch stillNoViews
                            if strcmp(stillNoViews.identifier,'MATLAB:UndefinedFunction') ...
                                    | strcmp(stillNoViews.identifier,'MATLAB:nonExistentField') ...
                                    | strcmp(stillNoViews.identifier,'MATLAB:refClearedVar') ...
                                    | strcmp(stillNoViews.identifier,'MATLAB:undefinedVariable')
                                nextView = 1; % when it is the first view for the Subject/Observable pair
                            end
                        end
                        if strcmp(Observable,'Mu')
                            SubjViews.(Subjects{subj}).(Observable){nextView,1} = cell2mat(AllSingleViews{currentView,'First_ticker'} );
                            SubjViews.(Subjects{subj}).(Observable){nextView,2} = AllSingleViews{currentView,'Value'};
                            SubjViews.(Subjects{subj}).(Observable){nextView,3} = cell2mat(AllSingleViews{currentView,'Condition'} );
                            
                        elseif strcmp(Observable,'Corr')
                            
                            SubjViews.(Subjects{subj}).(Observable){nextView,1} = cell2mat(AllSingleViews{currentView,'First_ticker'} );
                            SubjViews.(Subjects{subj}).(Observable){nextView,2} = cell2mat(AllSingleViews{currentView,'Second_ticker'} );
                            SubjViews.(Subjects{subj}).(Observable){nextView,3} = AllSingleViews{currentView,'Value'};
                            SubjViews.(Subjects{subj}).(Observable){nextView,4} = table2array(AllSingleViews{currentView,'Condition'} );
                            
                        else
                            error(['The observable name must be "Mu" or "Corr": view on ' j '-th asset not built']);
                        end
                        
                    end
                    
                end % looping over #NumberOfSubjects for given scenario
                S.ScenariosToRun(scenario).SubjViews = SubjViews;
                S.ScenariosToRun(scenario).Label =  ScenarioLabel;
                % Remove last comma and space from AllViewsLabel
                AllViewsLabel = AllViewsLabel(1:(end-2));
                 % Sort the views in alphanumeric order
                % 1) it splits AllViewsLabel using ', ' as delimiter
                % 2) it sorts the resulting cell array
                % 3) it joins the sorted cell array using ', ' as delimiter
                AllViewsLabel = strjoin(sort(split(AllViewsLabel, ', ')), ', ');
                S.ScenariosToRun(scenario).AllViewsLabel = AllViewsLabel;
                S.ScenariosToRun(scenario).NumberOfSubjects = NumberOfSubjects;
                % to give equal weight to all the subjects expressing views
                % (otherwise single values can be setup)
                S.ScenariosToRun(scenario).SubjectiveViewsWeight = [];
                % ** ConfInSubjViews = [];
            end % looping over #NumberOfScenarios
            
      
            
            % to give equal weight to all the subjects expressing views
            % (otherwise single values can be setup)
            % ** ConfInSubjViews = ones(1,S.NumberOfSubjects)./S.NumberOfSubjects;
            % ConfInSubjViews = [];
            
            % WARNING: by default this field is left empty and in the
            % obj of class Universe performing the dynamic AA its own
            % field  (e.g. DAA_params.SubjectiveViewsWeight;) will be
            % used to assign a global weight to subj views, that will
            % be divided equaly between the subjects expressing views
            % IF IT IS NECESSARY TO ATTRIBUTE DIFFERENT (THAN EQUAL)
            % WEIGHTS DO IT BELOW
        end % SubjectiveViews method
        
    end % public methods
    
end % class definition


% OLD SETS of SUBJ VIEWS USED
% ***********************************************************
%  % BREMAIN
%  % ***********************************************************
%  % Stefano
%  SubjViews.S.Mu{1,1} = ['VG1 Index']; SubjViews.S.Mu{1,2} = [0.0263];
%  SubjViews.S.Mu{2,1} = ['ES1 Index']; SubjViews.S.Mu{2,2} = [0.0050];
%  SubjViews.S.Mu{3,1} = ['UX1 Index']; SubjViews.S.Mu{3,2} = [-0.0926];
%  SubjViews.S.Mu{4,1} = ['V2X Index']; SubjViews.S.Mu{4,2} = [-0.0694];
%  % Gianluca
%  SubjViews.G.Mu{1,1} = ['VG1 Index'];  SubjViews.G.Mu{1,2} = [0.0238];
%  SubjViews.G.Mu{2,1} = ['ES1 Index'];  SubjViews.G.Mu{2,2} = [0.0118];
%  SubjViews.G.Mu{3,1} = ['UX1 Index'];  SubjViews.G.Mu{3,2} = [-0.0926];
%  SubjViews.G.Mu{4,1} = ['V2X Index'];  SubjViews.G.Mu{4,2} = [-0.0694];
%  SubjViews.G.Mu{5,1} = ['EC1 Curncy']; SubjViews.G.Mu{5,2} = [-0.0049];
%  % Riccardo
%  SubjViews.R.Mu{1,1} = ['VG1 Index'];     SubjViews.R.Mu{1,2} = [0.05];
%  SubjViews.R.Mu{2,1} = ['ES1 Index'];     SubjViews.R.Mu{2,2} = [0.025];
%  SubjViews.R.Mu{3,1} = ['TP1 Index'];     SubjViews.R.Mu{3,2} = [0.05];
%  SubjViews.R.Mu{4,1} = ['UX1 Index'];     SubjViews.R.Mu{4,2} = [-0.055];
%  SubjViews.R.Mu{5,1} = ['V2X Index'];     SubjViews.R.Mu{5,2} = [-0.0694];
%  SubjViews.R.Mu{6,1} = ['EC1 Curncy'];    SubjViews.R.Mu{6,2} = [0.0075];
%  SubjViews.R.Mu{7,1} = ['JY1 Curncy'];    SubjViews.R.Mu{7,2} = [-0.0125];
%  SubjViews.R.Mu{8,1} = ['USDTRY Curncy']; SubjViews.R.Mu{8,2} = [-0.0125];
%  SubjViews.R.Mu{9,1} = ['TY1 Comdty'];    SubjViews.R.Mu{9,2} = [-0.0039];
%  SubjViews.R.Mu{10,1} = ['RX1 Comdty'];   SubjViews.R.Mu{10,2} = [-0.0055];
%
%  SubjViews.R.Corr{1,1} = ['VG1 Index'];  SubjViews.R.Corr{1,2} = ['ES1 Index']; SubjViews.R.Corr{1,3} = [0.60];
%  % Edoardo
%  SubjViews.E.Mu{1,1} = ['VG1 Index'];    SubjViews.E.Mu{1,2} = [0.0535];
%  % Pier
%  SubjViews.P.Mu{1,1} = ['VG1 Index'];    SubjViews.P.Mu{1,2} = [0.0155];
%  SubjViews.P.Mu{2,1} = ['ES1 Index'];    SubjViews.P.Mu{2,2} = [0.0132];
%  SubjViews.P.Mu{3,1} = ['TP1 Index'];    SubjViews.P.Mu{3,2} = [0.0300];
%  SubjViews.P.Mu{4,1} = ['EC1 Curncy'];   SubjViews.P.Mu{4,2} = [0.0020];

% SubjViews.EqDesk.Mu{1,1} = ['SXEP Index'];       SubjViews.S.Mu{1,2} = [0.07]; SubjViews.S.Mu{1,3} = ['>'];
% SubjViews.EqDesk.Mu{2,1} = ['SX3P Index'];       SubjViews.S.Mu{2,2} = [-0.03]; SubjViews.S.Mu{2,3} = ['<'];
% SubjViews.EqDesk.Mu{3,1} = ['SXKP Index'];       SubjViews.S.Mu{3,2} = [0.04]; SubjViews.S.Mu{3,3} = ['>'];
% SubjViews.EqDesk.Mu{4,1} = ['SX7P Index'];       SubjViews.S.Mu{4,2} = [0.05]; SubjViews.S.Mu{4,3} = ['>'];
%
% % flat ER views **
% SubjViews.EqDesk.Mu{5,1} = ['XLY US Equity'];    SubjViews.S.Mu{5,2} = [0.01]; SubjViews.S.Mu{5,3} = ['<'];
% SubjViews.EqDesk.Mu{6,1} = ['SXPP Index'];       SubjViews.S.Mu{6,2} = [0.01]; SubjViews.S.Mu{6,3} = ['<'];
% SubjViews.EqDesk.Mu{7,1} = ['SXIP Index'];       SubjViews.S.Mu{7,2} = [0.01]; SubjViews.S.Mu{7,3} = ['<'];
% SubjViews.EqDesk.Mu{8,1} = ['SX6P Index'];       SubjViews.S.Mu{8,2} = [0.01]; SubjViews.S.Mu{8,3} = ['<'];
% % ***************
% SubjViews.EqDesk.Mu{9,1} = ['XLY US Equity'];    SubjViews.S.Mu{9,2} = [-0.01]; SubjViews.S.Mu{9,3} = ['>'];
% SubjViews.EqDesk.Mu{10,1} = ['SXPP Index'];      SubjViews.S.Mu{10,2} = [-0.01]; SubjViews.S.Mu{10,3} = ['>'];
% SubjViews.EqDesk.Mu{11,1} = ['SXIP Index'];      SubjViews.S.Mu{11,2} = [-0.01]; SubjViews.S.Mu{11,3} = ['>'];
% SubjViews.EqDesk.Mu{12,1} = ['SX6P Index'];      SubjViews.S.Mu{12,2} = [-0.01]; SubjViews.S.Mu{12,3} = ['>'];

