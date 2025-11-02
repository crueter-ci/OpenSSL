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

add_library(OpenSSL::Crypto ${LIB_TYPE} IMPORTED GLOBAL)
add_library(OpenSSL::SSL ${LIB_TYPE} IMPORTED GLOBAL)

set_target_properties(OpenSSL::Crypto PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES ${OPENSSL_INCLUDE_DIR}
)

set_target_properties(OpenSSL::SSL PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES ${OPENSSL_INCLUDE_DIR}
)

if (UNIX)
    set_target_properties(OpenSSL::Crypto PROPERTIES
        IMPORTED_LOCATION ${OPENSSL_LIB_DIR}/libcrypto.${LIB_SUFFIX}
    )

    set_target_properties(OpenSSL::SSL PROPERTIES
        IMPORTED_LOCATION ${OPENSSL_LIB_DIR}/libssl.${LIB_SUFFIX}
    )
elseif(MINGW)
    if (BUILD_SHARED_LIBS)
        set_target_properties(OpenSSL::Crypto PROPERTIES
            IMPORTED_LOCATION ${OPENSSL_LIB_DIR}/libcrypto.dll
            IMPORTED_IMPLIB ${OPENSSL_LIB_DIR}/libcrypto.dll.a
        )

        set_target_properties(OpenSSL::SSL PROPERTIES
            IMPORTED_LOCATION ${OPENSSL_LIB_DIR}/libssl.dll
            IMPORTED_IMPLIB ${OPENSSL_LIB_DIR}/libssl.dll.a
        )
    else()
        set_target_properties(OpenSSL::Crypto PROPERTIES
            IMPORTED_LOCATION ${OPENSSL_LIB_DIR}/libcrypto.a
        )

        set_target_properties(OpenSSL::SSL PROPERTIES
            IMPORTED_LOCATION ${OPENSSL_LIB_DIR}/libssl.a
        )
    endif()
else()
    if (BUILD_SHARED_LIBS)
        set_target_properties(OpenSSL::Crypto PROPERTIES
            IMPORTED_LOCATION ${OPENSSL_LIB_DIR}/libcrypto.dll
            IMPORTED_IMPLIB ${OPENSSL_LIB_DIR}/libcrypto.lib
        )

        set_target_properties(OpenSSL::SSL PROPERTIES
            IMPORTED_LOCATION ${OPENSSL_LIB_DIR}/libssl.dll
            IMPORTED_IMPLIB ${OPENSSL_LIB_DIR}/libssl.lib
        )
    else()
        set_target_properties(OpenSSL::Crypto PROPERTIES
            IMPORTED_LOCATION ${OPENSSL_LIB_DIR}/libcrypto_static.lib
        )

        set_target_properties(OpenSSL::SSL PROPERTIES
            IMPORTED_LOCATION ${OPENSSL_LIB_DIR}/libssl_static.lib
        )
    endif()
endif()
