{
    config(devel=false): {
        listener: {
            tcp: {
                address: '[::]:8200',
                cluster_address: '[::]:8201',
                tls_cipher_suites: 'TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA,TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA,TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA,TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA,TLS_RSA_WITH_AES_128_GCM_SHA256,TLS_RSA_WITH_AES_256_GCM_SHA384,TLS_RSA_WITH_AES_128_CBC_SHA,TLS_RSA_WITH_AES_256_CBC_SHA',
                tls_disable: true,
                tls_prefer_server_cipher_suites: true,
            },
        },
        storage: if devel then {
            file: {
                path: '/vault/data',
            },
        } else {
            consul: {
                address: 'consul-test-web-ui:8500',
                path: 'vault/',
            },
        },
        ui: true,
        disable_mlock: true,
    },
}
