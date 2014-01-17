module OmegaHelpers
  AUDIO_EXTS  = ['.wav', '.mp3', '.ogg']

  # middleman ships w/ an older vendored version of padrino which
  # doesn't include the audio_tag helper, so roll a simple one of
  # our own for now (should be removed when we can leverage padrino's)

  def audio_assets
    path = "source/#{audio_dir}"
    Dir["#{path}/**/*"].collect { |audio|
      if File.directory?(audio) || !AUDIO_EXTS.include?(File.extname(audio))
        nil
      else
        audio.gsub("#{path}/", "")
      end
    }.compact
  end

  def audio_path(src)
    asset_path(:audio, src).
      gsub(".audio", "") # XXX quick hack to auto-extension padrino does
  end

  def audio_tag(url, options={})
    options.reverse_merge!(:src => audio_path(url))
    content_tag(:audio, "", options) # needs to be a content tag as audio
                                     # tag needs to have a closing element
  end
end
