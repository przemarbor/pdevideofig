function additionalPostProcessing(pdem, u, tlist, ti)

colormap(jet) 
colorbar
xlabel('x')
ylabel('y')

%% Constant mapping of colors in colorbar during the animation 
umax = max(max(u)) ;
umin = min(min(u)) ;

scale = 1 ;
set(gca, 'clim', [umin umax]*scale);

%% Information about the time of the animation
sformat = '%.3f' ;
title( ['Time: ' sprintf(sformat, tlist(ti)) ' s']  )

%% Additional posprocessing information
temp = max(max(u(:,ti))) - min(min(u(:,ti))) ;
fprintf('-----------------------------\n') ;
fprintf('The difference between max and min for t_i = %.3fs is %.3f.\n', tlist(ti), temp) ;