function output = qpsk_modulate(input)
    phases = [pi/4, 7*pi/4, 3*pi/4, 5*pi/4];
    output = exp(1j .* phases(input + 1));
end