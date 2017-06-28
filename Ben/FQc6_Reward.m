%%

function reward = FQc6_Reward(LOAD,CBR,CDR,type)

	WGT = [2, 5, 5];

    switch(type)
		
        case 'A' % function 1
            load_fx = 0.3 * (1-LOAD);

        case 'B' % function 2
            load_fx = 0.3 * (1 - LOAD^2);

        case 'C' % function 3
            load_fx = 0.3 * sqrt(1 - LOAD^2);

        case 'D' % function 4
            if (LOAD < 0.7)
                load_fx = 0.3;
            elseif (LOAD >= 0.7)
                load_fx = 1 - LOAD;
            end
    end
    
	reward = WGT(1)*load_fx - WGT(2)*CBR - WGT(3)*CDR;
end