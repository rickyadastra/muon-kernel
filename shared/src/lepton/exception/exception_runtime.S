#if __STDC_HOSTED__ == 0
    #if defined (__x86_64__) && (defined (MS_ABI))
        #include "exception_runtime_x86_64_ms.s"
    #elif defined (__x86_64__) && (defined (SYSV_ABI))
        #include "exception_runtime_x86_64_sysv.s"
    #endif
#endif
