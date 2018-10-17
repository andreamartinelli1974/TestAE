classdef AA_EqDesk_Final_UI < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        Backtest_GraphsUIFigure  matlab.ui.Figure
        UIAxes                   matlab.ui.control.UIAxes
        UIAxes2                  matlab.ui.control.UIAxes
        UIAxes3                  matlab.ui.control.UIAxes
        UIAxes4                  matlab.ui.control.UIAxes
        ExitButton               matlab.ui.control.Button
    end

    
    

    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            
            % chart 1
            if exist('Chart3.mat')
                load('Chart3.mat');
                
                app.UIAxes.Box = 'on';
                app.UIAxes.XGrid = 'on';
                app.UIAxes.YGrid = 'on';
                app.UIAxes.NextPlot = 'add';
                plot(app.UIAxes,Chart3.X,Chart3.Y1,'Color','r','LineWidth',3);
                plot(app.UIAxes,Chart3.X,Chart3.Y2);
                datetick(app.UIAxes,'x',28);
                %xlim(app.UIAxes,[min(Chart3.X) inf]);
                title(app.UIAxes, Chart3.Labels{1,3});
                xlabel(app.UIAxes, Chart3.Labels{1,1});
                ylabel(app.UIAxes, Chart3.Labels{1,2});
                legend(app.UIAxes, Chart3.legenda,'Location','southwest','Orientation','vertical','Interpreter','none','FontSize',7);
            end
            
            % chart 2
            if exist('Chart4.mat')
                load('Chart4.mat');
                
                app.UIAxes2.Box = 'on';
                app.UIAxes2.XGrid = 'on';
                app.UIAxes2.YGrid = 'on';
                app.UIAxes2.NextPlot = 'add';
                plot(app.UIAxes2,Chart4.X1,Chart4.Y1,'Color','r','LineWidth',3);
                plot(app.UIAxes2,Chart4.X2,Chart4.Y2,'o','Color','g','LineWidth',0.5);
                datetick(app.UIAxes2,'x',28);
                %xlim(app.UIAxes2,[min(Chart4.X1) inf]);
                title(app.UIAxes2, Chart4.Labels{1,3});
                xlabel(app.UIAxes2, Chart4.Labels{1,1});
                ylabel(app.UIAxes2, Chart4.Labels{1,2});
                legend(app.UIAxes2, Chart4.legenda,'Location','southwest','Orientation','vertical','Interpreter','none','FontSize',7);
            end
            
            % chart 3
            if exist('Chart5.mat')
                load('Chart5.mat');
                
                app.UIAxes3.Box = 'on';
                app.UIAxes3.XGrid = 'on';
                app.UIAxes3.YGrid = 'on';
                app.UIAxes3.NextPlot = 'add';
                plot(app.UIAxes3,Chart5.X,Chart5.Y);
                datetick(app.UIAxes3,'x',28);
                %xlim(app.UIAxes3,[min(Chart5.X) inf]);
                title(app.UIAxes3, Chart5.Labels{1,3});
                xlabel(app.UIAxes3, Chart5.Labels{1,1});
                ylabel(app.UIAxes3, Chart5.Labels{1,2});
                legend(app.UIAxes3, Chart5.legenda,'Location','southwest','Orientation','vertical','Interpreter','none','FontSize',7);
            end
            
            % chart 4
            if exist('Chart6.mat')
                load('Chart6.mat');
                
                app.UIAxes4.Box = 'on';
                app.UIAxes4.XGrid = 'on';
                app.UIAxes4.YGrid = 'on';
                app.UIAxes4.NextPlot = 'add';
                plot(app.UIAxes4,Chart6.X1,Chart6.Y1,'Linewidth',1);
                plot(app.UIAxes4,Chart6.X1,Chart6.Y2,'Linewidth',3);
                datetick(app.UIAxes4,'x',28);
                %xlim(app.UIAxes4,[min(Chart3.X) inf]);
                title(app.UIAxes4, Chart3.Labels{1,3});
                xlabel(app.UIAxes4, Chart3.Labels{1,1});
                ylabel(app.UIAxes4, Chart3.Labels{1,2});
                legend(app.UIAxes4, Chart3.legenda,'Location','southwest','Orientation','vertical','Interpreter','none','FontSize',7);
            end
            
        end

        % Button pushed function: ExitButton
        function ExitButtonPushed(app, event)
            app.delete
        end
        
        % Close request function: Backtest_GraphsUIFigure
        function Backtest_GraphsUIFigureCloseRequest(app, event)
            app.delete
        end
    end

    % App initialization and construction
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create Backtest_GraphsUIFigure
            app.Backtest_GraphsUIFigure = uifigure;
            app.Backtest_GraphsUIFigure.Color = [1 1 1];
            app.Backtest_GraphsUIFigure.Position = [20 150 1220 790];
            app.Backtest_GraphsUIFigure.Name = 'Backtest_Graphs';

            % Create UIAxes
            app.UIAxes = uiaxes(app.Backtest_GraphsUIFigure);
            title(app.UIAxes, 'Title')
            xlabel(app.UIAxes, 'X')
            ylabel(app.UIAxes, 'Y')
            app.UIAxes.NextPlot = 'add';
            app.UIAxes.Position = [20 432 580 340];

            % Create UIAxes2
            app.UIAxes2 = uiaxes(app.Backtest_GraphsUIFigure);
            title(app.UIAxes2, 'Title')
            xlabel(app.UIAxes2, 'X')
            ylabel(app.UIAxes2, 'Y')
            app.UIAxes2.Position = [623 432 580 340];

            % Create UIAxes3
            app.UIAxes3 = uiaxes(app.Backtest_GraphsUIFigure);
            title(app.UIAxes3, 'Title')
            xlabel(app.UIAxes3, 'X')
            ylabel(app.UIAxes3, 'Y')
            app.UIAxes3.Position = [20 53 580 340];

            % Create UIAxes4
            app.UIAxes4 = uiaxes(app.Backtest_GraphsUIFigure);
            title(app.UIAxes4, 'Title')
            xlabel(app.UIAxes4, 'X')
            ylabel(app.UIAxes4, 'Y')
            app.UIAxes4.Position = [623 53 580 340];

            % Create ExitButton
            app.ExitButton = uibutton(app.Backtest_GraphsUIFigure, 'push');
            app.ExitButton.ButtonPushedFcn = createCallbackFcn(app, @ExitButtonPushed, true);
            app.ExitButton.BackgroundColor = [0.6392 0.0784 0.1804];
            app.ExitButton.FontSize = 16;
            app.ExitButton.FontWeight = 'bold';
            app.ExitButton.FontColor = [1 1 1];
            app.ExitButton.Position = [560 12 100 26];
            app.ExitButton.Text = 'Exit';
        end
    end

    methods (Access = public)

        % Construct app
        function app = AA_EqDesk_Final_UI

            % Create and configure components
            createComponents(app)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.Backtest_GraphsUIFigure)
        end
    end
end