Grover.configure do |config|
  # Auto-detect Chrome on macOS default path
  chrome_path = ENV["GROVER_CHROME_PATH"] ||
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
  config.options[:executable_path] = chrome_path if File.exist?(chrome_path)
end
