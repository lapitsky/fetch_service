require 'rails_helper'

RSpec.describe Payer do
  subject { build(:payer) }

  it 'validates presence of name' do
    expect(subject).to validate_presence_of(:name)
  end

  it 'validates uniqueness of name' do
    expect(subject).to validate_uniqueness_of(:name)
  end
end
