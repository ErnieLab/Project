%%

function reward = FQc6_Reward(LOAD,CBR,CDR,type)

	WGT = [2, 1, 6];  %自訂reward的weight(選用模擬結果最好的一組weight)

    switch(type)  %設計4種獎勵函式，模擬結果顯示第3種效能較好，所以我們選用第3種case
		
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