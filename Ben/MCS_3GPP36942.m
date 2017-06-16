%% 3GPP - Modulation and Coding Scheme Page 99


function Spectral_Efficiency = MCS_3GPP36942(SINR)

sinr_min_dB = -6.5; % [dB]
sinr_MAX_dB = 19.2; % [dB]
Thr_min = 0;        % [bit/sec/Hz]
Thr_MAX = 4.8;      % [bit/sec/Hz]
Alpha = 0.75;       % Attenuation Factor

SINR_dB = 10*log10(SINR);

if     (SINR_dB < sinr_min_dB)
    Spectral_Efficiency = Thr_min;
elseif (SINR_dB >= sinr_min_dB && SINR_dB < sinr_MAX_dB)
    Spectral_Efficiency = Alpha * log2(1 + SINR);
elseif (SINR_dB >= sinr_MAX_dB)
    Spectral_Efficiency = Thr_MAX;
end

