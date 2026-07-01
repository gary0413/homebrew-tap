cask "saykey" do
  version "0.1.0"
  sha256 "e93bb09c2954f59867ddc9c7b013292d82f7ef394cb96c5eb5803ea445c74cae"

  url "https://github.com/gary0413/SayKey/releases/download/v#{version}/SayKey-v#{version}-macos.zip"
  name "SayKey"
  desc "Push-to-talk voice input built for Chinese-English code-switching"
  homepage "https://github.com/gary0413/SayKey"

  depends_on formula: ["whisper-cpp", "opencc"]
  depends_on macos: :ventura

  app "SayKey.app"

  # SayKey needs the whisper model (~547MB) and a small Silero VAD model in
  # ~/.saykey/models. Download them on install if they aren't already there.
  postflight do
    require "fileutils"
    models = File.join(Dir.home, ".saykey", "models")
    FileUtils.mkdir_p(models)
    {
      "ggml-large-v3-turbo-q5_0.bin" =>
                                        "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo-q5_0.bin",
      "ggml-silero-v6.2.0.bin"       =>
                                        "https://huggingface.co/ggml-org/whisper-vad/resolve/main/ggml-silero-v6.2.0.bin",
    }.each do |name, file_url|
      dest = File.join(models, name)
      next if File.exist?(dest)

      opoo "Downloading SayKey model #{name} (first run only)…"
      system_command "/usr/bin/curl",
                     args: ["-L", "--fail", "--progress-bar", "-o", dest, file_url]
    end
  end

  uninstall quit: "app.saykey.SayKey"

  caveats <<~EOS
    SayKey runs entirely on-device. On first launch, grant Microphone (and,
    only if you enable auto-paste, Accessibility) in System Settings.

    Start/stop dictation with Control-Option-Space. Config: ~/.saykey/config.json

    Models are stored in ~/.saykey/models and are NOT removed on uninstall.
  EOS
end
