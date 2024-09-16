% DEMO1_RATE_LEVEL_FUNCTIONS
%
% Measuring auditory-nerve rate-level functions at a single CF.
% 
% The rate-level function is a function between the sound level of an input
% (most typically, a pure tone at a particular sound-pressure level in dB
% SPL re: 20μPa) and the output firing rate of a neuron. Classically, 
% rate-level functions in the auditory nerve slope upward over 20-40 dB 
% above threshold before saturating, at least for sensitive units with
% low thresholds. Here, we simulate responses to pure tones in (1) a
% low-threshold high-spontaneous rate (HSR) fiber, (2) a medium-threshold
% medium-spontaneous-rate (MSR) fiber, and (3) a high-threshold low-
% spontaneous-rate fiber.
%
% A paper with good examples of mammalian auditory-nerve rate-level
% functions is:
%
% Sachs, M. B., and Abbas, P. J. (1974). “Rate versus level functions for 
% auditory-nerve fibers in cats: tone-burst stimuli,” The Journal of the 
% Acoustical Society of America, 56, 1835–1847. doi:10.1121/1.1903521


% Select parameters
level_low = 0.0;    % dB SPL
level_high = 80.0;  % dB SPL
level_step = 5.0;   % dB
levels = level_low:level_step:level_high;
n_level = length(levels);
cf = 1e3;           % Hz
dur = 0.1;          % s
dur_ramp = 0.01;    % s
n_rep = 100;        % #
fs = 100e3;         % sampling rate (Hz)
fiber_types = ["high", "medium", "low"];
n_fiber_type = length(fiber_types);

% Pre-allocate output vectors
mu = zeros(n_level, n_fiber_type);

% Loop over levels
for ii = 1:n_level
	% Synthesize stimulus
	t = 0.0:(1/fs):(dur - 1/fs); t = t';
	stim = sin(2*pi*cf*t);
	stim = cosine_ramp(stim, dur_ramp, fs);
	stim = 20e-6 * 10^(levels(ii)/20.0) * sqrt(2) * stim;

	% Loop over fiber types
	for jj = 1:n_fiber_type
		% Simulate PSTH response
		res = zb_auditory_model( ...
			stim, ...                   % first argument is stimulus
			fs, ...                     % second argument is sampling rate 
			[cf], ...                   % third argument is vector of CFs
			"NumFibers", 1, ...         % single fiber
			"NumReps", n_rep, ...       % 50 reps 
			"NoiseType", "frozen", ...  % freeze synaptic noise
			"FiberType", fiber_types(jj) ...     % spontaneous rate type (high/med/low)
		);
	
		% res.PSTH contains peri-stimulus time histogram, which is the number
		% of spikes observed in each time bin (of width res.PSTHBinSize 
		% seconds). To turn this into a spike rate, we divide by the bin width
		% and by the number of reps and then average over time.
		mu(ii, jj) = mean(res.PSTH .* (1/res.PSTHBinSize) ./ n_rep);
	end
end

% Plot results
figure;
plot(levels, mu);
xlabel("Firing rate (sp/s)");
xlabel("Level (dB SPL)");
ylim([0 250]);
legend(["HSR", "MSR", "LSR"]);
