Dir.glob(Pathname.new(__dir__).join("v1x0/**/*.rb")) do |file|
  require file.to_s
end
