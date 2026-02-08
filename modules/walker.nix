{ pkgs, ... }:

{
  home.packages = with pkgs; [
    walker
  ];

  # Walker configuration
  xdg.configFile."walker/config.toml".text = ''
    # Appearance
    placeholder = "Search..."

    # UI Settings
    [ui]
    width = 600
    height = 400
    margin = 100

    # Styling similar to screenshot
    [ui.anchors]
    top = true
    left = false
    right = false
    bottom = false

    # Search settings
    [search]
    delay = 0
    placeholder = "Search..."

    # List settings
    [list]
    height = 300
    max_entries = 10

    # Enable modules you want
    [[modules]]
    name = "applications"
    prefix = ""

    [[modules]]
    name = "runner"
    prefix = ""
  '';

  # Walker CSS theme for dark appearance
  xdg.configFile."walker/style.css".text = ''
    * {
      font-family: "JetBrains Mono", monospace;
      font-size: 14px;
    }

    #window {
      background-color: rgba(30, 30, 46, 0.95);
      border-radius: 12px;
      border: 1px solid rgba(180, 190, 254, 0.3);
    }

    #input {
      background-color: transparent;
      color: #cdd6f4;
      padding: 12px 16px;
      border: none;
      border-bottom: 1px solid rgba(180, 190, 254, 0.2);
    }

    #item {
      padding: 10px 16px;
      color: #cdd6f4;
      background-color: transparent;
      border-radius: 8px;
      margin: 4px 8px;
    }

    #item:selected {
      background-color: rgba(180, 190, 254, 0.15);
    }

    #item:hover {
      background-color: rgba(180, 190, 254, 0.1);
    }

    #text {
      color: #cdd6f4;
    }

    #sub {
      color: #a6adc8;
      font-size: 12px;
    }

    #icon {
      margin-right: 12px;
    }
  '';
}
