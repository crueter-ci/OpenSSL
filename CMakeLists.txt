cmake_minimum_required(VERSION 3.10)

set(OpenSSL_ROOT_DIR "${CMAKE_CURRENT_LIST_DIR}")

set(OPENSSL_LIB_DIR ${CMAKE_CURRENT_LIST_DIR}/lib)
set(OPENSSL_INCLUDE_DIR ${CMAKE_CURRENT_LIST_DIR}/include)

if (APPLE)
    set(SHARED_SUFFIX dylib)
else()
    set(SHARED_SUFFIX so)
endif()

if (BUILD_SHARED_LIBS)
    set(LIB_TYPE SHARED)
    set(LIB_SUFFIX ${SHARED_SUFFIX})
else()
    set(LIB_TYPE STATIC)
    set(LIB_SUFFIX a)
endif()

add_library(crypto ${LIB_TYPE} IMPORTED)
add_library(ssl ${LIB_TYPE} IMPORTED)

set_target_properties(crypto PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES ${OPENSSL_INCLUDE_DIR}
)

set_target_properties(ssl PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES ${OPENSSL_INCLUDE_DIR}
)

if (UNIX)
    set_target_properties(crypto PROPERTIES
        IMPORTED_LOCATION ${OPENSSL_LIB_DIR}/libcrypto.${LIB_SUFFIX}
    )

    set_target_properties(ssl PROPERTIES
        IMPORTED_LOCATION ${OPENSSL_LIB_DIR}/libssl.${LIB_SUFFIX}
    )
elseif(MINGW)
    if (BUILD_SHARED_LIBS)
        set_target_properties(crypto PROPERTIES
            IMPORTED_LOCATION ${OPENSSL_LIB_DIR}/libcrypto.dll
            IMPORTED_IMPLIB ${OPENSSL_LIB_DIR}/libcrypto.dll.a
        )

        set_target_properties(ssl PROPERTIES
            IMPORTED_LOCATION ${OPENSSL_LIB_DIR}/libssl.dll
            IMPORTED_IMPLIB ${OPENSSL_LIB_DIR}/libssl.dll.a
        )
    else()
        set_target_properties(crypto PROPERTIES
            IMPORTED_LOCATION ${OPENSSL_LIB_DIR}/libcrypto.a
        )

        set_target_properties(ssl PROPERTIES
            IMPORTED_LOCATION ${OPENSSL_LIB_DIR}/libssl.a
        )
    endif()
else()
    if (BUILD_SHARED_LIBS)
        set_target_properties(crypto PROPERTIES
            IMPORTED_LOCATION ${OPENSSL_LIB_DIR}/libcrypto.dll
            IMPORTED_IMPLIB ${OPENSSL_LIB_DIR}/libcrypto.lib
        )

        set_target_properties(ssl PROPERTIES
            IMPORTED_LOCATION ${OPENSSL_LIB_DIR}/libssl.dll
            IMPORTED_IMPLIB ${OPENSSL_LIB_DIR}/libssl.lib
        )
    else()
        set_target_properties(crypto PROPERTIES
            IMPORTED_LOCATION ${OPENSSL_LIB_DIR}/libcrypto_static.lib
        )

        set_target_properties(ssl PROPERTIES
            IMPORTED_LOCATION ${OPENSSL_LIB_DIR}/libssl_static.lib
        )
    endif()
endif()

if (WIN32)
    # extras needed, notably for static linking
    target_link_libraries(ssl INTERFACE wsock32 ws2_32 crypt32 mswsock wlanapi)
endif()

add_library(OpenSSL::SSL ALIAS ssl)
add_library(OpenSSL::Crypto ALIAS crypto)
