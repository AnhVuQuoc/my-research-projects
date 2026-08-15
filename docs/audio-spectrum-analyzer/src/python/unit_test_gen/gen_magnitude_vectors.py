import numpy as np
import os

N = 256
NUM_BINS = 128
DW = 16
ALPHA = 31471
BETA = 13036
SHIFT = DW - 1


def to_hex16u(x):
    return format(x & 0xFFFF, "04x")


def abs16(v):
    if v < 0:
        return (-v) & 0xFFFF
    return v & 0xFFFF


def round_sat_unsigned(full):
    lower_bits = full & ((1 << (SHIFT - 1)) - 1)
    bit_shift_minus1 = (full >> (SHIFT - 1)) & 1
    if bit_shift_minus1 == 0:
        shifted = full >> SHIFT
    elif lower_bits != 0:
        shifted = (full >> SHIFT) + 1
    else:
        bit_shift = (full >> SHIFT) & 1
        shifted = (full >> SHIFT) if bit_shift == 0 else (full >> SHIFT) + 1
    if shifted > 0xFFFF:
        shifted = 0xFFFF
    return shifted


def find_msb_pos(val):
    for k in range(DW - 1, -1, -1):
        if (val >> k) & 1:
            return k
    return 0


def magnitude_and_log2(re, im):
    abs_re = abs16(re)
    abs_im = abs16(im)
    mx = max(abs_re, abs_im)
    mn = min(abs_re, abs_im)
    prod = ALPHA * mx + BETA * mn
    mag = round_sat_unsigned(prod)

    msb_pos = find_msb_pos(mag)
    normalized = (mag << (DW - 1 - msb_pos)) & 0xFFFF
    frac_q8 = (normalized >> 7) & 0xFF
    int_part = msb_pos - SHIFT

    if mag == 0:
        log2_q8_8 = -32768
    else:
        log2_q8_8 = int_part * 256 + frac_q8

    return mag, (log2_q8_8 & 0xFFFF)


def main():
    os.makedirs("sim", exist_ok=True)
    rng = np.random.default_rng(11)

    edge_cases = [
        (0, 0), (32767, 32767), (-32768, -32768),
        (32767, -32768), (-32768, 32767),
        (1, 0), (0, 1), (-1, 0), (0, -1),
        (32767, 0), (-32768, 0), (0, 32767), (0, -32768),
    ]
    rand_re = rng.integers(-32768, 32767, size=2000)
    rand_im = rng.integers(-32768, 32767, size=2000)

    re_list = [v[0] for v in edge_cases] + list(rand_re)
    im_list = [v[1] for v in edge_cases] + list(rand_im)
    TOTAL = len(re_list)

    with open("sim/mag_in_re.mem", "w") as f:
        for v in re_list:
            f.write(to_hex16u(int(v)) + "\n")
    with open("sim/mag_in_im.mem", "w") as f:
        for v in im_list:
            f.write(to_hex16u(int(v)) + "\n")

    with open("sim/mag_exp_mag.mem", "w") as fm, open("sim/mag_exp_log2.mem", "w") as fl:
        for re, im in zip(re_list, im_list):
            mag, log2v = magnitude_and_log2(int(re), int(im))
            fm.write(to_hex16u(mag) + "\n")
            fl.write(to_hex16u(log2v) + "\n")

    with open("sim/mag_total.txt", "w") as f:
        f.write(str(TOTAL))

    print(f"Da sinh {TOTAL} cap (re,im) kiem chung cho magnitude_unit ({len(edge_cases)} diem bien + {len(rand_re)} ngau nhien)")


if __name__ == "__main__":
    main()
