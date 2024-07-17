{ pkgs, torSocket }: {
  systemdEnvs = {
    LD_PRELOAD = "${pkgs.torsocks}/lib/torsocks/libtorsocks.so";
    TORSOCKS_CONF_FILE = (builtins.toFile "torsocks.conf" ''
      TorAddress ${torSocket.addr}
      TorPort ${builtins.toString torSocket.port}
      OnionAddrRange 127.42.42.0/24
      AllowOutboundLocalhost 1
      AllowInbound 1
      IsolatePID 1
    '');
  };
}
