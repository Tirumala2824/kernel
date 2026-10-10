/* Capture front ends, one per node type (Kconfig KERNEL_NODE_*).
 *
 * US_AIR: the SPH0641LU4H-1 runs in ultrasonic mode at 3.072 MHz. The I2S
 * peripheral is used as a 1-bit shift register in standard mode (BCLK =
 * 48 kHz x 32 bit x 2 slots = 3.072 MHz, WS unused) and kd_pdm decimates the
 * raw bits to 192 kSPS. Each 32-sample PCM piece goes straight into pl_feed,
 * which high-passes it at 20 kHz before anything is buffered. The DMA
 * descriptors hold 3 x 4 ms of raw PDM bits and are overwritten in place.
 *
 * CONTACT_PIEZO: PCM1808 (I2S slave, 24-bit in 32-bit slots, 48 kHz, MCLK 256 fs).
 * CONTACT_ACCEL: ST IIS3DWB over SPI, 26.7 kHz ODR, FIFO, Z axis.
 * AUDIO_AIR: standard PDM mic through the I2S PDM RX filter at 32 kHz.
 *
 * Samples only ever pass through these small transient buffers. */
#include <string.h>

#include "esp_log.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "node.h"
#include "sdkconfig.h"

#if CONFIG_KERNEL_NODE_CONTACT_ACCEL
#include "driver/spi_master.h"
#else
#include "driver/i2s_pdm.h"
#include "driver/i2s_std.h"
#endif

#if CONFIG_KERNEL_PDM_BCLK_INVERT
#define PDM_BCLK_INV true
#else
#define PDM_BCLK_INV false
#endif

static const char *TAG = "capture";
static volatile bool s_paused;
static uint32_t s_errors;

static void note_error(bool err)
{
    if (err) {
        if (++s_errors >= 10) {
            pl_set_sensor_fault(true);
        }
    } else if (s_errors) {
        s_errors = 0;
        pl_set_sensor_fault(false);
    }
}

#if !CONFIG_KERNEL_NODE_CONTACT_ACCEL
static i2s_chan_handle_t s_rx;
static bool s_enabled;

static void set_enabled(bool on)
{
    if (on == s_enabled) {
        return;
    }
    if (on) {
        i2s_channel_enable(s_rx);
    } else {
        i2s_channel_disable(s_rx);
    }
    s_enabled = on;
}
#endif

void cap_pause(bool paused) { s_paused = paused; }

/* ------------------------------------------------------------- US_AIR */
#if CONFIG_KERNEL_NODE_US_AIR
static esp_err_t init_hw(void)
{
    i2s_chan_config_t chan = I2S_CHANNEL_DEFAULT_CONFIG(I2S_NUM_0, I2S_ROLE_MASTER);
    chan.dma_desc_num = 3;
    chan.dma_frame_num = 192; /* 192 frames x 64 bits = 4 ms of PDM bits */
    ESP_ERROR_CHECK(i2s_new_channel(&chan, NULL, &s_rx));
    i2s_std_config_t std = {
        .clk_cfg = I2S_STD_CLK_DEFAULT_CONFIG(48000),
        .slot_cfg = I2S_STD_MSB_SLOT_DEFAULT_CONFIG(I2S_DATA_BIT_WIDTH_32BIT, I2S_SLOT_MODE_STEREO),
        .gpio_cfg = {
            .mclk = I2S_GPIO_UNUSED,
            .bclk = CONFIG_KERNEL_PIN_MIC_CLK,
            .ws = I2S_GPIO_UNUSED,
            .dout = I2S_GPIO_UNUSED,
            .din = CONFIG_KERNEL_PIN_MIC_DATA,
            .invert_flags = {.mclk_inv = false, .bclk_inv = PDM_BCLK_INV, .ws_inv = false},
        },
    };
    return i2s_channel_init_std_mode(s_rx, &std);
}

static void capture_task(void *arg)
{
    static uint32_t words[384]; /* 4 ms of raw PDM bits */
    float pcm[32];
    kd_pdm_t pdm;
    kd_pdm_init(&pdm);
    for (;;) {
        if (s_paused) {
            set_enabled(false);
            vTaskDelay(pdMS_TO_TICKS(100));
            continue;
        }
        set_enabled(true);
        size_t got = 0;
        esp_err_t err = i2s_channel_read(s_rx, words, sizeof(words), &got, 200);
        note_error(err != ESP_OK || got == 0);
        size_t nw = got / sizeof(uint32_t);
        /* 16 words = 512 bits = 32 PCM samples; filtered in pl_feed immediately. */
        for (size_t i = 0; i < nw; i += 16) {
            size_t take = nw - i < 16 ? nw - i : 16;
            size_t n = kd_pdm_run(&pdm, &words[i], take, pcm, 32);
            if (n) {
                pl_feed(pcm, n);
            }
        }
    }
}
#endif

/* ----------------------------------------------------------- AUDIO_AIR */
#if CONFIG_KERNEL_NODE_AUDIO_AIR
static esp_err_t init_hw(void)
{
    i2s_chan_config_t chan = I2S_CHANNEL_DEFAULT_CONFIG(I2S_NUM_0, I2S_ROLE_MASTER);
    chan.dma_desc_num = 3;
    chan.dma_frame_num = 256; /* 8 ms at 32 kHz */
    ESP_ERROR_CHECK(i2s_new_channel(&chan, NULL, &s_rx));
    i2s_pdm_rx_config_t pdm = {
        .clk_cfg = I2S_PDM_RX_CLK_DEFAULT_CONFIG(32000),
        .slot_cfg = I2S_PDM_RX_SLOT_DEFAULT_CONFIG(I2S_DATA_BIT_WIDTH_16BIT, I2S_SLOT_MODE_MONO),
        .gpio_cfg = {
            .clk = CONFIG_KERNEL_PIN_MIC_CLK,
            .din = CONFIG_KERNEL_PIN_MIC_DATA,
            .invert_flags = {.clk_inv = false},
        },
    };
    return i2s_channel_init_pdm_rx_mode(s_rx, &pdm);
}

static void capture_task(void *arg)
{
    static int16_t raw[256];
    static float pcm[256];
    for (;;) {
        if (s_paused) {
            set_enabled(false);
            vTaskDelay(pdMS_TO_TICKS(100));
            continue;
        }
        set_enabled(true);
        size_t got = 0;
        esp_err_t err = i2s_channel_read(s_rx, raw, sizeof(raw), &got, 200);
        note_error(err != ESP_OK || got == 0);
        size_t n = got / sizeof(int16_t);
        for (size_t i = 0; i < n; i++) {
            pcm[i] = raw[i] * (1.0f / 32768.0f);
        }
        if (n) {
            pl_feed(pcm, n);
        }
    }
}
#endif

/* ------------------------------------------------------- CONTACT_PIEZO */
#if CONFIG_KERNEL_NODE_CONTACT_PIEZO
static esp_err_t init_hw(void)
{
    i2s_chan_config_t chan = I2S_CHANNEL_DEFAULT_CONFIG(I2S_NUM_0, I2S_ROLE_MASTER);
    chan.dma_desc_num = 3;
    chan.dma_frame_num = 240; /* 5 ms at 48 kHz */
    ESP_ERROR_CHECK(i2s_new_channel(&chan, NULL, &s_rx));
    i2s_std_config_t std = {
        .clk_cfg = I2S_STD_CLK_DEFAULT_CONFIG(48000),
        .slot_cfg = I2S_STD_PHILIPS_SLOT_DEFAULT_CONFIG(I2S_DATA_BIT_WIDTH_32BIT, I2S_SLOT_MODE_STEREO),
        .gpio_cfg = {
            .mclk = CONFIG_KERNEL_PIN_I2S_MCLK,
            .bclk = CONFIG_KERNEL_PIN_MIC_CLK,
            .ws = CONFIG_KERNEL_PIN_I2S_WS,
            .dout = I2S_GPIO_UNUSED,
            .din = CONFIG_KERNEL_PIN_MIC_DATA,
            .invert_flags = {.mclk_inv = false, .bclk_inv = false, .ws_inv = false},
        },
    };
    std.clk_cfg.mclk_multiple = I2S_MCLK_MULTIPLE_256;
    return i2s_channel_init_std_mode(s_rx, &std);
}

static void capture_task(void *arg)
{
    static int32_t raw[2 * 240];
    static float pcm[240];
    for (;;) {
        if (s_paused) {
            set_enabled(false);
            vTaskDelay(pdMS_TO_TICKS(100));
            continue;
        }
        set_enabled(true);
        size_t got = 0;
        esp_err_t err = i2s_channel_read(s_rx, raw, sizeof(raw), &got, 200);
        note_error(err != ESP_OK || got == 0);
        size_t frames = got / (2 * sizeof(int32_t));
        for (size_t i = 0; i < frames; i++) {
            /* Left slot; 24-bit data left-justified in 32 bits. */
            pcm[i] = (float)(raw[2 * i] >> 8) * (1.0f / 8388608.0f);
        }
        if (frames) {
            pl_feed(pcm, frames);
        }
    }
}
#endif

/* ------------------------------------------------------- CONTACT_ACCEL */
#if CONFIG_KERNEL_NODE_CONTACT_ACCEL
#define IIS3DWB_WHO_AM_I 0x0F
#define IIS3DWB_ID 0x7B
#define IIS3DWB_FIFO_CTRL3 0x09
#define IIS3DWB_FIFO_CTRL4 0x0A
#define IIS3DWB_CTRL1_XL 0x10
#define IIS3DWB_CTRL3_C 0x12
#define IIS3DWB_FIFO_STATUS1 0x3A
#define IIS3DWB_FIFO_DATA_OUT_TAG 0x78

static spi_device_handle_t s_spi;

static esp_err_t reg_write(uint8_t reg, uint8_t val)
{
    uint8_t tx[2] = {reg & 0x7F, val};
    spi_transaction_t t = {.length = 16, .tx_buffer = tx};
    return spi_device_polling_transmit(s_spi, &t);
}

static esp_err_t reg_read(uint8_t reg, uint8_t *buf, size_t n)
{
    static uint8_t tx[1 + 7 * 64], rx[1 + 7 * 64];
    if (n > sizeof(rx) - 1) {
        return ESP_ERR_INVALID_SIZE;
    }
    memset(tx, 0, n + 1);
    tx[0] = reg | 0x80;
    spi_transaction_t t = {.length = 8 * (n + 1), .tx_buffer = tx, .rx_buffer = rx};
    esp_err_t err = spi_device_polling_transmit(s_spi, &t);
    if (err == ESP_OK) {
        memcpy(buf, rx + 1, n);
    }
    return err;
}

static esp_err_t init_hw(void)
{
    spi_bus_config_t bus = {
        .mosi_io_num = CONFIG_KERNEL_PIN_SPI_MOSI,
        .miso_io_num = CONFIG_KERNEL_PIN_SPI_MISO,
        .sclk_io_num = CONFIG_KERNEL_PIN_SPI_SCLK,
        .quadwp_io_num = -1,
        .quadhd_io_num = -1,
        .max_transfer_sz = 512,
    };
    ESP_ERROR_CHECK(spi_bus_initialize(SPI2_HOST, &bus, SPI_DMA_CH_AUTO));
    spi_device_interface_config_t dev = {
        .clock_speed_hz = 8 * 1000 * 1000,
        .mode = 3,
        .spics_io_num = CONFIG_KERNEL_PIN_SPI_CS,
        .queue_size = 2,
    };
    ESP_ERROR_CHECK(spi_bus_add_device(SPI2_HOST, &dev, &s_spi));
    uint8_t id = 0;
    reg_read(IIS3DWB_WHO_AM_I, &id, 1);
    if (id != IIS3DWB_ID) {
        ESP_LOGE(TAG, "IIS3DWB not found (WHO_AM_I 0x%02x)", id);
        return ESP_ERR_NOT_FOUND;
    }
    reg_write(IIS3DWB_CTRL3_C, 0x44);    /* BDU, register auto-increment */
    reg_write(IIS3DWB_FIFO_CTRL3, 0x0A); /* batch accelerometer at 26667 Hz */
    reg_write(IIS3DWB_FIFO_CTRL4, 0x06); /* continuous FIFO mode */
    reg_write(IIS3DWB_CTRL1_XL, 0xA0);   /* on, +/-2 g, 26.7 kHz ODR */
    return ESP_OK;
}

static void capture_task(void *arg)
{
    static uint8_t buf[7 * 64];
    static float pcm[64];
    for (;;) {
        if (s_paused) {
            vTaskDelay(pdMS_TO_TICKS(100));
            continue;
        }
        uint8_t st[2];
        esp_err_t err = reg_read(IIS3DWB_FIFO_STATUS1, st, 2);
        uint16_t level = (uint16_t)(st[0] | ((st[1] & 0x03) << 8));
        note_error(err != ESP_OK);
        if (err != ESP_OK || level == 0) {
            vTaskDelay(pdMS_TO_TICKS(2));
            continue;
        }
        if (level > 64) {
            level = 64;
        }
        if (reg_read(IIS3DWB_FIFO_DATA_OUT_TAG, buf, 7u * level) != ESP_OK) {
            continue;
        }
        size_t n = 0;
        for (uint16_t i = 0; i < level; i++) {
            const uint8_t *s = &buf[7 * i];
            int16_t z = (int16_t)(s[5] | (s[6] << 8));
            pcm[n++] = z * (1.0f / 32768.0f);
        }
        pl_feed(pcm, n);
    }
}
#endif

esp_err_t cap_start(void)
{
    esp_err_t err = init_hw();
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "capture init failed: %s", esp_err_to_name(err));
        pl_set_sensor_fault(true);
        return err;
    }
    /* Core 1, high priority: the detectors must keep up with the DMA. */
    xTaskCreatePinnedToCore(capture_task, "kcapture", 8192, NULL, 10, NULL, 1);
    return ESP_OK;
}
