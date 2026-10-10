# Portable detectors (C11 + libm). Builds as an ESP-IDF component, or as a
# plain static library for host tests (firmware/test_host).
set(KD_SRCS kd_dsp.c kd_pdm.c kd_halfband.c kd_spec.c kd_imp.c)

if(ESP_PLATFORM)
    idf_component_register(SRCS ${KD_SRCS} INCLUDE_DIRS include)
    target_compile_options(${COMPONENT_LIB} PRIVATE -Wall -Wextra -Werror -O2)
else()
    add_library(kernel_detect STATIC ${KD_SRCS})
    target_include_directories(kernel_detect PUBLIC include)
    target_compile_features(kernel_detect PRIVATE c_std_11)
    if(NOT MSVC)
        target_link_libraries(kernel_detect PUBLIC m)
    endif()
endif()
