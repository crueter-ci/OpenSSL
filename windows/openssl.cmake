set(OPENSSL_LIB_DIR ${CMAKE_CURRENT_LIST_DIR}/lib)
set(OPENSSL_INCLUDE_DIR ${CMAKE_CURRENT_LIST_DIR}/include)

if (BUILD_SHARED_LIBS)
    add_library(OpenSSL::Crypto SHARED IMPORTED GLOBAL)
    set_target_properties(OpenSSL::Crypto PROPERTIES
        IMPORTED_LOCATION ${OPENSSL_LIB_DIR}/libcrypto.dll
        IMPORTED_IMPLIB ${OPENSSL_LIB_DIR}/libcrypto.lib
        INTERFACE_INCLUDE_DIRECTORIES ${OPENSSL_INCLUDE_DIR}
    )

    add_library(OpenSSL::SSL SHARED IMPORTED GLOBAL)
    set_target_properties(OpenSSL::SSL PROPERTIES
        IMPORTED_LOCATION ${OPENSSL_LIB_DIR}/libssl.dll
        IMPORTED_IMPLIB ${OPENSSL_LIB_DIR}/libssl.lib
        INTERFACE_INCLUDE_DIRECTORIES ${OPENSSL_INCLUDE_DIR}
    )
else()
    add_library(OpenSSL::Crypto STATIC IMPORTED GLOBAL)
    set_target_properties(OpenSSL::Crypto PROPERTIES
        IMPORTED_LOCATION ${OPENSSL_LIB_DIR}/libcrypto_static.lib
        INTERFACE_INCLUDE_DIRECTORIES ${OPENSSL_INCLUDE_DIR}
    )

    add_library(OpenSSL::SSL STATIC IMPORTED GLOBAL)
    set_target_properties(OpenSSL::SSL PROPERTIES
        IMPORTED_LOCATION ${OPENSSL_LIB_DIR}/libssl_static.lib
        INTERFACE_INCLUDE_DIRECTORIES ${OPENSSL_INCLUDE_DIR}
    )
endif()

function(link_openssl)
    foreach(TARGET ${ARGN})
        if (TARGET ${TARGET})
            target_link_libraries(${TARGET} PUBLIC OpenSSL::SSL OpenSSL::Crypto)
        endif()
    endforeach()
endfunction()
