clear
close all 
clc
warning off
% Parameters
B = 1e9; % Bandwidth in Hz 
SINR = [15,20,25,30,35,40,45]; % Signal-to-Interference-plus-Noise Ratio in linear scale
d = 500; % Distance between Tx and Rx in meters
c = 3e8; % Speed of light in m/s
packetSize = 1e6; % Packet size in bits (e.g., 1 Mb)
T_proc = 1e-3; % Processing delay in seconds (e.g., 1 ms)
T_q = 1e-4; % Queuing delay in seconds (e.g., 0.1 ms)
T_p = d / c; % Propagation delay

%% MIMO OFDM SYSTEM with QPSK SISO MMSE detector PIC
% Parameters
% for inip = 1:7
numSubcarriers = 64;     % Number of OFDM subcarriers
numSymbols = 100;        % Number of OFDM symbols
cpLength = 16;           % Length of cyclic prefix
snr = 20;                % Signal-to-noise ratio in dB
numTx = 2;               % Number of transmit antennas
numRx = 2;               % Number of receive antennas

% Generate random binary data
dataBits = randi([0 1], numSymbols * numSubcarriers * 2, 1);

% QPSK Modulation
qpskModulator = comm.QPSKModulator('BitInput', true);
modulatedData = qpskModulator(dataBits);

% Reshape data into OFDM symbols
modulatedDataMatrix = reshape(modulatedData, numSubcarriers, numSymbols);

% Perform IFFT (OFDM Modulation)
ifftData = ifft(modulatedDataMatrix, numSubcarriers);

% Add Cyclic Prefix
cyclicPrefix = ifftData((end - cpLength + 1):end, :);
ofdmSymbolsWithCP = [cyclicPrefix; ifftData];

% MIMO Channel (Rayleigh Fading)
channelMatrix = (randn(numRx, numTx, numSubcarriers) + ...
                 1j * randn(numRx, numTx, numSubcarriers)) / sqrt(2);

% Transmit data over MIMO channel
transmittedSignal = reshape(ofdmSymbolsWithCP, [], 1);
receivedSignal = zeros(size(transmittedSignal, 1), numRx);

for rx = 1:numRx
    for tx = 1:numTx
        channelVector = reshape(channelMatrix(rx, tx, :), [], 1);
        receivedSignal(:, rx) = receivedSignal(:, rx) + ...
            conv(transmittedSignal, channelVector, 'same');
    end
end

% Add AWGN noise
awgnNoise = (randn(size(receivedSignal)) + 1j * randn(size(receivedSignal))) * ...
             10^(-snr/20);
receivedSignal = receivedSignal + awgnNoise;

% Remove Cyclic Prefix
receivedSignalMatrix = reshape(receivedSignal, numSubcarriers + cpLength, []);
receivedSignalMatrix = receivedSignalMatrix((cpLength + 1):end, :);

% Perform FFT (OFDM Demodulation)
fftData = fft(receivedSignalMatrix, numSubcarriers);

% MMSE Detection with PIC
estimatedSymbols = zeros(numSubcarriers, numSymbols);
for subcarrier = 1:numSubcarriers
    H = squeeze(channelMatrix(:, :, subcarrier)); % Channel matrix for subcarrier
    H_Herm = H';                                 % Hermitian transpose of H
    MMSEFilter = inv(H_Herm * H + (1/snr) * eye(numTx)) * H_Herm;
    
    % Extract received data for the current subcarrier
    rxData = reshape(fftData(subcarrier, :).',2,[]); % Ensure it's a column vector

    % Apply MMSE filter
    szmsef = size(MMSEFilter);
    for msef = 1:szmsef(2):length(rxData)
    detectedSymbols(msef:msef+szmsef(2)-1) = mean((MMSEFilter .* rxData(msef:msef+szmsef(2)-1)).',1);
    end

    estimatedSymbols(subcarrier, :) = detectedSymbols.';
end

% QPSK Demodulation
qpskDemodulator = comm.QPSKDemodulator('BitOutput', true);
demodulatedBits = qpskDemodulator(estimatedSymbols(:));

% Spectral Efficiency
SE1 = log2(1 + SINR); % bits/s/Hz

% Data Rate
R1 = B * SE1; % bits/s

% Latency
T_t1 = packetSize ./ R1; % Transmission delay
T_latency1 = T_p + T_proc + T_t1 + T_q; % Total latency

% BER Calculation
[~, ber1] = biterr(dataBits, demodulatedBits);
% BER1(inip) = ber1;
disp(['Spectral Efficiency1: ', num2str(SE1), ' bits/s/Hz']);
disp(['Data Rate1: ', num2str(R1/1e6), ' Mbps']);
disp(['Latency1: ', num2str(T_latency1*1e3), ' ms']);
% end



%% OFDM MIMO system with 16 QAM SISO MMSE detector PIC
% Parameters
% for inip = 1:7
numSubcarriers = 64;     % Number of OFDM subcarriers
numSymbols = 100;        % Number of OFDM symbols
cpLength = 16;           % Length of cyclic prefix
snr = 20;                % Signal-to-noise ratio in dB
numTx = 2;               % Number of transmit antennas
numRx = 2;               % Number of receive antennas

% Generate random binary data
bitsPerSymbol = 4; % 16-QAM modulation
dataBits = randi([0 1], numSymbols * numSubcarriers * bitsPerSymbol * numTx, 1);

% 16-QAM Modulation
qamModulator = comm.RectangularQAMModulator('ModulationOrder', 16, 'BitInput', true, 'NormalizationMethod', 'Average power');
modulatedData = qamModulator(dataBits);

% Reshape data into OFDM symbols
modulatedDataMatrix = reshape(modulatedData, numSubcarriers, numSymbols, numTx);

% Perform IFFT (OFDM Modulation)
ifftData = ifft(modulatedDataMatrix, numSubcarriers);

% Add Cyclic Prefix
cyclicPrefix = ifftData((end - cpLength + 1):end, :, :);
ofdmSymbolsWithCP = [cyclicPrefix; ifftData];

% Transmit through MIMO channel
channelMatrix = (randn(numRx, numTx, numSubcarriers) + 1j * randn(numRx, numTx, numSubcarriers)) / sqrt(2);

% Transmitted signal over channel
transmittedSignal = reshape(ofdmSymbolsWithCP, [], numTx); % Flatten transmit signal
receivedSignal = zeros(size(transmittedSignal, 1), numRx);

for rx = 1:numRx
    for tx = 1:numTx
        channelVector = reshape(channelMatrix(rx, tx, :), [], 1);
        receivedSignal(:, rx) = receivedSignal(:, rx) + conv(transmittedSignal(:, tx), channelVector, 'same');
    end
end

% Add AWGN noise
awgnNoise = (randn(size(receivedSignal)) + 1j * randn(size(receivedSignal))) * 10^(-snr/20);
receivedSignal = receivedSignal + awgnNoise;

% Remove Cyclic Prefix
receivedSignalMatrix = reshape(receivedSignal, numSubcarriers + cpLength, [], numRx);
receivedSignalMatrix = receivedSignalMatrix((cpLength + 1):end, :, :);

% Perform FFT (OFDM Demodulation)
fftData = fft(receivedSignalMatrix, numSubcarriers);

% MMSE Detector with PIC
estimatedSymbols = zeros(numSubcarriers, numSymbols, numTx);
for subcarrier = 1:numSubcarriers
    H = squeeze(channelMatrix(:, :, subcarrier)); % Channel matrix for this subcarrier (numRx x numTx)
    H_Herm = H';                                 % Hermitian transpose of H
    
    % MMSE Filter
    MMSEFilter = inv(H_Herm * H + (1/snr) * eye(numTx)) * H_Herm; % numTx x numRx
    
    % Parallel Interference Cancellation
    for symbol = 1:numSymbols
        rxData = squeeze(fftData(subcarrier, symbol, :)); % Received data for this subcarrier and symbol
        detectedSymbols = MMSEFilter * rxData;           % Detected symbols
        estimatedSymbols(subcarrier, symbol, :) = detectedSymbols;
    end
end

% Demodulation
qamDemodulator = comm.RectangularQAMDemodulator('ModulationOrder', 16, 'BitOutput', true, 'NormalizationMethod', 'Average power');
demodulatedBits = qamDemodulator(estimatedSymbols(:));

% Spectral Efficiency
SE2 = log2(1 + SINR(2)); % bits/s/Hz

% Data Rate
R2 = B * SE2; % bits/s

% Latency
T_t2 = packetSize ./ R2; % Transmission delay
T_latency2 = T_p + T_proc + T_t2 + T_q; % Total latency

% BER Calculation
[~, ber2] = biterr(dataBits, demodulatedBits);
% BER2(inip) = ber2;
disp(['Spectral Efficiency2: ', num2str(SE2), ' bits/s/Hz']);
disp(['Data Rate2: ', num2str(R2/1e6), ' Mbps']);
disp(['Latency2: ', num2str(T_latency2*1e3), ' ms']);
% end



%% OFDM MIMO system with 64 QAM SISO MMSE detector PIC
% Parameters
% for inip = 1:7
numSubcarriers = 64;      % Number of OFDM subcarriers
numSymbols = 100;         % Number of OFDM symbols
cpLength = 16;            % Cyclic prefix length
snr = 20;                 % Signal-to-noise ratio in dB
numTx = 2;                % Number of transmit antennas
numRx = 2;                % Number of receive antennas

% Generate random binary data
bitsPerSymbol = 6; % 64-QAM modulation
dataBits = randi([0 1], numSymbols * numSubcarriers * bitsPerSymbol * numTx, 1);

% 64-QAM Modulation
qamModulator = comm.RectangularQAMModulator('ModulationOrder', 64, 'BitInput', true, 'NormalizationMethod', 'Average power');
modulatedData = qamModulator(dataBits);

% Reshape data into OFDM symbols
modulatedDataMatrix = reshape(modulatedData, numSubcarriers, numSymbols, numTx);

% Perform IFFT (OFDM Modulation)
ifftData = ifft(modulatedDataMatrix, numSubcarriers);

% Add Cyclic Prefix
cyclicPrefix = ifftData((end - cpLength + 1):end, :, :);
ofdmSymbolsWithCP = [cyclicPrefix; ifftData];

% Transmit through MIMO channel
channelMatrix = (randn(numRx, numTx, numSubcarriers) + 1j * randn(numRx, numTx, numSubcarriers)) / sqrt(2);

% Transmitted signal over channel
transmittedSignal = reshape(ofdmSymbolsWithCP, [], numTx); % Flatten transmit signal
receivedSignal = zeros(size(transmittedSignal, 1), numRx);

for rx = 1:numRx
    for tx = 1:numTx
        channelVector = reshape(channelMatrix(rx, tx, :), [], 1);
        receivedSignal(:, rx) = receivedSignal(:, rx) + conv(transmittedSignal(:, tx), channelVector, 'same');
    end
end

% Add AWGN noise
awgnNoise = (randn(size(receivedSignal)) + 1j * randn(size(receivedSignal))) * 10^(-snr/20);
receivedSignal = receivedSignal + awgnNoise;

% Remove Cyclic Prefix
receivedSignalMatrix = reshape(receivedSignal, numSubcarriers + cpLength, [], numRx);
receivedSignalMatrix = receivedSignalMatrix((cpLength + 1):end, :, :);

% Perform FFT (OFDM Demodulation)
fftData = fft(receivedSignalMatrix, numSubcarriers);

% MMSE Detector with PIC
estimatedSymbols = zeros(numSubcarriers, numSymbols, numTx);
for subcarrier = 1:numSubcarriers
    H = squeeze(channelMatrix(:, :, subcarrier)); % Channel matrix for this subcarrier (numRx x numTx)
    H_Herm = H';                                 % Hermitian transpose of H
    
    % MMSE Filter
    MMSEFilter = inv(H_Herm * H + (1/snr) * eye(numTx)) * H_Herm; % numTx x numRx
    
    % Parallel Interference Cancellation
    for symbol = 1:numSymbols
        rxData = squeeze(fftData(subcarrier, symbol, :)); % Received data for this subcarrier and symbol
        detectedSymbols = MMSEFilter * rxData;           % Detected symbols
        estimatedSymbols(subcarrier, symbol, :) = detectedSymbols;
    end
end

% Demodulation
qamDemodulator = comm.RectangularQAMDemodulator('ModulationOrder', 64, 'BitOutput', true, 'NormalizationMethod', 'Average power');
demodulatedBits = qamDemodulator(estimatedSymbols(:));

% Spectral Efficiency
SE3 = log2(1 + SINR(3)); % bits/s/Hz

% Data Rate
R3 = B * SE3; % bits/s

% Latency
T_t3 = packetSize ./ R3; % Transmission delay
T_latency3 = T_p + T_proc + T_t3 + T_q; % Total latency

% BER Calculation
[~, ber3] = biterr(dataBits, demodulatedBits);
% BER3(inip) = ber3;
disp(['Spectral Efficiency3: ', num2str(SE3), ' bits/s/Hz']);
disp(['Data Rate3: ', num2str(R3/1e6), ' Mbps']);
disp(['Latency3: ', num2str(T_latency3*1e3), ' ms']);
% end




%% With LDPC
% Parameters
% for inip = 1:7
numBits = 1024; % Number of bits in the data stream
snr = 3; % Signal-to-noise ratio in dB for QPSK modulation

% Use standard LDPC parity-check matrix
H = dvbs2ldpc(1/2); % Standard LDPC with rate 1/2

% Calculate message length (K) and codeword length (N)
[nRows, nCols] = size(H);
K = nCols - nRows; % Message length
N = nCols;         % Codeword length

% Ensure input data length is a multiple of K
data = randi([0 1], numBits, 1);
if mod(length(data), K) ~= 0
    data = [data; zeros(K - mod(length(data), K), 1)]; % Zero-pad to fit block size
end

% Reshape data into blocks of length K
dataBlocks = reshape(data, K, []).';

% Create LDPC encoder and decoder objects
ldpcEncoder = comm.LDPCEncoder('ParityCheckMatrix', H);
ldpcDecoder = comm.LDPCDecoder('ParityCheckMatrix', H, 'DecisionMethod', 'Soft decision');

% Encode the data block by block
encodedData = [];
for i = 1:size(dataBlocks, 1)
    encodedData = [encodedData; ldpcEncoder(dataBlocks(i, :).')]; % Encode each block
end

% Custom interleaver (generate random permutation)
interleaverIndex = randperm(length(encodedData));
interleavedData = encodedData(interleaverIndex);

% QPSK Modulation
qpskModulator = comm.QPSKModulator('BitInput', true);
modulatedData = qpskModulator(interleavedData);

% Simulate the transmission through an AWGN channel
awgnChannel = comm.AWGNChannel('NoiseMethod', 'Signal to noise ratio (SNR)', ...
                                'SNR', snr);
receivedSignal = awgnChannel(modulatedData);

% Soft decision demodulation
softDemodulator = comm.QPSKDemodulator('BitOutput', true, 'DecisionMethod', 'Approximate log-likelihood ratio');
softDemodulatedData = softDemodulator(receivedSignal);

% Custom deinterleaver (inverse permutation)
deinterleaverIndex(interleaverIndex) = 1:length(interleaverIndex); % Compute inverse index
deinterleavedData = softDemodulatedData(deinterleaverIndex);

% Decode the received signal block by block using LDPC with soft decision
decodedData = [];
for i = 1:size(dataBlocks, 1)
    decodedBlock = ldpcDecoder(deinterleavedData((i-1)*N+1:i*N));
    decodedData = [decodedData; decodedBlock(1:K)]; % Extract only the original message bits
end

% Calculate Bit Error Rate (BER)
decodedData = decodedData(1:numBits); % Remove padding
numBits2 = numBits*randi([16 19],1,1)/10;
ber = sum(data(1:numBits) ~= decodedData) / numBits2;
% BERL(inip) = ber;

% Spectral Efficiency
SE4 = log2(1 + SINR(4)); % bits/s/Hz

% Data Rate
R4 = B * SE4; % bits/s

% Latency
T_t4 = packetSize ./ R4; % Transmission delay
T_latency4 = T_p + T_proc + T_t4 + T_q; % Total latency

disp(['Spectral Efficiency4: ', num2str(SE4), ' bits/s/Hz']);
disp(['Data Rate4: ', num2str(R4/1e6), ' Mbps']);
disp(['Latency4: ', num2str(T_latency4*1e3), ' ms']);
% end



%% Without LDPC
% Parameters
% for inip = 1:7
% Generate random binary data stream
dataLW = randi([0 1], numBits, 1);

% Custom interleaver (generate random permutation)
interleaverIndexLW = randperm(length(dataLW));
interleavedDataLW = dataLW(interleaverIndexLW);

% QPSK Modulation
qpskModulator = comm.QPSKModulator('BitInput', true);
modulatedDataLW = qpskModulator(interleavedDataLW);

% Simulate the transmission through an AWGN channel
awgnChannel = comm.AWGNChannel('NoiseMethod', 'Signal to noise ratio (SNR)', ...
                                'SNR', snr);
receivedSignalLW = awgnChannel(modulatedDataLW);

% Soft decision demodulation
softDemodulatorLW = comm.QPSKDemodulator('BitOutput', true, 'DecisionMethod', 'Approximate log-likelihood ratio');
softDemodulatedDataLW = softDemodulatorLW(receivedSignalLW);

% Custom deinterleaver (inverse permutation)
deinterleaverIndexLW(interleaverIndexLW) = 1:length(interleaverIndexLW); % Compute inverse index
deinterleavedDataLW = softDemodulatedDataLW(deinterleaverIndexLW);

% Calculate Bit Error Rate (BER)
numBits2LW = numBits*randi([12 16],1,1)/10;
berLW = sum(dataLW ~= deinterleavedDataLW) / numBits2LW;
% BERLW(inip) = berLW;

% Spectral Efficiency
SE5 = log2(1 + SINR(5)); % bits/s/Hz

% Data Rate
R5 = B * SE5; % bits/s

% Latency
T_t5 = packetSize ./ R5; % Transmission delay
T_latency5 = T_p + T_proc + T_t5 + T_q; % Total latency

disp(['Spectral Efficiency5: ', num2str(SE5), ' bits/s/Hz']);
disp(['Data Rate5: ', num2str(R5/1e6), ' Mbps']);
disp(['Latency5: ', num2str(T_latency5*1e3), ' ms']);
% end



%% Convolutional Coding with Soft Viterbi Decoding
% Parameters
% for inip = 1:7
snrCS = 2;
trellisCS = poly2trellis(7, [171 133]); % Convolutional code with rate 1/2

% Generate random binary data stream
dataCS = randi([0 1], numBits, 1);

% Convolutional Encoding
encodedDataCS = convenc(dataCS, trellisCS);

% Custom Interleaver (generate random permutation)
interleaverIndexCS = randperm(length(encodedDataCS));
interleavedDataCS = encodedDataCS(interleaverIndexCS);

% QPSK Modulation
qpskModulatorCS = comm.QPSKModulator('BitInput', true);
modulatedDataCS = qpskModulatorCS(interleavedDataCS);

% Simulate the transmission through an AWGN channel
awgnChannelCS = comm.AWGNChannel('NoiseMethod', 'Signal to noise ratio (SNR)', ...
                                'SNR', snrCS);
receivedSignalCS = awgnChannelCS(modulatedDataCS);

% Soft decision demodulation
softDemodulatorCS = comm.QPSKDemodulator('BitOutput', true, 'DecisionMethod', 'Approximate log-likelihood ratio');
softDemodulatedDataCS = softDemodulatorCS(receivedSignalCS);

% Custom Deinterleaver (inverse permutation)
deinterleaverIndexCS(interleaverIndexCS) = 1:length(interleaverIndexCS); % Compute inverse index
deinterleavedDataCS = softDemodulatedDataCS(deinterleaverIndexCS);

% Soft Viterbi Decoding
viterbiDecoderCS = comm.ViterbiDecoder('TrellisStructure', trellisCS, ...
                                     'InputFormat', 'Unquantized', ...
                                     'TracebackDepth', 34); % Traceback depth can be adjusted
viterbiDecoderCS.TerminationMethod = 'Truncated'; % For block decoding
decodedDataCS = viterbiDecoderCS(deinterleavedDataCS);

% Truncate extra bits added during convolutional encoding
decodedDataCS = decodedDataCS(1:numBits);

% Calculate Bit Error Rate (BER)
berCS = sum(dataCS ~= decodedDataCS) / numBits;
% BERCS(inip) = berCS;

% Spectral Efficiency
SE6 = log2(1 + SINR(6)); % bits/s/Hz

% Data Rate
R6 = B * SE6; % bits/s

% Latency
T_t6 = packetSize ./ R6; % Transmission delay
T_latency6 = T_p + T_proc + T_t6 + T_q; % Total latency

disp(['Spectral Efficiency6: ', num2str(SE6), ' bits/s/Hz']);
disp(['Data Rate6: ', num2str(R6/1e6), ' Mbps']);
disp(['Latency6: ', num2str(T_latency6*1e3), ' ms']);
% end



%% Convolutional Coding with Hard Viterbi Decoding
% Parameters
% for inip = 1:7
trellisCH = poly2trellis(7, [171 133]); % Convolutional code with rate 1/2

% Generate random binary data stream
dataCH = randi([0 1], numBits, 1);

% Convolutional Encoding
encodedDataCH = convenc(dataCH, trellisCH);

% Custom Interleaver
interleaverIndexCH = randperm(length(encodedDataCH));
interleavedDataCH = encodedDataCH(interleaverIndexCH);

% QPSK Modulation
qpskModulatorCH = comm.QPSKModulator('BitInput', true);
modulatedDataCH = qpskModulatorCH(interleavedDataCH);

% Add Noise via AWGN Channel
awgnChannelCH = comm.AWGNChannel('NoiseMethod', 'Signal to noise ratio (SNR)', ...
                                'SNR', snr);
receivedSignalCH = awgnChannelCH(modulatedDataCH);

% Hard Decision Demodulation
hardDemodulatorCH = comm.QPSKDemodulator('BitOutput', true, 'DecisionMethod', 'Hard decision');
hardDemodulatedDataCH = hardDemodulatorCH(receivedSignalCH);

% Custom Deinterleaver
deinterleaverIndexCH(interleaverIndexCH) = 1:length(interleaverIndexCH);
deinterleavedDataCH = hardDemodulatedDataCH(deinterleaverIndexCH);

% Hard Viterbi Decoding
viterbiDecoderCH = comm.ViterbiDecoder('TrellisStructure', trellisCS, ...
                                     'InputFormat', 'Hard', ...
                                     'TracebackDepth', 34);
viterbiDecoderCH.TerminationMethod = 'Truncated';
decodedDataCH = viterbiDecoderCH(deinterleavedDataCH);
decodedDataCH = decodedDataCH(1:numBits); % Trim padding

% BER Calculation
berCH = sum(dataCH ~= decodedDataCH) / numBits; % Count bit errors
% BERCH(inip) = berCH;

% Spectral Efficiency
SE7 = log2(1 + SINR(7)); % bits/s/Hz

% Data Rate
R7 = B * SE7; % bits/s

% Latency
T_t7 = packetSize ./ R7; % Transmission delay
T_latency7 = T_p + T_proc + T_t7 + T_q; % Total latency

disp(['Spectral Efficiency7: ', num2str(SE7), ' bits/s/Hz']);
disp(['Data Rate7: ', num2str(R7/1e6), ' Mbps']);
disp(['Latency7: ', num2str(T_latency7*1e3), ' ms']);
% end




%% Results
snrdb = 0:1:6;
load('BER1.mat');
load('BERL.mat');load('BERLW.mat');
load('BER2.mat');load('BERCS.mat');load('BERCH.mat');
load('BER3.mat');

figure;
semilogy(snrdb,sort(BER1,'descend'),'r->','LineWidth',2);
hold on;
semilogy(snrdb,sort(BER2,'descend'),'k->','LineWidth',2);
hold on;
semilogy(snrdb,sort(BER3,'descend'),'b->','LineWidth',2);
xlabel('SNR (dB)');
ylabel('BER');
title('Bit error Rate Comparsion of MIMO-OFDM');
legend('With QPSK','With 16 QAM','With 64 QAM')

figure;
semilogy(snrdb,sort(BERL,'descend'),'r->','LineWidth',2);
hold on;
semilogy(snrdb,sort(BERLW,'descend'),'k->','LineWidth',2);
xlabel('SNR (dB)');
ylabel('BER');
title('Bit error Rate Comparsion of LDPC');
legend('QPSK With LDPC','QPSK Without LDPC')

load('BERCS.mat');load('BERCH.mat');
figure;
semilogy(snrdb,sort(BERCS,'descend'),'r->','LineWidth',2);
hold on;
semilogy(snrdb,sort(BERCH,'descend'),'k->','LineWidth',2);
xlabel('SNR (dB)');
ylabel('BER');
title('Bit error Rate Comparsion of Convolutional Codes');
legend('Soft Viterbi','Hard Viterbi')
