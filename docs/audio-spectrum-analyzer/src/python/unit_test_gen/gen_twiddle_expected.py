import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from golden_model_fft import twiddle_q15

N = 256

def to_hex16(x):
    return format(x & 0xFFFF, "04x")


def main():
    os.makedirs("sim", exist_ok=True)
    with open("sim/tw_exp_re.mem", "w") as fre, open("sim/tw_exp_im.mem", "w") as fim:
        for k in range(N // 2):
            re, im = twiddle_q15(k)
            fre.write(to_hex16(re) + "\n")
            fim.write(to_hex16(im) + "\n")
    print(f"Da sinh {N//2} he so twiddle (doc lap) vao sim/tw_exp_re.mem, sim/tw_exp_im.mem")


if __name__ == "__main__":
    main()
