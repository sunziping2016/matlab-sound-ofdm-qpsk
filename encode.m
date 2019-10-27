clear all;

run('parameter');

%% 生成随机数据
figure(1);
stem(data_input); grid on; xlabel('Data Points'); ylabel('Amplitude');
title('Transmitted Data "O"');

writematrix(data_input, 'data.txt');

%% 使用QPSK调制
qpsk_modulated_data = pskmod(data_input, M);
qpsk_modulated_pilot = pskmod(pilot_input, M);
% scatterplot(qpsk_modulated_data);title('MODULATED TRANSMITTED DATA');

%% 对每个块做IFFT
data_matrix = reshape(qpsk_modulated_data, data_subcarrier_num, symbol_num);
pilot_matrix = reshape(qpsk_modulated_pilot, pilot_subcarrier_num, symbol_num);

full_matrix = zeros(subcarrier_num, symbol_num);
full_matrix(data_subcarrier_indices, :) = data_matrix;
full_matrix(pilot_subcarrier_indices, :) = pilot_matrix;

cyclic_prefix_start = symbol_len-cyclic_prefix_len;
cyclic_prefix_end = symbol_len;

for i=1:symbol_num
    ifft_full_matrix(:,i) = ifft((full_matrix(:,i)),symbol_len);
    %   Compute and append Cyclic Prefix
    for j=1:cyclic_prefix_len
       actual_cyclic_prefix(j,i) = ifft_full_matrix(j+cyclic_prefix_start,i);
    end
    %   Append the CP to the existing block to create the actual OFDM block
    ifft_data(:,i) = vertcat(actual_cyclic_prefix(:,i),ifft_full_matrix(:,i));
end

%% 转成序列信号
ofdm_signal = reshape(ifft_data, 1, real_symbol_len * symbol_num);

%% 调制信号
t = 0:1/sample_freq:(length(ofdm_signal)-1)/sample_freq;
tx = real(ofdm_signal.*exp(1j*2*pi*carrier_freq*t));
figure(2);
subplot(3,1,1);
plot(real(ofdm_signal));
subplot(3,1,2);
plot(imag(ofdm_signal));
subplot(3,1,3);
plot(tx);

%% 加入
real_tx = [zeros(1,space_factor*symbol_len), ...
           preamble_am.*repmat(smb_start,1,start_preamble_num), ...
           tx, ...
           preamble_am.*repmat(smb_end,1,end_preamble_num), ...
           zeros(1,space_factor*symbol_len)];
figure(3);
plot(real_tx);

audiowrite('send.wav', real_tx, sample_freq, 'BitsPerSample', 16);