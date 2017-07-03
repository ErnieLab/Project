% =========================== %
% ?¢Á??™Â∑±Ë¶ÅÁ?Pico Cell Model %
% =========================== %

% ----------------- %
% System Initialize %
% ----------------- %
load('MC_lct_4sq');	 % ?äMacro?Ñ‰?ÁΩÆË??≤‰?ÔºåË??∏Â?Á®±ÁÇ∫:  Macro_location

edge   = 4763;       % Á≥ªÁµ±?ÑÈ???[m]
n_Pico = 250;        % Pico Cell ?ÑÊï∏??

% ----- %
% Start %
% ----- %
Pico_location = zeros(n_Pico, 2);                 % Pico Cell ?Ñ‰?ÁΩ?
d_PCMC        = zeros(length(Macro_location), 1); % PicoË∑üMacro?ÑË???

% ?àÊì∫??0?ãPico?≤‰?ÔºåÊñπ‰æøÂ?ÂßãÂ?Ë®àÁ?ÂΩºÊ≠§Ë∑ùÈõ¢??
Pico_location(1,:) = [ 2268, 2268];
Pico_location(2,:) = [    0, 2268];   
Pico_location(3,:) = [-2268, 2268];   
Pico_location(4,:) = [ 2268,    0];  
Pico_location(5,:) = [    0,    0];   
Pico_location(6,:) = [-2268,    0];  
Pico_location(7,:) = [ 2268,-2268];   
Pico_location(8,:) = [    0,-2268];   
Pico_location(9,:) = [-2268,-2268];   

% ?ãÊ≠§?∫ÊîæPico Cell
for Pico_index = 10:1:n_Pico
	Pico_location(Pico_index, 1) = (rand - 0.5)*edge;
	Pico_location(Pico_index, 2) = (rand - 0.5)*edge;

	for Macro_index = 1:1:length(Macro_location)
		d_PCMC(Macro_index, 1) = norm(Pico_location(Pico_index,:) - Macro_location(Macro_index,:));
	end
	min_d_PCMC = min(d_PCMC);

	for Pico_check_index = 1:1:(Pico_index-1)
		d_PCPC(Pico_check_index, 1) = norm(Pico_location(Pico_index,:) - Pico_location(Pico_check_index,:));
	end
	mid_d_PCPC = min(d_PCPC);

	while(min_d_PCMC < 75 || mid_d_PCPC < 40 ) % min_d_PCMC: PicoË∑üMacro?ÑË??¢È???  mid_d_PCPC: PicoË∑üPico?ÑË??¢È???
		                                       % 3GPP?ÑPPP model?ÉÊï∏??min_d_PCMC < 75 || mid_d_PCPC < 40)
		Pico_location(Pico_index, 1) = (rand - 0.5)*edge;
		Pico_location(Pico_index, 2) = (rand - 0.5)*edge;

		for Macro_index = 1:1:length(Macro_location)
			d_PCMC(Macro_index, 1) = norm(Pico_location(Pico_index,:) - Macro_location(Macro_index,:));
		end
		min_d_PCMC = min(d_PCMC);

		for Pico_check_index = 1:1:(Pico_index-1)
			d_PCPC(Pico_check_index, 1) = norm(Pico_location(Pico_index,:) - Pico_location(Pico_check_index,:));
		end
		mid_d_PCPC = min(d_PCPC);
	end
end


figure(), hold on;
plot(Macro_location(:,1), Macro_location(:,2), 'sk', 'MarkerFaceColor', 'k','MarkerSize',10);
plot(Pico_location(:,1), Pico_location(:,2), '^k', 'MarkerFaceColor', 'g','MarkerSize', 5);
plot([+1,-1,-1,+1,+1]*edge/2, [+1,+1,-1,-1,+1]*edge/2, 'Color', [0.3 0.3 0.0]);
title('Beginning');
legend('Macrocell','Picocell','User');
set(gcf,'numbertitle','off');
set(gcf,'name','Environment');

% ?•‰?‰æÜË?Ëº∏Âá∫Pico Cell?Ñ‰?ÁΩ?
% ‰∏??Ë¶ÅÊ≥®?èÂëΩ?ç‰?ÂÆöË?Ë∑ücode?ÑÂ??∏Á¨¶?àÔ?‰∏??Ë¶ÅÈ?Â∏∏Ê≥®??!!!!!!!!!!!!!!

% Â¶ÇÊ??ØÁÖß3GPP?ÑÀäPPP model?∫ÊîæÔºåÂëΩ?çÁÇ∫: PC_lct_4sq_nXXX_random

save PC_lct_4sq_n250_random Pico_location




% Â¶ÇÊ??ØËá™Â∑±Á?modelÔºåÂëΩ?çË??áÂ?‰∏ãÔ?

%                   PicoË∑üPico‰πãÈ??≥Â?Ë¶?0m
%                             |
%               Pico 300??   |
%                   |         |
%                   v         v
% save PC_lct_4sq_n250_MP520_PP40 Pico_location
%        ^     ^         ^
%        |     |         |
%     Pico‰ΩçÁΩÆ |         |
%              |         |
%           Macro?∫Êîæ    |
%                        |
%             MacroË∑üMacro‰πãÈ??≥Â?Ë¶?00m