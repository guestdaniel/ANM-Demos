% DEMO2_PHASE_LOCKING
%
% Measuring auditory-nerve phase locking as a function of frequency.
% 
% Auditory nerves fire in a synchronized pattern in response to acoustic
% frequencies below about 2-4 kHz. We often say such responses are "phase
% locked" to the frequency because spikes tend to occur at a particular
% phase within one cycle of the frequency. When a pure tone is presented
% with a frequency matching the CF of the auditory-nerve fiber under
% investigation, the strength of phase locking as measured with vector
% strength (or synchronization index) will decrease systematically
% with increasing frequency for frequencies above ~2 kHz.
%
% Here, we'll measure vector strength for a pure tone at CF at a constant
% overall level of 50 dB SPL in a high-spontaneous-rate fiber.
%
% Some background reading is provided:
%
% Rose, J. E., Brugge, J. F., Anderson, D. J., and Hind, J. E. (1967). 
% "Phase-locked response to low-frequency tones in single auditory nerve 
% fibers of the squirrel monkey," Journal of Neurophysiology, 30, 769–793. 
% doi:10.1152/jn.1967.30.4.769
%
% Weiss, T. F., and Rose, C. (1988). “A comparison of synchronization 
% filters in different auditory receptor organs,” Hearing Research, 
% 33, 175–180. doi:10.1016/0378-5955(88)90030-5
%
% A multiple-opinion piece on the role of phase locking to acoustic 
% temporal fine structure is also provided:
%
% Verschooten, E., Shamma, S., Oxenham, A. J., Moore, B. C. J., Joris, 
% P. X., Heinz, M. G., and Plack, C. J. (2019). "The upper frequency 
% limit for the use of phase locking to code temporal fine structure in 
% humans: a compilation of viewpoints," Hearing Research, 377, 109–121. 
% doi:10.1016/j.heares.2019.03.011

% Select parameters
level = 50.0;       % dB SPL
freq_low = 250.0;   % Hz
freq_high = 8e3;    % Hz
freq_step = 1/4;    % octaves
freqs = 2 .^  (log2(freq_low):freq_step:log2(freq_high));
n_freq = length(freqs);
dur = 0.1;          % s
dur_ramp = 0.01;    % s
n_rep = 100;        % #
fs = 100e3;         % sampling rate (Hz)

% Determine settings for period histogram
n_bin = 16;

% Pre-allocate output variables
vs = zeros(n_freq, 1);  % average vector strength at each frequency
hs = zeros(n_freq, n_bin);  % period histograms at each frequency

% Loop over levels
for ii = 1:n_freq
	% Synthesize stimulus
	t = 0.0:(1/fs):(dur - 1/fs); t = t';
	stim = sin(2*pi*freqs(ii)*t);
	stim = cosine_ramp(stim, dur_ramp, fs);
	stim = 20e-6 * 10^(level/20.0) * sqrt(2) * stim;

	% Simulate PSTH response
	res = zb_auditory_model( ...
		stim, ...                   % first argument is stimulus
		fs, ...                     % second argument is sampling rate
		[freqs(ii)], ...            % third argument is vector of CFs
		"NumFibers", 1, ...         % single fiber
		"NumReps", n_rep, ...       % 50 reps
		"NoiseType", "frozen", ...  % freeze synaptic noise
		"FiberType", "high", ...    % spontaneous rate type
		"PSTHBiNSize", 1/fs ...     % PSTH bin width 
	);

	% res.PSTH contains peri-stimulus time histogram, which is the number
	% of spikes observed in each time bin (of width res.PSTHBinSize
	% seconds). To compute the vector strength, we first turn each spike into
	% a complex exponential of unit length and with angle determined by the
	% phase of the spike relative to the frequency of interest. The vector
	% strength is the length of the resulting sum of all the complex
	% exponentials, normalized by the total number of spikes.
	t = 0.0:(res.PSTHBinSize):(length(res.PSTH)*res.PSTHBinSize - res.PSTHBinSize);
	vs(ii) = abs(1/sum(res.PSTH) * sum(res.PSTH' .* exp(1i * 2*pi * freqs(ii) .* t)'));

	% We can also take the PSTH and transform it into a period PSTH, which
	% can be a useful visual analogue of vector strength
	bin_width = 1/freqs(ii)/n_bin;
	edges = 0.0:bin_width:(1/freqs(ii));
	counts = histcounts(mod(repelem(t, res.PSTH), 1/freqs(ii)), edges);
	hs(ii, :) = counts;
end

% Plot results, vector strength versus frequency 
close all;
figure;
plot(freqs, vs); hold on;
set(gca, "Xscale", "log");
ylabel("Vector strength [0, 1]");
xlabel("Frequency/CF (Hz)");
ylim([0 1]);

% Plot period histograms
figure;
tl = tiledlayout(1, n_freq);
for ii = 1:n_freq
	nexttile;
	histogram("BinEdges", 0.0:(2*pi/n_bin):(2*pi), "BinCounts", hs(ii, :));
	ylim([0, 500])
	if ii > 1
		yticklabels([]);
	end
	title("CF = " + sprintf("%0.1f", freqs(ii)));
end
xlabel(tl, "Phase (rad)");
