function p = quick_tone(args)
arguments
	args.freq = 1e3
	args.phase = 0.0
	args.dur = 1.0
	args.fs = 100e3
	args.dur_ramp = 0.01
	args.level = 10.0
end
	% QUICK_TONE Synthesize a pure tone (i.e., a sinusoid)
	%
	% signal = QUICK_TONE(args) synthesizes a pure tone with the specified
	% frequency (in Hz), the specified starting phase (in radians), and the
	% specified duration (in seconds) at a sampling rate of fs Hz. The signal
	% is then ramped and scaled to a requested output level (in that order).
	t = (0:(1/args.fs):(args.dur-1/args.fs));
    p = sin(2*pi*args.freq * t + args.phase);
	p = cosine_ramp(p, args.dur_ramp, args.fs);
	p = 20e-6 * 10^(args.level/20.0) * sqrt(2) * p;
end