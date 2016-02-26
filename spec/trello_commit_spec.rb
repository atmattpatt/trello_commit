require 'spec_helper'

describe TrelloCommit do
  it 'has a version number' do
    expect(TrelloCommit::VERSION).not_to be nil
  end

  it 'does something useful' do
    expect(false).to eq(true)
  end
end
