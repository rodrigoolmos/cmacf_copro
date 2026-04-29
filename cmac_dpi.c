#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static float abs_float(float value)
{
    return (value < 0.0f) ? -value : value;
}

static float bits_to_float(uint32_t bits)
{
    float value;
    memcpy(&value, &bits, sizeof(value));
    return value;
}

static uint32_t float_to_bits(float value)
{
    uint32_t bits;
    memcpy(&bits, &value, sizeof(bits));
    return bits;
}

void cmac_golden(
    uint32_t ar_bits,
    uint32_t ai_bits,
    uint32_t br_bits,
    uint32_t bi_bits,
    unsigned char clear_acc,
    uint32_t *zr_bits,
    uint32_t *zi_bits)
{
    static float acc_re = 0.0f;
    static float acc_im = 0.0f;

    float ar = bits_to_float(ar_bits);
    float ai = bits_to_float(ai_bits);
    float br = bits_to_float(br_bits);
    float bi = bits_to_float(bi_bits);

    if (clear_acc) {
        acc_re = 0.0f;
        acc_im = 0.0f;
    }

    acc_re += (ar * br) - (ai * bi);
    acc_im += (ar * bi) + (ai * br);

    *zr_bits = float_to_bits(acc_re);
    *zi_bits = float_to_bits(acc_im);
}

unsigned char cmac_check(
    unsigned int idx,
    uint32_t ar_bits,
    uint32_t ai_bits,
    uint32_t br_bits,
    uint32_t bi_bits,
    unsigned char clear_acc,
    uint32_t got_zr_bits,
    uint32_t got_zi_bits)
{
    const float max_error_percent = 0.001f;
    const float min_denominator = 1.0e-30f;

    uint32_t exp_zr_bits;
    uint32_t exp_zi_bits;
    float got_zr;
    float got_zi;
    float exp_zr;
    float exp_zi;
    float zr_den;
    float zi_den;
    float zr_error_percent;
    float zi_error_percent;

    cmac_golden(
        ar_bits,
        ai_bits,
        br_bits,
        bi_bits,
        clear_acc,
        &exp_zr_bits,
        &exp_zi_bits);

    got_zr = bits_to_float(got_zr_bits);
    got_zi = bits_to_float(got_zi_bits);
    exp_zr = bits_to_float(exp_zr_bits);
    exp_zi = bits_to_float(exp_zi_bits);

    zr_den = abs_float(exp_zr);
    zi_den = abs_float(exp_zi);
    if (zr_den < min_denominator) {
        zr_den = min_denominator;
    }
    if (zi_den < min_denominator) {
        zi_den = min_denominator;
    }

    zr_error_percent = (abs_float(got_zr - exp_zr) / zr_den) * 100.0f;
    zi_error_percent = (abs_float(got_zi - exp_zi) / zi_den) * 100.0f;

    if ((zr_error_percent <= max_error_percent) &&
        (zi_error_percent <= max_error_percent)) {
        return 1;
    }

    printf("Test %u FAIL:\n", idx);
    printf("  got bits zr=%08x zi=%08x value zr=%e zi=%e\n",
           got_zr_bits,
           got_zi_bits,
           got_zr,
           got_zi);
    printf("  exp bits zr=%08x zi=%08x value zr=%e zi=%e\n",
           exp_zr_bits,
           exp_zi_bits,
           exp_zr,
           exp_zi);
    printf("  error percent zr=%e zi=%e max=%e\n",
           zr_error_percent,
           zi_error_percent,
           max_error_percent);

    return 0;
}

void cmac_gen_test(
    uint32_t *ar_bits,
    uint32_t *ai_bits,
    uint32_t *br_bits,
    uint32_t *bi_bits)
{
    float ar = (float)rand();
    float ai = (float)rand();
    float br = (float)rand();
    float bi = (float)rand();

    memcpy(ar_bits, &ar, sizeof(*ar_bits));
    memcpy(ai_bits, &ai, sizeof(*ai_bits));
    memcpy(br_bits, &br, sizeof(*br_bits));
    memcpy(bi_bits, &bi, sizeof(*bi_bits));
}
