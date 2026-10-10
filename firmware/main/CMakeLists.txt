idf_component_register(
    SRCS
        "app_main.c"
        "node_profile.c"
        "capture.c"
        "pipeline.c"
        "event_store.c"
        "snippets.c"
        "node_auth.c"
        "power.c"
        "ble_gatt.c"
    INCLUDE_DIRS "."
    REQUIRES
        kernel_detect
        kernel_proto
        bt
        nvs_flash
        driver
        esp_adc
        esp_timer
        esp_partition
        efuse
        esp_hw_support
        mbedtls
        esp_pm
        log
)
target_compile_options(${COMPONENT_LIB} PRIVATE -Wall -Wextra -Werror -Wno-unused-parameter)
