% ============================= %
% ?��??�己要�?UE Location Model %
% ============================= %
% ?�己?��??�種就�?注解?��???

% ----------------- %
% System Initialize %
% ----------------- %
edge = 4763;       % 系統?��???[m]
n_UE = 400;        % UE ?�數??


% ----------- %
% 位置?��??? %
% ----------- %
% UE_location = zeros(n_UE, 2); % Pico Cell ?��?�?
% 
% x = (rand(n_UE,1)-0.5)*edge;
% y = (rand(n_UE,1)-0.5)*edge;
% 
% UE_location = [x,y];
% 
% save UE_lct_n400_random UE_location




% ----------------- %
% ?�中?�中?��??��?  %
% ----------------- %
UE_location = zeros(n_UE, 2); % Pico Cell ?��?�?

central_part = 10;  % ?��???0 
% EX:
%    central_part = 5
%    表示??/10?�UE?�在中�?

% UE??/4?�在中�?
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