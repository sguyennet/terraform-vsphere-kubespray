global_defs {
    lvs_id haproxy_DH_passive
}

vrrp_script check_haproxy {
    script "killall -0 haproxy"
    interval 2
    weight 2
}

vrrp_instance VI_01 {
    state SLAVE
    interface ${interface_name}
    virtual_router_id 51
    priority 100

    virtual_ipaddress {
        ${virtual_ip}
    }

    track_script {
        check_haproxy
    }
}
