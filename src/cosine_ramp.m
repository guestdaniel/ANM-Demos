function signal_out = cosine_ramp(signal, dur_ramp, fs)
% COSINE_RAMP Ramps an input signal with raised-cosine aka Hanning ramps
%
% signal_out = COSINE_RAMP(signal, dur_ramp, fs) adds raised-cosine aka
% Hanning ramp at the onset and offset of the signal. The final duration
% is equal to the input duration (i.e., onset/offset ramp time is included
% as part of the overall signal time). The ramp is generated using sampling
% rate `fs` in Hz. Duration `dur_ramp` is specified in seconds.
	% Handle potential errors
	if ~isvector(signal)
		error("Cannot ramp non-vector signal");
	end

	% Handle case of column vector (we transponse inside the function and
	% transpose back on return)
	flip = false;
	if size(signal, 1) == 1
		flip = true;
		signal = signal';
	end

	% Create ramp and apply to signal
	len_ramp = round(dur_ramp*fs);
	ramp_segment = hanning(len_ramp*2);
	ramp_segment = ramp_segment(1:len_ramp);
    ramp = [ramp_segment; ones(length(signal) - length(ramp_segment)*2, 1); fliplr(ramp_segment')'];
    signal_out = ramp .* signal;
	
	% If needed, transpose signal back to original orientation
	if flip
		signal_out = signal_out';
	end
end

