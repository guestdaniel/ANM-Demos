function signal_out = cosine_ramp(signal, dur_ramp, fs)
% COSINE_RAMP Ramps an input signal with raised-cosine onset/offset ramps
%
% signal_out = COSINE_RAMP(signal, dur_ramp, fs) adds raised-cosine onset/
% offset ramps of duration dur_ramp to a signal with sampling rate fs.
%
	len_ramp = round(dur_ramp*fs);
	ramp_segment = hanning(len_ramp*2);
	ramp_segment = ramp_segment(1:len_ramp);
    ramp = [ramp_segment; ones(length(signal) - length(ramp_segment)*2, 1); fliplr(ramp_segment')'];
    signal_out = ramp .* signal;
end

