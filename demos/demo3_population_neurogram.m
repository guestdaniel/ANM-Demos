% DEMO3_POPULATION_NEUROGRAM
%
% Average auditory-nerve response as function of time and frequency
%
% In many applications, it is useful to look at the full population of 
% auditory-nerve fibers in response to a single sound without collapsing
% across time. Most often, one visualizes average rate as a function of
% time (on the x-axis) and characteristic frequency (on the y-axis),
% creating a so-called population "neurogram" or "auditory spectrogram".
% The code below generates such an example for a single /hvd/ token from
% the North Texas Vowel Database.
%
% Things to try:
%	- Try other tokens from https://personal.utdallas.edu/~assmann/KIDVOW1/North_Texas_vowel_database.html
%		Edit line 30 to point to different tokens
%	- Change the sound level (line 22)
%	- Change the fiber type (line 45)
%	- Change between narrowband/broadband spectrogram by adjusting STFT
%		Line 52 below

% Select parameters
level = 50.0;    % overall level for the stimulus (dB SPL)
fs = 100e3;      % model sampling rate (Hz)
cf_low = 125;    % lowest CF (Hz)
cf_high = 16e3;  % highest CF (Hz)
n_cf = 121;      % number of CFs 
cfs = exp(linspace(log(cf_low), log(cf_high), n_cf));

% Load vowel token from UT Dallas servers
[x, fs_orig] = webread('http://www.utdallas.edu/~assmann/KIDVOW1/kabrii01.wav');

% Resample vowel to 100 kHz and rescale to requested level
x = resample(x, 100e3, fs);  % resample to model rate
x = x/rms(x);
x = 20e-6 * 10^(level/20) * x;

% Simulate response (using automated parallel compute across CFs)
res = zb_auditory_model( ...
	x, ...                      % first argument is stimulus
	fs, ...                     % second argument is sampling rate
	cfs, ...                    % third argument is vector of CFs
	"NumFibers", 1, ...         % single fiber
	"NumReps", 1, ...           % single rep
	"NoiseType", "frozen", ...  % freeze synaptic noise
	"FiberType", "high", ...    % high sppontaneous rate 
	"UseParallel", true ...     % enable parallel compute (first time is slow due to parpool setup)
);

% Compare side-by-side with traditional spectrogram
tiledlayout(1, 2);
nexttile;
n = 2^11;  % number of samples in the STFT window 
[S, F, T] = spectrogram(x, hanning(n), round(n*0.9), n*4, fs);
h = pcolor(T, F, 20*log10(abs(S)));
set(h, "EdgeColor", "none");
set(gca, "YDir", "normal");
set(gca, "Yscale", "log");
yticks([200 500 1000 2000 5000 10000]);
ylim([cf_low cf_high]);
xlim([0 length(x)/fs]);
xlabel("Time (s)");
ylabel("Frequency (Hz)");
title("Spectrogram");

nexttile;
t = 0.0:(1/fs):(length(res.AN)/fs - 1/fs);
h = pcolor(t, cfs, res.AN);
set(h, "EdgeColor", "none");
set(gca, "YDir", "normal");
set(gca, "Yscale", "log");
yticks([200 500 1000 2000 5000 10000]);
ylim([cf_low cf_high]);
xlim([0 length(x)/fs]);
caxis([0 quantile(res.AN(:), 0.99)])
xlabel("Time (s)");
ylabel("CF (Hz)");
title("Neurogram");
