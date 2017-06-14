%% Fuzzifier for FQ_INP CIO and for FQ_INP Cell Loading
%%把input值對應到membership funcion上的值

%% Abbreviation
% FQ : Fuzzy Q-learning
% CIO : Cell Individual Offset
% DoM : Degree of Membership
% INP : Input

function subDoM = FQc1_Fuzzifier(FQ_INP, type)

	subDoM = zeros(1,5);

	switch(type)
        case 'C'	% 'C' means CIO

            if(FQ_INP < -5)
                subDoM(1) = 1; subDoM(2) = 0; subDoM(3) = 0; subDoM(4) = 0; subDoM(5) = 0;
            elseif(FQ_INP >= -5 && FQ_INP < -2.5)
                subDoM(1) =  -0.4*FQ_INP-1; subDoM(2) = 0.4*FQ_INP+2; subDoM(3) = 0; subDoM(4) = 0; subDoM(5) = 0;
            elseif(FQ_INP >= -2.5 && FQ_INP < 0)
                subDoM(1) = 0; subDoM(2) = -0.4*FQ_INP; subDoM(3) = 0.4*FQ_INP+1; subDoM(4) = 0; subDoM(5) = 0;
            elseif(FQ_INP >= 0 && FQ_INP < 2.5)
                subDoM(1) = 0; subDoM(2) = 0; subDoM(3) = -0.4*FQ_INP+1; subDoM(4) = 0.4*FQ_INP; subDoM(5) = 0;
            elseif(FQ_INP >= 2.5 && FQ_INP < 5)
                subDoM(1) = 0; subDoM(2) = 0; subDoM(3) = 0; subDoM(4) = -0.4*FQ_INP+2; subDoM(5) = 0.4*FQ_INP-1;
            elseif(FQ_INP >= 5)
                subDoM(1) = 0; subDoM(2) = 0; subDoM(3) = 0; subDoM(4) = 0; subDoM(5) = 1;
            else
                disp('Membership fx of CIO set error!');
            end

        case 'L'	% 'L' means Loading

            if(FQ_INP < 0)
                subDoM(1) = 1; subDoM(2) = 0; subDoM(3) = 0; subDoM(4) = 0; subDoM(5) = 0;
            elseif(FQ_INP >= 0 && FQ_INP < 0.25)
                subDoM(1) = -4*FQ_INP+1; subDoM(2) = 4*FQ_INP; subDoM(3) = 0; subDoM(4) = 0; subDoM(5) = 0;
            elseif(FQ_INP >= 0.25 && FQ_INP < 0.5)
                subDoM(1) = 0; subDoM(2) = -4*FQ_INP+2; subDoM(3) = 4*FQ_INP-1; subDoM(4) = 0; subDoM(5) = 0;
            elseif(FQ_INP >= 0.5 && FQ_INP < 0.75)
                subDoM(1) = 0; subDoM(2) = 0; subDoM(3) = -4*FQ_INP+3; subDoM(4) = 4*FQ_INP-2; subDoM(5) = 0;
            elseif(FQ_INP >= 0.75 && FQ_INP < 1)
                subDoM(1) = 0; subDoM(2) = 0; subDoM(3) = 0; subDoM(4) = -4*FQ_INP+4; subDoM(5) = 4*FQ_INP-3;
            elseif(FQ_INP >= 1)
                subDoM(1) = 0; subDoM(2) = 0; subDoM(3) = 0; subDoM(4) = 0; subDoM(5) = 1;
            else
                disp('Membership fx of Loading set error!');
            end
	end
end
