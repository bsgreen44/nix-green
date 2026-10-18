{ ... }:

# Privacy defaults. Only well-known keys are declared here, so `rebuild` restores
# them after a macOS update flips them back. Settings with undocumented or fragile
# keys are done by hand once per install:
#   1. System Settings -> Apple Intelligence & Siri -> turn off Apple Intelligence
#      (and the ChatGPT extension)
#   2. System Settings -> Spotlight -> uncheck unwanted result categories
#      (the local index stays on; Raycast, Finder and Mail search rely on it)
#   3. System Settings -> Keyboard -> Keyboard Shortcuts -> Spotlight -> uncheck
#      "Show Spotlight search" so Cmd+Space reaches Raycast (see ../modules/raycast.nix)
#   4. System Settings -> Privacy & Security -> Analytics & Improvements -> turn off
#      every toggle (crash report sharing lives outside /Library/Preferences)
{
  system.defaults.CustomUserPreferences = {
    # Siri off (Apple Intelligence & Siri)
    "com.apple.assistant.support" = {
      "Assistant Enabled" = false;
      "Siri Data Sharing Opt-In Status" = 2; # 2 = opted out of "Improve Siri & Dictation"
      "Search Queries Data Sharing Status" = 2; # 2 = opted out of "Help Apple improve Search"
    };
    "com.apple.Siri" = {
      StatusMenuVisible = false;
      VoiceTriggerUserEnabled = false;
      TypeToSiriEnabled = false;
    };

    # No online suggestions in Spotlight / Look Up
    "com.apple.lookup.shared".LookupSuggestionsDisabled = true;

    # No personalized ads (Privacy & Security -> Apple Advertising)
    "com.apple.AdLib" = {
      allowApplePersonalizedAdvertising = false;
      allowIdentifierForAdvertising = false;
      forceLimitAdTracking = true;
    };
  };

  # Don't share Mac Analytics (Privacy & Security -> Analytics & Improvements)
  system.defaults.CustomSystemPreferences."/Library/Preferences/com.apple.SubmitDiagInfo".AutoSubmit = false;
}
