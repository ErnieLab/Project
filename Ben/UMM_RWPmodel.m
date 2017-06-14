%%  User Mobility Model : Random Waypoint Model
% Literature: === A Survey of Mobility Model Ch1 ===
% As the simulation starts, each mobile node randomly selects 
% one location in the simulation field as the destination. 
% It then travels towards this destination with constant velocity 
% chosen uniformly and randomly from 0 to V_MAX.

% 40[m/s] = 144[km/hr]
% 20[km/hr]  =  5.5556[m/s];  40[km/hr] = 11.1111[m/s];  60[km/hr] = 16.6667[m/s];  80[km/hr] = 22.2222[m/s]; 
% 100[km/hr] = 27.7778[m/s]; 120[km/hr] = 33.3333[m/s]; 140[km/hr] = 38.8889[m/s]; 160[km/hr] = 44.4444[m/s];

%% Abbreviation
% BF : Border Effect
% DEST : Destination
% DGNI : Directly Given, No Initialization

function [lct_new, v_new, t_oneStep_new] = UMM_RWPmodel(type, idx_t, t_start, lct_old, UE_timer_oneStep, ...
                                                        t_d, rectEdge, v_old, seedSpeed, seedAngle, seedEachStepOfTIME)

    % V_MAX =  1;       % 3.6[km/hr]
    % V_MAX =  5.5556;  %  20[km/hr]
    % V_MAX = 11.1111;  %  40[km/hr]
    % V_MAX = 16.6667;  %  60[km/hr]
    % V_MAX = 22.2222;  %  80[km/hr]
    % V_MAX = 27.7778;  % 100[km/hr]
    V_MAX = 33.3333;  % 120[km/hr]
    % V_MAX = 38.8889;  % 140[km/hr]
    % V_MAX = 44.4444;  % 160[km/hr]
    % V_MAX = 50;       % 180[km/hr]
    % V_MAX = 55.5556;  % 200[km/hr]
    
    % = UE change DIRC uniform distribution btwn Move_Max/10 and Move_MAX/2 =
    Move_MAX = 30;                                                              % [meter]
    
    % === Significant ADJ ===
%     t_d = t_d * 1e-03;
%     V_MAX = V_MAX * 1e-03;                                                    % 40[m/s] = 0.04[m/msec]
    
    % === When the Simulation Beginning ===
    if (idx_t == t_start)                                                       % When Simulation time = 1[msec]
        % --- Given Initial DESTination ---
        % theta = rand(1)*2*pi;                                                   % Angle [rad]
        theta = seedAngle * 2 * pi;                                                   % 2016.11.17

        % === fixed or valuable velocity? === % 0711
        switch type
            case 'I'    % Invariable Velocity
                speed = V_MAX;
            case 'V'    % Variable Velocity
                % speed = rand(1)*V_MAX;                                          % [m/s]
                speed = seedSpeed * V_MAX;                                          % 2016.11.17
                if speed < 1
                    speed = 1; % Avoid velocity less than 1, result in huge ToS
                end
        end
        % speed = V_MAX;
        % === fixed or valuable velocity? ===

        v_old(1) = speed*cos(theta);
        v_old(2) = speed*sin(theta);
        
        t_oneStep_new = 0;
        while(t_oneStep_new == 0)
            % t_oneStep_new = randi([Move_MAX/10 Move_MAX/2],1);                  % one step timer duration (DGNI)
            t_oneStep_new = seedEachStepOfTIME;                                       % 2016.11.17
        end
        
        % --- Update UE Location ---
        lct_new(1) = lct_old(1) + v_old(1)*t_d;
        lct_new(2) = lct_old(2) + v_old(2)*t_d;
        if (lct_new(1) > rectEdge/2)
            lct_new(1) = rectEdge - lct_new(1);
            v_new(1) = -v_old(1);
        elseif (lct_new(1) < -rectEdge/2)
            lct_new(1) = -rectEdge - lct_new(1);
            v_new(1) = -v_old(1);
        else
            v_new(1) = v_old(1);
        end
        if (lct_new(2) > rectEdge/2)
            lct_new(2) = rectEdge - lct_new(2);
            v_new(2) = -v_old(2);
        elseif (lct_new(2) < -rectEdge/2)
            lct_new(2) = -rectEdge - lct_new(2);
            v_new(2) = -v_old(2);
        else
            v_new(2) = v_old(2);
        end 
        
    % === User is moving and not arriving DEST yet ===
    elseif (UE_timer_oneStep ~= 0)
        % --- Keep Going to DESTination ---
%         lct_DEST = RWP_DEST;
        t_oneStep_new = UE_timer_oneStep;
        % --- Update UE Location ---
        lct_new(1) = lct_old(1) + v_old(1)*t_d;
        lct_new(2) = lct_old(2) + v_old(2)*t_d;
        if (lct_new(1) > rectEdge/2)
            lct_new(1) = rectEdge - lct_new(1);
            v_new(1) = -v_old(1);
        elseif (lct_new(1) < -rectEdge/2)
            lct_new(1) = -rectEdge - lct_new(1);
            v_new(1) = -v_old(1);
        else
            v_new(1) = v_old(1);
        end
        if (lct_new(2) > rectEdge/2)
            lct_new(2) = rectEdge - lct_new(2);
            v_new(2) = -v_old(2);
        elseif (lct_new(2) < -rectEdge/2)
            lct_new(2) = -rectEdge - lct_new(2);
            v_new(2) = -v_old(2);
        else
            v_new(2) = v_old(2);
        end
    
    % === User is moving and arriving DEST ===
    elseif (UE_timer_oneStep == 0)   
        % --- Given New DESTination New Velocity New Direction ---
        % theta = rand(1)*2*pi;                                                   % Angle [rad]
        theta = seedAngle * 2 * pi;                                                   % 2016.11.17
        switch type
            case 'I'
                speed = V_MAX;
            case 'V'
                % speed = rand(1)*V_MAX;                                          % [m/s]
                speed = seedSpeed*V_MAX;                                          % 2016.11.17
                if speed < 1
                    speed = 1; % Avoid velocity less than 1, result in huge ToS
                end
        end
        v_old(1) = speed*cos(theta);
        v_old(2) = speed*sin(theta);    
        
        t_oneStep_new = 0;
        while(t_oneStep_new == 0)
            % t_oneStep_new = randi([Move_MAX/10 Move_MAX/2],1);                    % one step timer duration (DGNI)
            t_oneStep_new = seedEachStepOfTIME;
        end
        
        % --- Update UE Location ---
        lct_new(1) = lct_old(1) + v_old(1)*t_d;
        lct_new(2) = lct_old(2) + v_old(2)*t_d;
        if (lct_new(1) > rectEdge/2)
            lct_new(1) = rectEdge - lct_new(1);
            v_new(1) = -v_old(1);
        elseif (lct_new(1) < -rectEdge/2)
            lct_new(1) = -rectEdge - lct_new(1);
            v_new(1) = -v_old(1);
        else
            v_new(1) = v_old(1);
        end
        if (lct_new(2) > rectEdge/2)
            lct_new(2) = rectEdge - lct_new(2);
            v_new(2) = -v_old(2);
        elseif (lct_new(2) < -rectEdge/2)
            lct_new(2) = -rectEdge - lct_new(2);
            v_new(2) = -v_old(2);
        else
            v_new(2) = v_old(2);
        end   
    end
end