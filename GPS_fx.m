% Global Positioning System

function measured_ToS = GPS_fx(BS_lct, BS_r, UE_lct, UE_v)	% for all main.m
% function [measured_ToS, n_PP, n_PN, n_NN, n_CC] = GPS_fx(BS_lct, BS_r, UE_lct, UE_v)	% for 'pdf_predictedToS.m' only


	a = UE_v(1)^2 + UE_v(2)^2;
	b = 2 * (UE_lct(1)*UE_v(1) - BS_lct(1)*UE_v(1) + UE_lct(2)*UE_v(2) - BS_lct(2)*UE_v(2));
	c = (UE_lct(1)-BS_lct(1))^2 + (UE_lct(2)-BS_lct(2))^2 - BS_r^2;


	% d = fix(norm(BS_lct - UE_lct));
	% if fix(BS_r) == 1622
	% 	% fprintf('MacroCase: DIST = %d\n',d);
	% 	if (d > 1622)
	% 		fprintf('Out of the MC\n');
	% 	else
	% 		fprintf('Inside the MC\n');
	% 	end
	% elseif fix(BS_r) == 272
	% 	% fprintf('PicoCase:  DISTs = %d\n',d);
	% 	if (d > 272)
	% 		fprintf('Out of the PC\n');
	% 	else
	% 		fprintf('Inside the PC\n');
	% 	end
	% end


	if (b^2 - 4*a*c) < 0
		% disp('GPS Measured ToS is complex');
	end

	ToS_1 = (-b + sqrt(b^2-4*a*c)) / (2*a);
	ToS_2 = (-b - sqrt(b^2-4*a*c)) / (2*a);
	% disp(ToS_1);
	% disp(ToS_2);
	% fprintf('\n\n\n');

	% Two Positive
	if (ToS_1 > 0 && ToS_2 > 0 && imag(ToS_1) == 0 && imag(ToS_2) == 0)
		% disp('Two Measured ToS is positive');
		% disp(ToS_1);
		% disp(ToS_2);
		
		measured_ToS = abs(ToS_1 - ToS_2);

		n_PP = 1; n_PN = 0; n_NN = 0; n_CC = 0;

	% One Positive One Negative
	elseif (ToS_1 > ToS_2 && ToS_1 > 0)
		measured_ToS = ToS_1;
		n_PP = 0; n_PN = 1; n_NN = 0; n_CC = 0;

	% One Positive One Negative
	elseif (ToS_1 < ToS_2 && ToS_2 > 0)
		measured_ToS = ToS_2;
		n_PP = 0; n_PN = 1; n_NN = 0; n_CC = 0;

	% Two Negative	
	elseif (ToS_1 < 0 && ToS_2 < 0)
		measured_ToS = 0;
		% disp('GPS result:')
		% disp(ToS_1);
		% disp(ToS_2);
		n_PP = 0; n_PN = 0; n_NN = 1; n_CC = 0;

	% Two Complex	
	elseif (imag(ToS_1)~=0 && imag(ToS_2)~=0)
		measured_ToS = 0;
		n_PP = 0; n_PN = 0; n_NN = 0; n_CC = 1;

	% 2016.10.27 SSL Proposal	
	else 
		measured_ToS = 0;
	end
end