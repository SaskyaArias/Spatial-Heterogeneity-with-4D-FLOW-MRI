function []=strain_plot_v2Siemens(data,stdev,units,suffix,limits,dt)

    
color=[0.9,0,0;0,0.7,0;0,0,0.95];
t = [0:dt:dt*(size(data,1)-1)];
t_int = [0:dt/10:dt*(size(data,1)-1)];

        figure
        hold on
        intData = interp1(1:size(data,1),data(:,1),1:0.1:size(data,1),'spline');
        p1=plot(t_int,intData,'-','Color',color(:,3));
        p12=plot(t,data(:,1),'.','Color',color(:,3));
        
        ylabel(units,'Interpreter','latex','FontSize',16)
        filename=[suffix,'.eps'];

        ylim(limits)
        


        errorbar(t,data(:,1),stdev(:,1),'.','Color',color(:,3));

        xlabel('$time \quad [\mathrm{s}]$','Interpreter','latex','FontSize',16)
        %title(ID,'Interpreter','latex');

        xlim([0 dt*(size(data,1)+1)])
        set(gcf,'color','w');
        set(gca,'TickLabelInterpreter','latex','FontSize',14);
       
        
        export_fig(filename,'-eps');
        hold off
        close
        
        
end