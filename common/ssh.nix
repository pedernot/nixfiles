{lib, ...}: {
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "asbest" = {
        hostname = "bk.cptr.no";
      };
      "bast1" = {
        hostname = "dora.cptr.no";
        port = 2233;
        proxyCommand = "ssh -q -W %h:%p asbest";
      };
      "bast2" = {
        hostname = "dora.cptr.no";
        port = 2234;
        proxyCommand = "ssh -q -W %h:%p asbest";
      };
      "staging" = {
        hostname = "app9";
        proxyCommand = "ssh -q -W app9:%p bast2";
      };
      "app*" = {
        proxyCommand = "ssh -q -W %h:%p bast2";
      };
      "util1" = {
        proxyCommand = "ssh -q -W %h:%p bast2";
      };
      "search*" = {
        proxyCommand = "ssh -q -W %h:%p bast2";
      };
      "dora-cluster" = {
        hostname = "search1";
        dynamicForwards = [{port = 1080;}];
        proxyCommand = "ssh -q -W search1:%p bast2";
        extraOptions = {SessionType = "none";};
      };
      "mimir-db" = {
        hostname = "search1";
        localForwards = [
          {
            bind.port = 5432;
            host.address = "mimir1a.int.no.cptr.no";
            host.port = 5432;
          }
        ];
        proxyCommand = "ssh -q -W search1:%p bast2";
        extraOptions = {SessionType = "none";};
      };
      "ci-cluster" = {
        hostname = "bk-ci3";
        dynamicForwards = [{port = 1080;}];
        proxyCommand = "ssh -q -W bk-ci3.dhcp.bk.cptr.no:%p asbest";
        extraOptions = {SessionType = "none";};
      };
      "bk-ci*" = {
        proxyCommand = "ssh -q -W %h.dhcp.bk.cptr.no:%p asbest";
      };
      "client" = {
        hostname = "login-client.univex.no";
      };
      "34.* 54.*" = lib.hm.dag.entryBefore ["*"] {
        # aws
        user = "ubuntu";
        identityFile = "/home/peder/.ssh/backend_key.pem";
      };
      "*" = {
        user = "pedernot";
        serverAliveInterval = 60;
        forwardX11 = false;
        forwardAgent = true;
      };
    };
  };
}
