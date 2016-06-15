set detach-on-fork on
set follow-fork-mode parent

define dump_headers
    dont-repeat
    set $t = (ngx_table_elt_t *)($arg0.part.elts)
    set $n = $arg0.part.nelts

    # figure out max key length for padding
    set $klm = 0
    set $i = 0
    while $i < $n
        if $t[$i].key.len > $klm
            set $klm = $t[$i].key.len
        end
        set $i = $i + 1
    end

    # output
    set $max_templ = 100
    set $max_buf = 256
    set $templ = malloc($max_templ)
    set $buf = malloc($max_buf)
    set $i = 0
    while $i < $n
        set $k = $t[$i].key.data
        set $kl = $t[$i].key.len
        set $v = $t[$i].value.data
        set $vl = $t[$i].value.len
        set $res = snprintf($templ, $max_templ, "%%%d.%ds: %%.%ds", $klm, $kl, $vl)
        set $res = snprintf($buf, $max_buf, $templ, $k, $v)
        printf "%s\n", $buf
        set $i = $i + 1
    end
    call free($buf)
    call free($templ)
end

define dump_headers_in
    dont-repeat
    dump_headers $arg0->headers_in.headers
end

define dump_headers_out
    dont-repeat
    dump_headers $arg0->headers_out.headers
end