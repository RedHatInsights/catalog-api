require 'rake'

namespace :sonar do
  desc "Run a sonarqube scan"
  task :scan => :environment do
    raise "Test coverage required, Run 'CI=1 rake spec' to generate coverage/.resultset.json" unless File.exist?("coverage/.resultset.json")
    raise "Scanner jar required, download from here https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-4.2.0.1873.zip then set the env var with SONAR_PATH=/path/to/sonar-scanner/lib/sonar-scanner-cli-4.2.0.1873.jar" unless ENV['SONAR_PATH']

    setup unless File.exist?(".sonar/sonar-scanner.properties")

    system("java -jar #{ENV['SONAR_PATH']} -Dproject.settings=.sonar/sonar-scanner.properties")
  end

  def setup
    user = ENV['USER'] || `whoami`
    host = if ENV['SONAR_HOST']
             ENV['SONAR_HOST']
           else
             puts "Using `localhost:9000` as sonarqube host - set SONAR_HOST and remove `.sonar/sonar-scanner.properties` to change it"
             "localhost:9000"
           end

    File.open(".sonar/sonar-scanner.properties", "w") do |fh|
      fh.write(File.read(".sonar/sonar-scanner.properties.template").sub("$user$", user).sub("$host$", host))
    end
  end
end
