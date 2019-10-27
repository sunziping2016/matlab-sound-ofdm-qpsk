function output = qpsk_demodulate(input)
    numbers = [3, 1, 0, 2];
    output = numbers(round((angle(input) + pi - pi/4) ./ (pi/2)) + 1);
end