function []=vepcGIFcmaps(m,d,suffix,limits,units)

filename=[suffix,'.gif'];
figure('Position',[10,10,300,300],'color','k')

for n = 1:24 %%look at horos the total amount of images/ #of contractions
      


     M=squeeze(m(:,:,n));
    D=squeeze(d(:,:,n));


    ax1 = axes;
    imagesc(M)
    colormap(ax1,'gray');
    daspect([1 1 1])
    h=gca;
    h.Visible="off";

    ax2 = axes;
    imagesc(ax2,D,'alphadata',0.2);

    cmap=jet(301);

    if limits(1)==0
        cmap(1,:) = 0;
    elseif limits(1)<0 && limits(2)>0
        cmap(151,:) = 0;
    elseif limits(1)<0 && limits(2)==0
        cmap(end,:) =0;
    end    


    colormap(ax2,cmap);
    caxis(ax2,[limits(1) limits(2)]);
    h=gca;
    h.Visible="off";
    daspect([1 1 1])
    linkprop([ax1 ax2],'Position');

    c=colorbar;
    x1=get(gca,'position');
    x=get(c,'Position');
    x(3)=x(3); % half the size
    set(c,'Position',x)
    set(gca,'position',x1)

    ylabel(c, units,'fontsize',12,'interpreter','latex','color','white')
    c.Color = 'w';
    c.TickLabelInterpreter='latex';
    c.Limits = [limits(1) limits(2)];
    
    
    frame = getframe(1);
    im = frame2im(frame);
      
    [imind,cm] = rgb2ind(im,256);
      if n == 1;
          imwrite(imind,cm,filename,'gif', 'DelayTime',0.1,'Loopcount',inf);
      else
          imwrite(imind,cm,filename,'gif','DelayTime',0.1,'WriteMode','append');
      end
      
      
end

close all

end