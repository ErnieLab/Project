% ============================= %
% ?¢Á??™Â∑±Ë¶ÅÁ?UE Location Model %
% ============================= %
% ?™Â∑±?≥Ë??™Á®ÆÂ∞±Ê?Ê≥®Ëß£?ñÊ???

% ----------------- %
% System Initialize %
% ----------------- %
edge = 4763;       % Á≥ªÁµ±?ÑÈ???[m]
n_UE = 400;        % UE ?ÑÊï∏??


% ----------- %
% ‰ΩçÁΩÆ?Ø‰??? %
% ----------- %
% UE_location = zeros(n_UE, 2); % Pico Cell ?Ñ‰?ÁΩ?
% 
% x = (rand(n_UE,1)-0.5)*edge;
% y = (rand(n_UE,1)-0.5)*edge;
% 
% UE_location = [x,y];
% 
% save UE_lct_n400_random UE_location




% ----------------- %
% ?Ü‰∏≠?®‰∏≠?ìÁ??∫Ê?  %
% ----------------- %
UE_location = zeros(n_UE, 2); % Pico Cell ?Ñ‰?ÁΩ?

central_part = 10;  % ?ÜÊ???0 
% EX:
%    central_part = 5
%    Ë°®Á§∫??/10?ÑUE?∫Âú®‰∏≠È?

% UE??/4?∫Âú®‰∏≠È?
x_1 = (rand(n_UE*central_part/10,1)-0.5)*(edge/2);
y_1 = (rand(n_UE*central_part/10,1)-0.5)*(edge/2);


x_2 = (rand(n_UE*(10 - central_part)/10,1)-0.5)*(edge);
y_2 = (rand(n_UE*(10 - central_part)/10,1)-0.5)*(edge);

x   = [x_1; x_2];
y   = [y_1; y_2];

UE_location = [x,y];

save UE_lct_n400_centralize UE_location




figure(), hold on;
plot(UE_location(:,1), UE_location(:,2), '*', 'Color',[0.8 0.0 0.2],'MarkerSize',5);
plot([+1,-1,-1,+1,+1]*edge/2, [+1,+1,-1,-1,+1]*edge/2, 'Color', [0.3 0.3 0.0]);
title('Beginning');
legend('User');
set(gcf,'numbertitle','off');
set(gcf,'name','Environment');