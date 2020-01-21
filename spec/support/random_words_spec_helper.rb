module RandomWordsSpecHelper
  def words
    @words ||= File.readlines("/usr/share/dict/words").collect(&:strip)
  end

  def random_path_part
    Array.new(rand(1..5)) { words.sample }.join("_")
  end

  def random_path
    Array.new(rand(1..10)) { random_path_part }.join("/")
  end

  def random_tag
    "/#{words.sample}/#{words.sample}".tap { |tag| tag << "=#{words.sample}" if (rand(10) % 2).even? }
  end
end
