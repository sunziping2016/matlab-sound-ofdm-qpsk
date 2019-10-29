clear all;

run('parameter');
start_end_threshold = 100;
%start_end_threshold = 1;

%% 读取信号
sound = audioread('send.wav')';
sound = sound(1,:);

%% 寻找preamble
figure(4);
[start_cor,start_lags] = xcorr(sound, smb_start);
subplot(2,1,1);
title('起始信号位置');
plot(start_lags, start_cor);
[end_cor,end_lags] = xcorr(sound, smb_end);
subplot(2,1,2);
plot(end_lags, end_cor);
title('终止信号位置');

plot_start_end = true;
if plot_start_end
    figure(5)
    axes = [];
end
signal_buffer = [];
started = 0;
slide_num = floor(length(sound) / symbol_len) - 1;
starts = [];
ends = [];
for i = 1:slide_num
    sig_rec_window = sound((symbol_len*(i-1)+1):symbol_len*(i+1));
    %fprintf("%d %d\n", length(smb_start), length(sig_rec_window));
    [start_cor,start_lags] = xcorr(sig_rec_window, smb_start);
    [start_cor_max, index] = max(start_cor);
    start_lag = start_lags(index);
    [end_cor,end_lags] = xcorr(sig_rec_window, smb_end);
    [end_cor_max, index] = max(end_cor);
    end_lag = start_lags(index);
    %fprintf("start lag: %d end lag: %d\n", start_lag, end_lag);
    skip_buffer = false;
    if start_cor_max > start_end_threshold && 0 <= start_lag && start_lag <= symbol_len
        starts = [starts, start_lag];
        fprintf("start_cor_max: %d index: %d\n", start_cor_max, start_lag);
        if length(starts) == start_preamble_num
            fprintf("start: %f\n", (i-1)*symbol_len+mean(starts)+1);
            signal_buffer = sig_rec_window(round(mean(starts))+1:symbol_len);
            started = 1;
            skip_buffer = true;
        end
    else
        starts = [];
    end
    if end_cor_max > start_end_threshold && 0 < end_lag && end_lag <= symbol_len
        ends = [ends, end_lag];
        fprintf("end_cor_max: %d index: %d\n", end_cor_max, end_lag);
        if length(ends) == end_preamble_num
            fprintf("end: %f\n", (i-1)*symbol_len+mean(ends)+1);
            signal_buffer = [signal_buffer, sig_rec_window(1:round(mean(ends)))];
            signal_buffer = signal_buffer(symbol_len+1:end-(end_preamble_num-1)*symbol_len);
            started = 0;
        end
    else
        ends = [];
    end
    if started == 1 && not(skip_buffer);
        signal_buffer = [signal_buffer, sig_rec_window(1:symbol_len)];
    end
    fprintf("signal buffer size: %d\n", length(signal_buffer));
    if plot_start_end
        subplot(slide_num,3,3*i-2);
        plot(sig_rec_window);
        ax = subplot(slide_num,3,3*i-1);
        plot(start_lags,start_cor);
        axes = [axes, ax];
        ax = subplot(slide_num,3,3*i);
        plot(end_lags,end_cor);
        axes = [axes, ax];
    end
end
if plot_start_end
    linkaxes(axes,'y');
end

figure(6);
plot(signal_buffer);
title('收到的信号');

%% 调整信号长度 
real_signal_len = length(signal_buffer);
symbol_num = round(real_signal_len / real_symbol_len);
expected_signal_len = symbol_num * real_symbol_len;
fprintf("real sig len: %d expected sig len: %d\n", real_signal_len, expected_signal_len);
if real_signal_len < expected_signal_len
    padding_left = floor((expected_signal_len - real_signal_len) / 2);
    padding_right = (expected_signal_len - real_signal_len) - padding_left;
    rx = [zeros(1, padding_left), signal_buffer, zeros(1, padding_right)];
elseif real_signal_len > expected_signal_len
    clip_left = floor((real_signal_len - expected_signal_len) / 2);
    clip_right = (real_signal_len - expected_signal_len) - clip_left;
    rx = signal_buffer(1+clip_left:length(signal_buffer)-clip_right);
else
    rx = signal_buffer;
end

%% 解调信号
t = 0:1/sample_freq:(length(rx)-1)/sample_freq;
real_recvd_signal = rx.*real(exp(1j*2*pi*carrier_freq*t));
imag_recvd_signal = rx.*imag(exp(-1j*2*pi*carrier_freq*t));
figure(7);
subplot(2,1,1);
plot(real_recvd_signal);
title('恢复的基带信号实部');
subplot(2,1,2)
plot(imag_recvd_signal);
title('恢复的基带信号虚部');
recvd_signal = real_recvd_signal + 1j * imag_recvd_signal;

%% 解析信号
recvd_full_matrix = reshape(recvd_signal, real_symbol_len, symbol_num);

recvd_full_matrix(1:cyclic_prefix_len,:)=[];

for i=1:symbol_num
    %   FFT
    fft_data_matrix(:,i) = fft(recvd_full_matrix(:,i),symbol_len);
    fft_data(:, i) = fft_data_matrix(1:subcarrier_num,i);
end

data_num = data_subcarrier_num*symbol_num;
pilot_num = pilot_subcarrier_num*symbol_num;

recvd_serial_data = reshape(fft_data(data_subcarrier_indices, :), 1,data_num);
recvd_serial_pilot = reshape(fft_data(pilot_subcarrier_indices, :), 1,pilot_num);
figure(8);
scatter(real(recvd_serial_data), imag(recvd_serial_data));title('收到的数据星座图');
qpsk_modulated_pilot = qpsk_modulate(pilot_input);
delta_frequency = qpsk_modulated_pilot ./ recvd_serial_pilot;
recvd_serial_data_corrected = recvd_serial_data .* mean(delta_frequency);
figure(9);
scatter(real(delta_frequency), imag(delta_frequency));title('pilot星座图');

qpsk_demodulated_data = qpsk_demodulate(recvd_serial_data_corrected);

figure(10);
stem(qpsk_demodulated_data,'rx');
grid on;xlabel('Data Points');ylabel('Amplitude');title('收到的数据')    
