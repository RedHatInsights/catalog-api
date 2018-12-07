describe "Swagger stuff" do
  describe "Routing" do
    include Rails.application.routes.url_helpers

    context "customizable route prefixes" do
      before do
        stub_const("ENV", ENV.to_h.merge("PATH_PREFIX" => random_path, "APP_NAME" => random_path_part))
        Rails.application.reload_routes!
      end

      after(:all) do
        Rails.application.reload_routes!
      end

      it "with a random prefix" do
        expect(ENV["PATH_PREFIX"]).not_to be_nil
        expect(ENV["APP_NAME"]).not_to be_nil
        expect(api_v0x0_orders_url(:only_path => true)).to eq("/#{URI.encode(ENV["PATH_PREFIX"])}/#{URI.encode(ENV["APP_NAME"])}/v0.0/orders")
      end

      it "doesn't use the APP_NAME when PATH_PREFIX is empty" do
        ENV["PATH_PREFIX"] = ""
        Rails.application.reload_routes!

        expect(ENV["APP_NAME"]).not_to be_nil
        expect(api_v0x0_orders_url(:only_path => true)).to eq("/api/v0.0/orders")
      end
    end

    def words
      @words ||= File.readlines("/usr/share/dict/words").collect(&:strip)
    end

    def random_path_part
      rand(1..5).times.collect { words.sample }.join("_")
    end

    def random_path
      rand(1..10).times.collect { random_path_part }.join("/")
    end
  end
end
