class Tag < ApplicationRecord
  acts_as_tenant(:tenant)

  belongs_to :tenant

  has_many :portfolio_tags, :dependent => :destroy
  has_many :portfolios, :through => :portfolio_tags

  has_many :portfolio_item_tags, :dependent => :destroy
  has_many :portfolio_items, :through => :portfolio_item_tags

  after_create    { update_portfolio_stats }
  after_destroy   { update_portfolio_stats }

  def to_tag_string
    "/#{namespace}/#{name}".tap { |string| string << "=#{value}" if value.present? }
  end

  def self.create!(attributes)
    attributes = attributes.with_indifferent_access

    super(attributes.except(:tag).merge(parse(attributes[:tag])))
  end

  def self.parse(tag_string)
    return {} if tag_string.blank?

    raise ArgumentError, "must start with /" unless tag_string.start_with?("/")

    tag_params = {}.tap do |tag_values|
      keyspace, tag_values[:value]       = tag_string.split("=")
      _nil, namespace, tag_values[:name] = keyspace.split("/", 3)
      tag_values[:namespace]             = namespace.presence
    end

    # FIXME: Doesn't exist on topo - but blows up when there are nil values in the db.
    tag_params.transform_values { |e| e || "" }
  end

  private

  def update_portfolio_stats
    portfolios.each(&:update_statistics)
  end
end
