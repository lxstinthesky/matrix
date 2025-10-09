{ lib, config, pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    enableLsColors = true;

    histSize = 10000;
    histFile = "$HOME/.zsh_history";
  
    shellAliases = {
      ll = "ls - l";
    };

    ohMyZsh = {
      enable = true;
      plugins = [
        "sudo"
        #"direnv"
        #"fzf"
      ];
      theme = "terminalparty";
    };

    # custom zsh options
    setOptions = [
      "HIST_IGNORE_DUPS" # do not write dupes
      "HIST_SAVE_NO_DUPS"
      "HIST_IGNORE_ALL_DUPS"
      "HIST_FIND_NO_DUPS"
      "APPEND_HISTORY" # append rather than overwrite ...?
      "SHARE_HISTORY" # all zsh sessions share history file
      "HIST_FCNTL_LOCK" # useful to prevent lockups ...? see github
      "HIST_IGNORE_SPACE" # add space before command to not write to history
    ];
  };
}
