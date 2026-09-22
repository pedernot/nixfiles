_: {
  programs = {
    newsboat = {
      enable = true;
      extraConfig = ''
        bind-key j down
        bind-key k up
        bind-key j next articlelist
        bind-key k prev articlelist
        bind-key J next-feed articlelist
        bind-key K prev-feed articlelist
        bind-key ` next-unread
        bind-key G end
        bind-key g home
        bind-key d pagedown
        bind-key u pageup
        bind-key l open
        bind-key h quit
        bind-key a toggle-article-read
        bind-key n next-unread
        bind-key N prev-unread
        bind-key D pb-download
        bind-key U show-urls
        bind-key x pb-delete

        color listnormal cyan default
        color listfocus black yellow standout bold
        color listnormal_unread blue default
        color listfocus_unread yellow default bold
        color info red black bold
        color article cyan default

        macro , open-in-browser
        macro v set browser "setsid mpv"; open-in-browser ; set browser xdg-open
      '';

      urls = let
        feed = url: tags: {inherit url tags;};
        yt = channel: (feed "https://youtube.com/feeds/videos.xml?channel_id=${channel}" ["yt"]);
      in [
        # (feed "https://without.boats/blog/index.xml" ["rust" "programming"])
        # (feed "https://rachelbythebay.com/w/atom.xml" ["programming"])
        # (feed "http://journal.stuffwithstuff.com/rss.xml" ["programming"])
        # (feed "https://drewdevault.com/blog/index.xml" ["programming"])
        (yt "UChYp9jNwqfpipGzCdLTxTTQ") # Anders Boisen
        (yt "UCMb0O2CdPBNi-QqPk5T3gsQ") # James Hoffman
        (yt "UC1zIiKvJIi7aYl2N68pWF8g") # DivKid
        (yt "UCOq5r8PZawDT9wV1wxzw0VQ") # Monotrail
        (yt "UCy1tvekyTbDs35hwcaWHbpg") # MakeNoise
        (yt "UCO6ZpP3Y8jtrH6emtMSBegQ") # Bries
        (yt "UCCyw4GaWJHezSUowFJ_uH0A") # Tim Wendelboe
        (yt "UCkamwny0IKatfz82LXcLTHQ") # Swedwoods
      ];
    };

    mpv = {
      enable = true;
      bindings = {
        "l" = "seek 5";
        "h" = "seek -5";
        "j" = "seek -60";
        "k" = "seek 60";
        "S" = "cycle sub";
      };
    };
  };
}
