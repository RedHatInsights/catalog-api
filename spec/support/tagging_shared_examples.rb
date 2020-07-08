shared_examples_for "controller that supports tagging endpoints" do
  let(:base_url) { "#{api_version}/#{object_instance.class.table_name}/#{object_instance.id}" }
  let(:bad_object_base_url) { "#{api_version}/#{object_instance.class.table_name}/#{object_instance.id + 10}" }

  before do
    object_instance
  rescue
    raise "Must provide the 'object_instance' to use this shared example"
  end

  context "tags" do
    let(:tag_name) { 'Gnocchi' }
    let(:tag_ns) { 'Charkie' }
    let(:tag_value) { 'Hundley' }
    let(:tag_params) { [{:tag => Tag.new(params).to_tag_string}] }

    shared_examples_for "#tag_add_test" do
      it "add tags for the object" do
        post "#{base_url}/tag", :headers => default_headers, :params => tag_params
        expect(json.first["tag"]).to eq Tag.new(params).to_tag_string
        expect(response).to have_http_status(201)
      end
    end

    shared_examples_for "bad_tags" do
      let(:bad_tags) { %w[/ /approval /approval/workflows=] }

      it "throws a 400" do
        bad_tags.each do |tag|
          post "#{base_url}/#{endpoint}", :headers => default_headers, :params => [:tag => tag]

          expect(response).to have_http_status(400)
        end
      end
    end

    shared_examples_for "good_tags" do
      include RandomWordsSpecHelper
      let(:good_tags) { Array.new(10) { random_tag } }

      it "adds the tag successfully" do
        good_tags.each do |tag|
          post "#{base_url}/tag", :headers => default_headers, :params => [:tag => tag]
          expect(response).to have_http_status(201)
          expect(json.first["tag"]).to eq tag
        end
      end
    end

    context "POST /{object}/{id}/tag" do
      context 'no namespace and value' do
        let(:params) { {:name => tag_name} }
        it_behaves_like "#tag_add_test"
      end

      context 'no value' do
        let(:params) { {:name => tag_name, :namespace => tag_ns} }
        it_behaves_like "#tag_add_test"
      end

      context 'all in' do
        let(:params) { {:name => tag_name, :namespace => tag_ns, :value => tag_value} }
        it_behaves_like "#tag_add_test"
      end

      context 'double add tags' do
        let(:params) { {:name => tag_name} }

        before do
          post "#{base_url}/tag", :headers => default_headers, :params => tag_params
          post "#{base_url}/tag", :headers => default_headers, :params => tag_params
        end

        it "returns not modified" do
          expect(response).to have_http_status(304)
        end
      end

      context 'bad object' do
        let(:params) { {:name => tag_name} }
        it 'returns 404' do
          post "#{bad_object_base_url}/tag", :headers => default_headers, :params => tag_params
          expect(response).to have_http_status(404)
        end
      end

      let(:endpoint) { "tag" }
      it_behaves_like "bad_tags"
      it_behaves_like "good_tags"
    end

    context "POST /{object}/{id}/untag" do
      let(:name) { 'Gnocchi' }
      let(:params) do
        [{:tag => Tag.new(:name => name).to_tag_string}]
      end

      it "removes the tag from the object" do
        post "#{base_url}/tag", :headers => default_headers, :params => params
        post "#{base_url}/untag", :headers => default_headers, :params => params
        object_instance.reload

        expect(response).to have_http_status(204)
        expect(object_instance.tags).to be_empty
      end

      it "silences not found errors" do
        object_instance.tags.destroy_all
        post "#{base_url}/untag", :headers => default_headers, :params => params

        expect(response).to have_http_status(204)
      end

      let(:endpoint) { "untag" }
      it_behaves_like "bad_tags"
      it_behaves_like "good_tags"
    end
  end
end
