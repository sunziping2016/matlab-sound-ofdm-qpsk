%% 参数
rng(50)

M = 4;
symbol_num = 11;
subcarrier_num = 10;
pilot_subcarrier_num = 2;
symbol_len = 1024;
cyclic_prefix_factor = 0.1;
space_factor = 1.5;

data_subcarrier_num = subcarrier_num - pilot_subcarrier_num;
pilot_subcarrier_indices = round((1:pilot_subcarrier_num) .* (subcarrier_num / (pilot_subcarrier_num + 1)));
data_subcarrier_indices = setdiff(1:subcarrier_num, pilot_subcarrier_indices);
data_num = symbol_num * data_subcarrier_num;
pilot_num = symbol_num * pilot_subcarrier_num;
full_num = data_num + pilot_num;
cyclic_prefix_len = ceil(cyclic_prefix_factor * symbol_len);
cyclic_prefix_start = symbol_len - cyclic_prefix_len;
cyclic_prefix_end = symbol_len;
real_symbol_len = symbol_len + cyclic_prefix_len;


sample_freq = 44100;
carrier_freq = 1000;
preamble_high_freq = 4000;
preamble_low_freq = 2000;
start_preamble_num = 2;
end_preamble_num = 2;
am = 100;

t = (0:1/sample_freq:(symbol_len-1)/sample_freq);
smb_start = chirp(t,preamble_low_freq,t(end),preamble_high_freq);
smb_end = chirp(t,preamble_high_freq,t(end),preamble_low_freq);

data_input = randi([0, M-1], 1, data_num);
% pilot_input = randi([0, M-1], 1, pilot_num);
pilot_input = zeros(1, pilot_num);
