{ pkgs }:

with pkgs;

devshell.mkShell {
  env = [
    {
      name = "ANDROID_HOME";
      value = "${android-sdk}/share/android-sdk";
    }
    {
      name = "ANDROID_SDK_ROOT";
      value = "${android-sdk}/share/android-sdk";
    }
    {
      name = "JAVA_HOME";
      value = jdk11.home;
    }
    {
      name = "PATH";
      prefix = "${pkgs.flutter}/bin/cache/dart-sdk/bin";
    }
  ];
  packages = [
    android-studio
    android-sdk
    gradle
    jdk11
    flutter
  ];
}
