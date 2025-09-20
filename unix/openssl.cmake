set(SHARED_SUFFIX so)
set(STATIC_SUFFIX a)

set(OPENSSL_LIB_DIR ${CMAKE_CURRENT_LIST_DIR}/lib)
set(OPENSSL_INCLUDE_DIR ${CMAKE_CURRENT_LIST_DIR}/include)

if (BUILD_SHARED_LIBS)
    add_library(OpenSSL::Crypto SHARED IMPORTED GLOBAL)
    set_target_properties(OpenSSL::Crypto PROPERTIES
        IMPORTED_LOCATION ${OPENSSL_LIB_DIR}/libcrypto.${SHARED_SUFFIX}
        INTERFACE_INCLUDE_DIRECTORIES ${OPENSSL_INCLUDE_DIR}
    )

    add_library(OpenSSL::SSL SHARED IMPORTED GLOBAL)
    set_target_properties(OpenSSL::SSL PROPERTIES
        IMPORTED_LOCATION ${OPENSSL_LIB_DIR}/libssl.${SHARED_SUFFIX}
        INTERFACE_INCLUDE_DIRECTORIES ${OPENSSL_INCLUDE_DIR}
    )
else()
    add_library(OpenSSL::Crypto STATIC IMPORTED GLOBAL)
    set_target_properties(OpenSSL::Crypto PROPERTIES
        IMPORTED_LOCATION ${OPENSSL_LIB_DIR}/libcrypto.${STATIC_SUFFIX}
        INTERFACE_INCLUDE_DIRECTORIES ${OPENSSL_INCLUDE_DIR}
    )

    add_library(OpenSSL::SSL STATIC IMPORTED GLOBAL)
    set_target_properties(OpenSSL::SSL PROPERTIES
        IMPORTED_LOCATION ${OPENSSL_LIB_DIR}/libssl.${STATIC_SUFFIX}
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
