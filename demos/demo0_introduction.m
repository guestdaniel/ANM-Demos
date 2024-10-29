% DEMO0_INTRODUCTION
%
% This is an introduction to the auditory nerve and auditory-nerve modeling
% 
% This script is designed as a friendly introduction to the auditory nerve
% and auditory-nerve modeling. Remember to start with the README.md file
% in this repository to learn how to get the code that we will use in this
% introduction. This introduction should get you ready to parse the more
% complex demo files (e.g., `demo1_rate_level_functions.m`).
%
% This script assumes basic familiarity with the concepts of frequency
% (units: Hertz, or Hz) as well as sound level (units: decibels sound
% pressure level, or dB SPL). For a refresher on sound level, refer to 
% https://en.wikipedia.org/wiki/Sound_pressure. It also assumes familiarity
% with digital signal processing concepts such as sampling rates.

%% Part 1: Pure-tone stimuli
% Before we look into auditory-nerve responses, we need to generate stimuli
% that are appropriate for the auditory-nerve model. The model operates at 
% a high sampling rate (most often, 100 kHz) on time-pressure waveforms in
% units of pascals. We can generate such a waveform in MATLAB below.

% Set sampling rate... needs to be high to avoid aliasing from
% nonlinearities in the model (e.g., IHC input-output function)
fs = 100e3;  % Hz

% We will synthesize a pure tone (or sinusoid). This is a common laboratory
% stimulus for auditory research. There's a few key things to keep in mind:
% 
% - Typically, frequencies in the range of 20 Hz–20 kHz are used in human
%   auditory research (because these are the limits of human hearing!), 
%	with frequencies in the 0.5-8 kHz range being most typical (most energy
%   in speech will be found within this range).
% - The duration needs to be long enough to elicit a meaningful response
%   (i.e., > few ms), but simulations longer than a few seconds may be slow
%	or unwieldly to look at.
% - We also have to ramp our stimulus to avoid sudden changes in pressure
%   or discontinuities at the onset/offset of the stimulus. 
% - Finally, we need to scale the stimulus to have energy in a range that
%   is physiologically meaningful: stimuli below about -10–0 dB SPL will not
%   elicit a response at most frequencies, whereas sound levels above 90 dB
%   SPL or so could even damage the system under investigation, and so are 
%   difficult to simulate. Thus, the range of -10–90 dB SPL is probably
%   where you want to stay.
%
% We will choose appropriate parameters below. For a more general treatment
% of sinusoids, see https://ccrma.stanford.edu/~jos/st/Sinusoids.html.
freq = 1000.0;    % Hz
level = 20.0;     % dB SPL
dur = 0.1;        % s
dur_ramp = 0.01;  % s

% First, we need to create a time vector, `t`, that encodes the time at the
% beginning of each discrete time sample.
t = 0.0:(1/fs):(dur - 1/fs);

% Next, we synthesize the sound-pressure waveform, pass it to a ramping
% function, and then scale the output to the requested sound level.
p = sin(2*pi*freq*t);
p = 20e-6 * 10^(level/20.0) * sqrt(2) * p;
p = cosine_ramp(p, dur_ramp, fs);

% Finally, we can plot the signal!
figure;
plot(t, p)
xlabel("Time (s)");
ylabel("Pressure (Pa)");

% In the future, to make life easier, we can use a convenience function
% defined in this package, `quick_tone`, to generate this stimulus more
% quickly. Query `help quick_tone` in the prompt to see more information,
% and see the example below. Note that `quick_tone` uses MATLAB's
% name-value pair syntax to pass arguments.
figure;
plot(t, quick_tone(freq=freq, level=level, dur=dur, fs=fs, dur_ramp=dur_ramp))
xlabel("Time (s)");
ylabel("Pressure (Pa)");

%% Part 2: Basic pure-tone response
% Given our stimulus function `quick_tone`, we can probe basic auditory-
% nerve responses to pure-tone stimulation. We can pass our stimuli to the
% auditory-nerve model wrapper function `zb_auditory_model` and get the 
% outputs in a structure array.

% Set stimulus and model parameters for this simulation
fs = 100e3;       % Hz
freq = 1000.0;    % Hz
level = 20.0;     % dB SPL
dur = 0.1;        % s
dur_ramp = 0.01;  % s
cf = 2000.0;      % Hz

% Synthesize stimulus
p = quick_tone(freq=freq, level=level, dur=dur, fs=fs, dur_ramp=dur_ramp);

% Pass stimlus to `zb_auditory_model`
% Note that, in addition to time-pressure waveform `p`, we need two more
% positional arguments:
%	- the second argument is the sampling rate, `fs`
%	- the third argument is a vector of characteristic frequency (or CF)
%	values. For the time being, we can pick the CF to match the tone
%	frequency of 1 kHz and explore this more later on!
resp = zb_auditory_model(p, fs, cf);

% The `resp` structure contains a few different fields, but for our
% purposes two are essential: `resp.IHC`, containing the IHC response over
% time, and `resp.AN`, containing the instantaneous auditory-nerve rate
% over time. We can conceptualize the latter as the time-varying arrival
% rate of a non-homogeneous Poisson process
% (https://en.wikipedia.org/wiki/Poisson_point_process), although this is
% an imperfect approximation because of refractoriness in the auditory
% nerve. 
% 
% Here, let's plot the stimulus, the IHC response, and the AN response in a
% single stack. Note that in simulating the responses, we typically
% simulate a bit of extra time after the end of the stimulus, because
% responses to stimulus *offsets* are interesting too! As a result, we
% can't use the same time vector `t` to plot the stimulus and model
% results.
t_stim = 0.0:(1/fs):(dur - 1/fs);
t_model = 0.0:(1/fs):(length(resp.AN)/fs - 1/fs);
figure;
tl = tiledlayout(3, 1, "TileSpacing", "tight", "Padding", "compact");
nexttile; plot(t_stim, p); xlabel("Time (s)"); ylabel("Pressure (Pa)"); xlim([0 0.12]);
nexttile; plot(t_model, resp.IHC); xlabel("Time (s)"); ylabel("Output (a.u.)"); xlim([0 0.12]);
nexttile; plot(t_model, resp.AN); xlabel("Time (s)"); ylabel("Rate (sp/s)"); xlim([0 0.12]);

%% Part 3: Varying sound level
% The rest of this script focuses on the effects of varying two key
% parameters: sound level and frequency. We'll vary sound level first and
% examine the consequences. We'll pick several sound levels spanning a wide
% range and then simulate the effects in the auditory nerve and plot the
% results in a stack. 

% Set stimulus and model parameters for this simulation
fs = 100e3;       % Hz
freq = 2000.0;    % Hz
dur = 0.1;        % s
dur_ramp = 0.01;  % s
cf = 2000.0;      % Hz

% Pick sound levels
levels = -20.0:20.0:80.0;  % dB SPL, increments of 20 dB starting at -20 dB SPL

% Loop over each level, synthesize acoustic waveform, and simulate response
resps = cell(length(levels), 1);
for ii = 1:length(levels)
	% Synthesize waveform (note we use a different level on each iteration)
	stim = quick_tone(freq=freq, dur=dur, dur_ramp=dur_ramp, level=levels(ii), fs=fs);

	% Generate model response
	resps{ii} = zb_auditory_model(stim, fs, cf);
end

% Create figure
figure;
tl = tiledlayout(length(levels), 1, "TileSpacing", "compact", "Padding", "compact");

% Loop through results and plot each
for ii = length(levels):-1:1  % backwards loop to put highest level on top
	% Extract AN rate from resp object and construct time axis
	anr = resps{ii}.AN;
	t = 0.0:(1/fs):(length(anr)/fs - 1/fs);

	% Plot 
	nexttile;
	plot(t, anr);

	% Set ylimits (we need to fix them across panels, because the range of
	% response rates will differ among sound levels — if we don't do this,
	% each panel will autoscale to different ylimits, making absolute
	% comparisons across panels hard!). Knowing where to set the ylimits is
	% something you'll learn from experience based on what you're simulating
	% and the stimulus sound levels.
	ylim([0 1250]);

	% Indicate level in title
	title("Level = " + string(levels(ii)) + " dB SPL");
end

% Add x and y labels
xlabel(tl, "Time (s)");
ylabel(tl, "Firing rate (sp/s)");

%% Part 4: Varying frequency
% Next, we vary the frequency of the tone and examine the consequences.
% Because the auditory periphery has sharp frequency selectivity, we need
% to vary the tone frequency in a limited range around the CF of the neuron
% being simulated; otherwise, we may see very little response for
% frequencies that are very distant from the CF. In general, when
% simulating auditory responses, we will use logarithmically spaced
% frequencies, rather than linearly spaced frequencies. A logarithmic
% spacing better captures how frequency is represented in the auditory
% periphery along the "tonotopic axis", and how distances between
% frequencies are represented perceptually.

% Set stimulus and model parameters for this simulation
fs = 100e3;       % Hz
level = 40.0;     % dB SPL
dur = 0.1;        % s
dur_ramp = 0.01;  % s
cf = 2000.0;      % Hz

% Pick frequencies 
freqs = exp(linspace(log(cf/1.5), log(cf*1.5), 7));  % Hz, even increments 
		% from cf/1.5 to cf*1.5 in logarithmically spaced steps

% Loop over each level, synthesize acoustic waveform, and simulate response
resps = cell(length(freqs), 1);
for ii = 1:length(freqs)
	% Synthesize waveform (note we use a different frequency on each iteration)
	stim = quick_tone(freq=freqs(ii), dur=dur, dur_ramp=dur_ramp, level=level, fs=fs);

	% Generate model response
	resps{ii} = zb_auditory_model(stim, fs, cf);
end

% Create figure
figure;
tl = tiledlayout(length(freqs), 1, "TileSpacing", "compact", "Padding", "compact");

% Loop through results and plot each
for ii = length(freqs):-1:1  % backwards loop to put highest freq on top
	% Extract AN rate from resp object and construct time axis
	anr = resps{ii}.AN;
	t = 0.0:(1/fs):(length(anr)/fs - 1/fs);

	% Plot 
	nexttile;
	plot(t, anr);

	% Set ylimits (we need to fix them across panels, because the range of
	% response rates will differ among sound levels — if we don't do this,
	% each panel will autoscale to different ylimits, making absolute
	% comparisons across panels hard!). Knowing where to set the ylimits is
	% something you'll learn from experience based on what you're simulating
	% and the stimulus sound levels.
	ylim([0 1250]);

	% Indicate freq in title
	title( ...
		"Freq  = " + string(round(freqs(ii)/1e3, 2)) + " kHz, " + ...
		 string(round(log2(freqs(ii)/cf), 2)) + " octaves re: CF" ...
	);
end

% Add x and y labels
xlabel(tl, "Time (s)");
ylabel(tl, "Firing rate (sp/s)");
