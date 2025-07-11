#pragma once

#include <lepton.h>

#define ASSERT_OR_THROW(COND, EXC, MSG, ...) \
    if (!COND) { \
        THROW_EXCEPTION(EXC, MSG) \
        return ##__VA_ARGS__; \
    }

#define ASSERT_NONNULL(VAR, ...) \
    if (VAR == null) { \
        THROW_EXCEPTION(NullException, #VAR " is null") \
        return ##__VA_ARGS__; \
    }
