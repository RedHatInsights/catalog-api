describe SurveyToJSONSchema do
  let(:variable_name) { 'charkie' }
  let(:description) { 'Please enter a value' }
  let(:title) { 'Curious George' }
  let(:choices) { "" }
  let(:max_value) { 100 }
  let(:min_value) { 1 }

  let(:base_properties) do
    {
      "title"       => title,
      "description" => description,
      "type"        => json_type
    }
  end

  let(:num_properties) do
    {
      variable_name => {
        "minimum" => min_value,
        "maximum" => max_value,
        "default" => default_value
      }.merge(base_properties)
    }
  end

  let(:string_properties) do
    {
      variable_name => {
        "minLength" => min_value,
        "maxLength" => max_value,
        "default"   => default_value
      }.merge(base_properties)
    }
  end

  let(:password_properties) do
    {
      variable_name => {
        "minLength" => min_value,
        "maxLength" => max_value,
        "default"   => default_value,
        "format"    => "password"
      }.merge(base_properties)
    }
  end

  let(:array_properties) do
    {
      variable_name => {
        "items"   => {
          'type' => 'string',
          'enum' => choice_array
        },
        "default" => [default_value]
      }.merge(base_properties)
    }
  end

  let(:single_select_properties) do
    {
      variable_name => {
        "type"    => 'string',
        "default" => default_value,
        "enum"    => choice_array
      }.merge(base_properties)
    }
  end

  let(:match) do
    {
      "title"                => SurveyToJSONSchema::DEFAULT_TITLE,
      "description"          => SurveyToJSONSchema::DEFAULT_DESCRIPTION,
      "$schema"              => "http://json-schema.org/schema#",
      "required"             => [variable_name],
      "properties"           => properties,
      "additionalProperties" => false,
      "type"                 => "object"
    }
  end

  let(:data) do
    { 'spec' => ['variable'             => variable_name,
                 'type'                 => spec_type,
                 'default'              => default_value,
                 'max'                  => max_value,
                 'min'                  => min_value,
                 'question_description' => description,
                 'question_name'        => title,
                 'choices'              => choices,
                 'required'             => true] }
  end

  it "raises JSON parse error for empty string" do
    expect { SurveyToJSONSchema.new("").to_json_schema }.to raise_error(JSON::ParserError)
  end

  it "raises runtime when the hash is invalid" do
    expect(SurveyToJSONSchema.new({}).to_json_schema).to eq(JSON.pretty_generate({}))
  end

  it "raises ArgumentError when the spec node is invalid" do
    data = { 'spec' => [1] }
    expect { SurveyToJSONSchema.new(data).to_json_schema }.to raise_error(ArgumentError)
  end

  it "raises ArgumentError when the spec node has unsupported type" do
    data = { 'spec' => ['type' => 'unknown'] }
    expect { SurveyToJSONSchema.new(data).to_json_schema }.to raise_error(ArgumentError)
  end

  shared_examples_for "valid_conversion" do
    it "matches" do
      expect(JSON.parse(SurveyToJSONSchema.new(data).to_json_schema)).to include(match)
    end
  end

  context "integer" do
    let(:json_type) { 'integer' }
    let(:spec_type) { 'integer' }
    let(:default_value) { 99 }
    let(:max_value) { 100 }
    let(:min_value) { 1 }
    let(:properties) { num_properties }

    it_behaves_like "valid_conversion"
  end

  context "float" do
    let(:json_type) { 'number' }
    let(:spec_type) { 'float' }
    let(:default_value) { 9.9 }
    let(:max_value) { 100.4 }
    let(:min_value) { 1.4 }
    let(:properties) { num_properties }

    it_behaves_like "valid_conversion"
  end

  context "text" do
    let(:json_type) { 'string' }
    let(:spec_type) { 'text' }
    let(:default_value) { "Hundley" }
    let(:max_value) { 10 }
    let(:min_value) { 4 }
    let(:properties) { string_properties }

    it_behaves_like "valid_conversion"
  end

  context "multiselect" do
    let(:json_type) { 'array' }
    let(:spec_type) { 'multiselect' }
    let(:default_value) { "Gnocchi" }
    let(:properties) { array_properties }
    let(:choice_array) { %w[a b c] }
    let(:choices) { "a\nb\nc" }

    it_behaves_like "valid_conversion"
  end

  context "multiplechoice" do
    let(:json_type) { 'string' }
    let(:spec_type) { 'multiplechoice' }
    let(:default_value) { "Gnocchi" }
    let(:properties) { single_select_properties }
    let(:choice_array) { %w[a b c] }
    let(:choices) { "a\nb\nc" }

    it_behaves_like "valid_conversion"
  end

  context "password" do
    let(:json_type) { 'string' }
    let(:spec_type) { 'password' }
    let(:default_value) { "Gnocchi" }
    let(:properties) { password_properties }

    it_behaves_like "valid_conversion"
  end

  context "textarea" do
    let(:json_type) { 'string' }
    let(:spec_type) { 'textarea' }
    let(:default_value) { "Gnocchi" }
    let(:properties) { string_properties }

    it_behaves_like "valid_conversion"
  end
end
