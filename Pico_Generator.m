% =========================== %
% ?��??�己要�?Pico Cell Model %
% =========================== %

% ----------------- %
% System Initialize %
% ----------------- %
load('MC_lct_4sq');	 % ?�Macro?��?置�??��?，�??��?稱為:  Macro_location

edge   = 4763;       % 系統?��???[m]
n_Pico = 250;        % Pico Cell ?�數??

% ----- %
% Start %
% ----- %
Pico_location = zeros(n_Pico, 2);                 % Pico Cell ?��?�?
d_PCMC        = zeros(length(Macro_location), 1); % Pico跟Macro?��???

% ?�擺??0?�Pico?��?，方便�?始�?計�?彼此距離??
Pico_location(1,:) = [ 2268, 2268];
Pico_location(2,:) = [    0, 2268];   
Pico_location(3,:) = [-2268, 2268];   
Pico_location(4,:) = [ 2268,    0];  
Pico_location(5,:) = [    0,    0];   
Pico_location(6,:) = [-2268,    0];  
Pico_location(7,:) = [ 2268,-2268];   
Pico_location(8,:) = [    0,-2268];   
Pico_location(9,:) = [-2268,-2268];   

% ?�此?�放Pico Cell
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

	while(min_d_PCMC < 75 || mid_d_PCPC < 40 ) % min_d_PCMC: Pico跟Macro?��??��???  mid_d_PCPC: Pico跟Pico?��??��???
		                                       % 3GPP?�PPP model?�數??min_d_PCMC < 75 || mid_d_PCPC < 40)
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

% ?��?來�?輸出Pico Cell?��?�?
% �??要注?�命?��?定�?跟code?��??�符?��?�??要�?常注??!!!!!!!!!!!!!!

% 如�??�照3GPP?�ˊPPP model?�放，命?�為: PC_lct_4sq_nXXX_random

save PC_lct_4sq_n250_random Pico_location




% 如�??�自己�?model，命?��??��?下�?

%                   Pico跟Pico之�??��?�?0m
%                             |
%               Pico 300??   |
%                   |         |
%                   v         v
% save PC_lct_4sq_n250_MP520_PP40 Pico_location
%        ^     ^         ^
%        |     |         |
%     Pico位置 |         |
%              |         |
%           Macro?�放    |
%                        |
%             Macro跟Macro之�??��?�?00m