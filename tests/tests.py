import json

@test("lnbits")
def _():
    assert_running("lnbits")
    machine.wait_until_succeeds(
        log_has_string("lnbits", "Application startup complete")
    )
    assert_matches(f"curl -fsS -L {ip('lnbits')}:8231/api/v1/health", "null")

@test("lnbits-clightning")
def _():
    assert_running("lnbits")
    machine.wait_until_succeeds(
        log_has_string("lnbits", "Application startup complete")
    )

    nodeinfo = json.loads(succeed(f"curl -fsS -L {ip('lnbits')}:8231/node/public/api/v1/info"))
    assert_str_matches(nodeinfo['backend_name'], "CLN")
    assert_str_matches(nodeinfo['alias'], "clntest")
    assert_str_matches(nodeinfo['color'], "123456")

@test("lnbits-lnd")
def _():
    assert_running("lnbits")
    machine.wait_until_succeeds(
        log_has_string("lnbits", "Application startup complete")
    )
    assert_matches(f"curl -fsS -L {ip('lnbits')}:8231/api/v1/health", "null")
    assert_matches("stat -c '%U' /var/lib/lnbits/lnd/lnbits.macaroon", "lnbits")

@test("lnbits-lndrest")
def _():
    assert_running("lnbits")
    machine.wait_until_succeeds(
        log_has_string("lnbits", "Application startup complete")
    )
    assert_matches(f"curl -fsS -L {ip('lnbits')}:8231/api/v1/health", "null")
    assert_matches("stat -c '%U' /var/lib/lnbits/lnd/lnbits.macaroon", "lnbits")

    nodeinfo = json.loads(succeed(f"curl -fsS -L {ip('lnbits')}:8231/node/public/api/v1/info"))
    assert_str_matches(nodeinfo['backend_name'], "LND")
    assert_str_matches(nodeinfo['alias'], "lndtest")
    assert_str_matches(nodeinfo['color'], "123456")
