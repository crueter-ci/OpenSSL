cmake_minimum_required(VERSION 3.10)

set(OpenSSL_ROOT_DIR "${CMAKE_CURRENT_LIST_DIR}")

set(OPENSSL_LIB_DIR ${CMAKE_CURRENT_LIST_DIR}/lib)
set(OPENSSL_INCLUDE_DIR ${CMAKE_CURRENT_LIST_DIR}/include)

set(LIB_TYPE STATIC)
if (MSVC)
    set(LIB_SUFFIX lib)
else()
    set(LIB_SUFFIX a)
endif()

add_library(crypto ${LIB_TYPE} IMPORTED GLOBAL)
add_library(ssl ${LIB_TYPE} IMPORTED GLOBAL)

add_library(OpenSSL::Crypto ALIAS crypto)
add_library(OpenSSL::SSL ALIAS ssl)

set_target_properties(crypto PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES ${OPENSSL_INCLUDE_DIR})
set_target_properties(ssl PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES ${OPENSSL_INCLUDE_DIR})

set_target_properties(crypto PROPERTIES
    IMPORTED_LOCATION ${OPENSSL_LIB_DIR}/libcrypto.${LIB_SUFFIX})

set_target_properties(ssl PROPERTIES
    IMPORTED_LOCATION ${OPENSSL_LIB_DIR}/libssl.${LIB_SUFFIX})

if (WIN32)
    # extras needed, notably for static linking
    target_link_libraries(ssl INTERFACE
        wsock32 ws2_32 crypt32 mswsock wlanapi)
endif()
