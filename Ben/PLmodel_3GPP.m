% The path loss model is defined by 3GPP TR 36.814 outdoor model 1
% Carrier frequency = 2 ghz
% UE speed 3 km/h

function pl = PLmodel_3GPP(d, type)
    d_km = d/1000;                                                         % [KiloMeter]
    
    if(type == 'M')
    	% if d_km < 0.035                                                    % Min DIST btwn Macro and UE is 35 m (2016.10.27)
    	% 	d_km = 0.035;
    	% end
        pl = 128.1 + 37.6*log10(d_km);                                     % MacroCell Path Loss Model
    elseif(type == 'P')
    	% if d_km < 0.01                                                     % Min DIST btwn Pico and UE is 10 m (2016.10.27)
    	% 	d_km = 0.01;
    	% end
        pl = 140.7 + 36.7*log10(d_km);                                     % PicoCell Path Loss Model
    else
        disp('path loss model1 by 3gpp set error');
        pl = 0;
    end
end