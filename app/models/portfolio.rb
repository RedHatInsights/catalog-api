class Portfolio < ApplicationRecord
  include OwnerField
  include Discard::Model
  acts_as_tenant(:tenant)
  default_scope -> { kept }

  validates :name, :presence => true, :uniqueness => { :scope => %i(tenant_id discarded_at) }
  validates :image_url, :format => { :with => URI::DEFAULT_PARSER.make_regexp }, :allow_blank => true
  validates :enabled_before_type_cast, :format => { :with => /\A(true|false)\z/i }, :allow_blank => true

  has_many :portfolio_items, :dependent => :destroy

  before_discard :discard_portfolio_items
  before_undiscard :undiscard_portfolio_items

  def add_portfolio_item(portfolio_item)
    portfolio_items << portfolio_item
  end

  private

  CHILD_DISCARD_TIME_LIMIT = 30

  def discard_portfolio_items
    if portfolio_items.map(&:discard).any? { |result| result == false }
      portfolio_items.kept.each do |item|
        errors.add(item.name.to_sym, "PortfolioItem ID #{item.id}: #{item.name} failed to be discarded")
      end

      err = "Failed to discard items from Portfolio '#{name}' id: #{id} - not discarding portfolio"
      Rails.logger.error(err)
      raise Discard::DiscardError, err
    end
  end

  def undiscard_portfolio_items
    if portfolio_items_to_restore.map(&:undiscard).any? { |result| result == false }
      portfolio_items_to_restore.select(&:discarded?).each do |item|
        errors.add(item.name.to_sym, "PortfolioItem ID #{item.id}: #{item.name} failed to be restored")
      end

      err = "Failed to restore items from Portfolio '#{name}' id: #{id} - not restoring portfolio"
      Rails.logger.error(err)
      raise Discard::DiscardError, err
    end
  end

  def portfolio_items_to_restore
    portfolio_items
      .with_discarded
      .discarded
      .select { |item| (item.discarded_at.to_i - discarded_at.to_i).abs < CHILD_DISCARD_TIME_LIMIT }
  end
end
