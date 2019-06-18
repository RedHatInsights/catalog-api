require 'json'

class SurveyToJSONSchema
  DEFAULT_TITLE = 'Ansible Survey'.freeze
  DEFAULT_DESCRIPTION = 'Ansible Survey Description'.freeze
  SUPPORTED_TYPES = %w[integer float multiplechoice multiselect password text textarea].freeze

  def initialize(survey)
    @survey = survey.kind_of?(String) ? JSON.parse(survey) : survey
    @converted_hash = survey_valid? ? initialize_json_schema : {}
  end

  def to_json_schema
    @survey.fetch('spec', []).each { |item| add_property(item) }
    JSON.pretty_generate(@converted_hash)
  end

  private

  def add_property(item)
    raise ArgumentError, "Invalid Item" unless item.kind_of?(Hash)
    raise ArgumentError, "Unsupported Type #{item['type']}" unless SUPPORTED_TYPES.include?(item['type'])

    @converted_hash['required'] << item['variable'] if item['required']
    @converted_hash['properties'][item['variable']] = send("convert_#{item['type']}".to_sym, item)
  end

  def survey_valid?
    @survey.key?('spec') && @survey['spec'].kind_of?(Array)
  end

  def initialize_json_schema
    { 'title'                => @survey['name'] || DEFAULT_TITLE,
      'description'          => @survey['description'] || DEFAULT_DESCRIPTION,
      'type'                 => 'object',
      '$schema'              => 'http://json-schema.org/schema#',
      'required'             => [],
      'properties'           => {},
      'additionalProperties' => false }
  end

  def convert_integer(item)
    { 'type'    => 'integer',
      'minimum' => item['min'],
      'maximum' => item['max'] }.compact.merge(basic(item))
  end

  def convert_float(item)
    { 'type'    => 'number',
      'minimum' => item['min'],
      'maximum' => item['max'] }.compact.merge(basic(item))
  end

  def convert_password(item)
    convert_text(item).merge('format' => 'password')
  end

  def convert_textarea(item)
    convert_text(item)
  end

  def convert_text(item)
    { 'type'      => 'string',
      'minLength' => item['min'],
      'maxLength' => item['max'] }.compact.merge(basic(item))
  end

  def convert_multiselect(item)
    { 'type'  => 'array',
      'items' => { 'type' => 'string',
                   'enum' => item['choices'].split("\n")}}.merge(basic(item))
  end

  def convert_multiplechoice(item)
    {'type' => 'string',
     'enum' => item['choices'].split("\n")}.merge(basic(item))
  end

  def basic(item)
    {'title'       => item['question_name'],
     'description' => item['question_description'],
     'default'     => default(item)}.compact
  end

  def default(item)
    item['type'] == 'multiselect' ? [item['default']] : item['default']
  end
end
