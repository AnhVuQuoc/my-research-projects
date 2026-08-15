import numpy as np

N = 256
STAGES = int(np.log2(N))
FRAC = 15
SATMAX = (1 << 15) - 1
SATMIN = -(1 << 15)


def bitrev(x, bits=STAGES):
    r = 0
    for _ in range(bits):
        r = (r << 1) | (x & 1)
        x >>= 1
    return r


def round_sat_shift(full, shift):
    if shift == 0:
        r = full
    else:
        round_bit = (full >> (shift - 1)) & 1
        lower = full & ((1 << (shift - 1)) - 1)
        base = full >> shift
        if round_bit == 0:
            r = base
        elif lower != 0:
            r = base + 1
        else:
            r = base if (base & 1) == 0 else base + 1
    return max(SATMIN, min(SATMAX, r))


def to_q15(f):
    return max(SATMIN, min(SATMAX, int(np.round(f * (1 << FRAC)))))


def twiddle_q15(idx):
    a = -2.0 * np.pi * idx / N
    return to_q15(np.cos(a)), to_q15(np.sin(a))


def cmul_q15(ar, ai, br, bi):
    pr = ar * br - ai * bi
    pi = ar * bi + ai * br
    return round_sat_shift(pr, FRAC), round_sat_shift(pi, FRAC)


class _Stage:
    def __init__(self, j):
        self.j = j
        self.L = N >> (j + 1)
        self.tw_step = 1 << j 
        self.fifo = [(0, 0)] * self.L
        self.cnt = 0
        self.o_r = self.o_i = self.o_v = 0

    def clock(self, iv, xr, xi, isof):
        nr = ni = 0
        if iv:
            cnt = 0 if isof else (self.cnt + 1)
            sel = 1 if (cnt % (2 * self.L)) >= self.L else 0
            fr, fi = self.fifo[0]
            if sel == 0:
                to = (xr, xi)
                wr, wi = twiddle_q15(((cnt % self.L) * self.tw_step) % N)
                nr, ni = cmul_q15(fr, fi, wr, wi)
            else:
                nr = round_sat_shift(fr + xr, 1)
                ni = round_sat_shift(fi + xi, 1)
                dr = round_sat_shift(fr - xr, 1)
                di = round_sat_shift(fi - xi, 1)
                to = (dr, di)
            self.fifo = self.fifo[1:] + [to]
            self.cnt = cnt
        self.o_r, self.o_i, self.o_v = nr, ni, iv


def fft_core_stream(x_q15, frames=8):
    sts = [_Stage(j) for j in range(STAGES)]
    stream = np.tile(x_q15, frames)
    T = len(stream) + STAGES + 4
    out = []
    for t in range(T):
        iv = 1 if t < len(stream) else 0
        xr = int(stream[t]) if t < len(stream) else 0
        prev = [(iv, xr, 0)] + [(sts[j].o_v, sts[j].o_r, sts[j].o_i) for j in range(STAGES - 1)]
        for j in range(STAGES):
            sof_j = 1 if (prev[j][0] and ((t - j) % N) == 0) else 0
            sts[j].clock(prev[j][0], prev[j][1], prev[j][2], sof_j)
        out.append(sts[STAGES - 1].o_r + 1j * sts[STAGES - 1].o_i)
    return np.array(out)


def fft_core_frame(x_q15):
    vals = fft_core_stream(x_q15, frames=8)
    Xref = np.fft.fft(np.array(x_q15) / (1 << FRAC)) / N
    best = (-1e9, None)
    for start in range(3 * N, 6 * N):
        frame = vals[start:start + N]
        if len(frame) < N:
            break
        X = np.zeros(N, dtype=complex)
        for k in range(N):
            X[bitrev(k)] = frame[k] / (1 << FRAC)
        e = np.sum(np.abs(X - Xref) ** 2)
        p = np.sum(np.abs(Xref) ** 2)
        s = 10 * np.log10(p / e) if e > 0 else 1e9
        if s > best[0]:
            best = (s, (start, frame))
    start, frame = best[1]
    Xr = [0] * N
    Xi = [0] * N
    for k in range(N):
        Xr[bitrev(k)] = int(np.real(frame[k]))
        Xi[bitrev(k)] = int(np.imag(frame[k]))
    return start, best[0], Xr, Xi


if __name__ == "__main__":
    tot = []
    for seed in range(6):
        np.random.seed(seed)
        xf = np.random.randn(N)
        xf = xf / (np.max(np.abs(xf)) * 1.05)
        xq = [to_q15(v) for v in xf]
        _, sqnr, Xr, Xi = fft_core_frame(xq)
        tot.append(sqnr)
        print(f"seed {seed}: SQNR = {sqnr:5.1f} dB")
    print(f"mean SQNR = {np.mean(tot):.1f} dB  (16-bit Q1.15, scaled 1/N)")
