RSpec.describe AccessControlEntry, :type => :model do
  it { is_expected.to have_db_column(:aceable_id).of_type(:integer) }
  it { is_expected.to have_db_column(:aceable_type).of_type(:string) }

  it { is_expected.to belong_to(:aceable) }
end
