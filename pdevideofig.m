function fig_handle = pdevideofig(pdem, u, tlist, ...
                                additionalPostProcessing , f, play_fps)

% PDEVIDEOFIG - Figure with horizontal scrollbar and play capabilities that 
% facilitate viewing and postprocessing solutions of evolutionary PDEs.
% At each time step the user can rotate, pan or zoom the view and
% keep the viewing settings from frame to frame.

%   PDEVIDEOFIG(PDEM, U, TLIST)
%   Creates a figure with a horizontal scrollbar and shortcuts to scroll
%   automatically the solution U of the problem given in the structure PDEM. 
%   The scroll range is 1 to length(TLIST). 
%
%   The keyboard shortcuts are:
%     Space -- play/pause video (2 frames-per-second default).
%     P     -- play/pause video (2 frames-per-second default).
%     Right/left arrow keys -- advance/go back one frame.
%     F/B                   -- advance/go back one frame.
%     Home/End -- go to first/last frame of video.

%   Advanced usage
%   --------------
%   VIDEOFIG(PDEM, U, TLIST, ADDITIONALPOSTPROCESSING)
%   ADDITIONALPOSTPROCESSING is a handle to a function that specifies
%   additional commands that should be processed in order to edit the
%   default appearance of videofig plot.
%
%   VIDEOFIG(PDEM, U, TLIST, ADDITIONALPOSTPROCESSING, F)
%   F is the number of the frame the animation should start with.
% 
%   VIDEOFIG(PDEM, U, TLIST, ADDITIONALPOSTPROCESSING, F, PLAY_FPS)
%   PLAY_FPS specifies the speed of the play function (frames-per-second) 

%   Examples of usage in pdevideofig_examples.m
%   The code based on 

%   marbor, 2022


if nargin < 6
    play_fps = 2 ; % %play speed (frames per second)
end

if nargin < 5
    f = 1 ; % 
end

if nargin < 4
    % definition of 'do-nothing' function
    additionalPostProcessing = @(varargin) disp('') ; % 
end

% Time step number of the solution (number of frames of the animation)
[~, num_frames] = size(u) ;

if f > num_frames
    error('Number f cannot be larger than total number of time steps.')
end


fig_handle = figure() ;
% Figure callbacks: 
    set(fig_handle, 'DeleteFcn', @DeleteFcn_Callback) ;    
    % the following callbacks need to be reregistered in app_timer callback: 
    set(fig_handle, 'KeyPressFcn', @KeyPressFcn_Callback) ;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % app_timer callback is triggered periodically 
% % (i.e. every 2 seconds -> don't press keys too fast! or decrease app_timer.Period) 
% % in order to reregister keyboard callbacks more often.

app_timer = timer() ;
app_timer.Period = 2 ;
app_timer.ExecutionMode = 'fixedRate' ;
app_timer.TimerFcn = @RegisteringTimer_Callback; % Here is where you assign the callback function
% % timer = t; % Put the timer object inside handles so that you can stop it later
start(app_timer) ;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%timer to play the animation
play_timer = timer('TimerFcn',@PlayTimer_callback, 'ExecutionMode','fixedRate');


% main drawing axes for animation display
slider_height = 0.03 ; 

axes_handle = axes() ; 
pos = get(axes_handle, 'Position') ;
set(axes_handle, 'Position', [pos(1) pos(2)+slider_height ...
                              pos(3) pos(4)-slider_height] ) ;

slider_h = uicontrol('Parent',fig_handle,'Style','slider', ...
              'Units', 'normalized', 'Position',[0 0 1 slider_height],...
              'value',1, 'min',1, 'max',num_frames, ...
              'Callback', @slider_callback, ...
              'SliderStep', [1/num_frames 1]);

%% Initial plot (first frame) and initial settings

maxz = max(max(u)) ;
minz = min(min(u)) ;

redraw_func(pdem, u, tlist, 1) ;
view([0 90])
set(axes_handle, 'ZLim', [minz maxz] ) ;






%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Local functions and callbacks

    %% 
    function redraw_func(pdem, u, tlist, ti)
                
        pdeplot(pdem,'XYData',u(:,ti),'ZData',u(:,ti),'ZStyle','continuous','Mesh','off');
        % plot([1:ti], [1:ti] )  
        additionalPostProcessing(pdem, u, tlist, ti) ;
        ReregisterCallbacks() ;
    end

    %% Keyboard control callback
    function KeyPressFcn_Callback(src, event)  %#ok, unused arguments

        % disp('AAAAAAAAAA')
        % disp(event.Key)
        % disp('AAAAAAAAAA')

	    switch (event.Key)  %process shortcut keys

	    case 'f'           % forward            
		    scroll(f + 1);
        case 'rightarrow'  % forward
            scroll(f + 1);
	    case 'b'           % backward
		    scroll(f - 1);
        case 'leftarrow'   % backward
            scroll(f - 1);
    	case 'home'        % first frame
    		scroll(1);
    	case 'end'         % last frame   
    		scroll(num_frames);
     	case 'p'           % play/pause  
     		play(1/play_fps) ;  
        case 'space'       % play/pause  
     		play(1/play_fps) ;  
	    otherwise
            % do nothing
        end        
    end
    

    %% Scroll the animation

    function scroll(new_f)
        % Scroll to another (new_f) frame

	    if nargin == 1 
		    if new_f < 1 || new_f > num_frames
			    return
		    end
		    f = new_f;
	    end
	    	    
 	    % move slider bar to new position
        set(slider_h, 'Value', f ) ;

	    % set to the right axes and call the custom redraw function
	    set(fig_handle, 'CurrentAxes', axes_handle);

        % get axes limits and view angles ..
        xlimi = get(axes_handle,'XLim') ;
        ylimi = get(axes_handle,'YLim') ;
        zlimi = get(axes_handle,'ZLim') ;
        [az,el] = view ;
        
        % .. redraw ..
	    redraw_func(pdem, u, tlist, f) ;

        % .. and restore axes limits and view angles 
        view(az, el) ;
        set(axes_handle,'XLim', xlimi, 'YLim', ylimi, 'ZLim', zlimi) ;
        
	    %used to be "drawnow", but when called rapidly and the CPU is busy
	    %it didn't let Matlab process events properly (ie, close figure).
	    pause(0.001) 
        % drawnow()
    end
    
    %% Slider callback
	function slider_callback(hObject, event)		

        % TODO (?): continuous slider callback
        % https://www.mathworks.com/matlabcentral/answers/264979-continuous-slider-callback-how-to-get-value-from-addlistener

        newval = hObject.Value;             % get value from the slider
        newval = round(newval);             % round off this value
        set(hObject, 'Value', newval);      % set slider position to rounded off value

        new_f = get(slider_h, 'Value') ;        
		
		if new_f < 1 || new_f > num_frames, return; end  %outside valid range
		
		if new_f ~= f  % don't redraw if the frame is the same (to prevent delays)
			scroll(new_f);
		end
	end
    %% Movie player timer callback.

    % executed at each timer period, when playing the video
	function PlayTimer_callback(src, event) 

		if f < num_frames
			scroll(f + 1);
		elseif strcmp(get(play_timer,'Running'), 'on')
			stop(play_timer) ;  %stop the timer if the end is reached
		end
    end
    %% Function 'play' toggles between stopping and starting the "play video" timer

	function play(period)		   
        
        % Accuracy of timer() period is up to milliseconds. In order to
        % avoid warning messages in command line we need to round 
        % the given period.
        period = round(period, 3) ;

		if strcmp(get(play_timer,'Running'), 'off')
			set(play_timer, 'Period', period);
			start(play_timer);
		else
			stop(play_timer);
        end
    end


    %% Application timer callback 

    % Timer callback is triggered periodically in order to reregister
    % keyboard callbacks.
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % A workaround based on:
    % https://undocumentedmatlab.com/articles/enabling-user-callbacks-during-zoom-pan

    % Synopsis: In some cases Matlab disables figure callbacks. 
    % (In our case, each time pdeplot is called KeyPressFcn callback stops working,
    % while using plot function does not end with this behaviour). 
    % In order to re-register them again we need to run the following: 

    function RegisteringTimer_Callback(source,event)
        ReregisterCallbacks() ;
    end

    %% Reregistering keyboard callback. 
    % This function is triggered in RegisteringTimer_Callback and after
    % each redraw function.

    function ReregisterCallbacks()
        hManager = uigetmodemanager(fig_handle);
        try
            set(hManager.WindowListenerHandles, 'Enable', 'off');  % HG1
        catch
            [hManager.WindowListenerHandles.Enabled] = deal(false);  % HG2
        end
        set(fig_handle, 'KeyPressFcn', @KeyPressFcn_Callback) ; 
    end

    %% Delete figure callback
    function DeleteFcn_Callback(hObject, eventdata)        
        % Stop and delete the timers when closing the figure.                
        if strcmp(app_timer.Running, 'on')
            stop(app_timer) ;
        end
        if strcmp(play_timer.Running, 'on')
            stop(play_timer) ;
        end

        delete(timerfind)
        % disp('Timers stopped and deleted.')
    end
    %%

end % ENDOF evomovfig function

