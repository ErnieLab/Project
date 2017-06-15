%% 3GPP - Modulation and Coding Scheme Page 99


function Throughput = MCS_3GPP36942(RSRQ)

sinr_min_dB = -6.5; % [dB]
sinr_MAX_dB = 19.2; % [dB]
Thr_min = 0;        % [bit/sec/Hz]
Thr_MAX = 4.8;      % [bit/sec/Hz]
Alpha = 0.75;       % Attenuation Factor

sinr = RSRQ/(1 - RSRQ);
sinr_dB = 10*log10(sinr);

if     (sinr_dB < sinr_min_dB)
    Throughput = Thr_min;
elseif (sinr_dB >= sinr_min_dB && sinr_dB < sinr_MAX_dB)
    Throughput = Alpha * log2(1 + sinr);
elseif (sinr_dB >= sinr_MAX_dB)
    Throughput = Thr_MAX;
end

