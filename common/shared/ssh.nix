{lib, ...}: {
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
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
        DynamicForward = "[localhost]:1080";
        proxyCommand = "ssh -q -W search1:%p bast2";
        sessionType = "none";
      };
      "mimir-db" = {
        hostname = "search1";
        LocalForward = [
          {
            bind.port = 5432;
            host.address = "mimir1a.int.no.cptr.no";
            host.port = 5432;
          }
        ];
        proxyCommand = "ssh -q -W search1:%p bast2";
        sessionType = "none";
      };
      "ci-cluster" = {
        hostname = "bk-ci3";
        DynamicForward = "[localhost]:1080";
        proxyCommand = "ssh -q -W bk-ci3.dhcp.bk.cptr.no:%p asbest";
        sessionType = "none";
      };
      "bk-ci*" = {
        proxyCommand = "ssh -q -W %h.dhcp.bk.cptr.no:%p asbest";
      };
      "client" = {
        hostname = "login-client.univex.no";
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
