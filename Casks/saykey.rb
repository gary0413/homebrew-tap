cask "saykey" do
  version "0.2.1"
  sha256 "fbd1721b505a936be1f296978467ea86f7ba1ce20b2ab6807b692e7711b572bd"

  url "https://github.com/gary0413/SayKey/releases/download/v#{version}/SayKey-v#{version}-macos.zip"
  name "SayKey"
  desc "Push-to-talk voice input built for Chinese-English code-switching"
  homepage "https://github.com/gary0413/SayKey"

  depends_on formula: ["whisper-cpp", "opencc"]
  depends_on macos: :ventura

  app "SayKey.app"

  # SayKey needs the whisper model (~547MB) and a small Silero VAD model in
  # ~/.saykey/models. Download them on install (if missing), verifying SHA-256
  # so a corrupted or tampered upstream can't feed bad model data to whisper.cpp.
  postflight do
    require "fileutils"
    require "digest"
    models = File.join(Dir.home, ".saykey", "models")
    FileUtils.mkdir_p(models)
    [
      ["ggml-large-v3-turbo-q5_0.bin",
       "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo-q5_0.bin",
       "394221709cd5ad1f40c46e6031ca61bce88931e6e088c188294c6d5a55ffa7e2"],
      ["ggml-silero-v6.2.0.bin",
       "https://huggingface.co/ggml-org/whisper-vad/resolve/main/ggml-silero-v6.2.0.bin",
       "2aa269b785eeb53a82983a20501ddf7c1d9c48e33ab63a41391ac6c9f7fb6987"],
    ].each do |name, file_url, want_sha|
      dest = File.join(models, name)
      next if File.exist?(dest)

      tmp = "#{dest}.download"
      opoo "Downloading SayKey model #{name} (first run only)…"
      system_command "/usr/bin/curl",
                     args: ["-L", "--fail", "--progress-bar", "-o", tmp, file_url]
      got_sha = Digest::SHA256.file(tmp).hexdigest
      if got_sha != want_sha
        File.delete(tmp)
        odie "SayKey model #{name} failed checksum (expected #{want_sha}, got #{got_sha})"
      end
      FileUtils.mv(tmp, dest)
    end

    # The app is self-signed (open source, runs fully on-device) but not Apple
    # notarized, so strip the download quarantine to avoid a Gatekeeper block.
    system_command "/usr/bin/xattr",
                   args: ["-dr", "com.apple.quarantine", "#{appdir}/SayKey.app"]
  end

  uninstall quit: "app.saykey.SayKey"

  caveats <<~EOS
    SayKey runs entirely on-device. On first launch, grant Microphone (and,
    only if you enable auto-paste, Accessibility) in System Settings.

    Start/stop dictation with Control-Option-Space. Config: ~/.saykey/config.json

    Models are stored in ~/.saykey/models and are NOT removed on uninstall.
  EOS
end
