% Link Prediction Algorithm 2003

function pred_ToS = LPA_fx(GAMMA, P1, P2, P3, Ps, t2, t3, d2)

	% pred_ToS = zeros(2,1);

	p = 2/GAMMA;

	B = ( ((P1*P2)^p)*t2 + ((P2*P3)^p)*t3 - ((P1*P3)^p)*t3 - ((P2*P3)^p)*t2 ) / ( (t2*t3^2 - t2^2*t3)*((P2*P3)^p) ) ; 

	a = t2 * ((Ps*P2)^p) * B;
	b = (Ps^p) * ((P1^p - P2^p) - (t2^2)*(P2^p)*B);
	c = t2*((P2*Ps)^p) - t2*((P1*P2)^p);

	ToS_1 = (-b + sqrt(b^2-4*a*c)) / (2*a);
	ToS_2 = (-b - sqrt(b^2-4*a*c)) / (2*a);

	if (ToS_1 > ToS_2)
		% pred_ToS(1) = ToS_1;
		% pred_ToS(2) = ToS_2;
		pred_ToS = ToS_1;
	elseif (ToS_1 < ToS_2)
		% pred_ToS(1) = ToS_2;
		% pred_ToS(2) = ToS_1;
		pred_ToS = ToS_2;
	elseif (imag(ToS_1) ~= 0 && imag(ToS_2) ~= 0)
		d2 = d2;
		% disp('pred_ToS is complex number');
		% P1 = P1 * 1e+16; P2 = P2 * 1e+16; P3 = P3 * 1e+16; 
		% fprintf(' P1 = %d, P2 = %d, P3 = %d \n', P1,P2,P3);
		% if (GAMMA == 3.76)
		% 	if d2 >= 1622.2
		% 		disp('Outside of MC Coverage!!!');
		% 	else
		% 		disp('Inside of MC Coverage');
		% 	end
		% elseif (GAMMA == 3.67)
		% 	if d2 >= 272.8722
		% 		disp('Outside of PC Coverage!!!');
		% 	else
		% 		disp('Inside of PC Coverage');
		% 	end
		% end
		pred_ToS = 1i;

	else
		pred_ToS = 0;	% Actually pred_ToS is complex but I give it ZERO because UE is out of coverage which is nonsense.
		% disp('Set error! pred_ToS is complex');
		% disp(ToS_1);
		% disp(ToS_2);
	end

end