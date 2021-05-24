describe Catalog::OrderProcessSequence do
  let(:tenant) { create(:tenant) }
  let!(:order_process1) { create(:order_process, :tenant => tenant) }
  let!(:order_process2) { create(:order_process, :tenant => tenant) }
  
  it 'moves an order process down by number' do
    Catalog::OrderProcessSequence.new(order_process1, 1).process
    expect(OrderProcess.pluck(:id)).to eq([order_process2.id, order_process1.id])
  end

  it 'moves an order process up by number' do
    Catalog::OrderProcessSequence.new(order_process2, -1).process
    expect(OrderProcess.pluck(:id)).to eq([order_process2.id, order_process1.id])
  end

  it 'moves an order process to the bottom' do
    Catalog::OrderProcessSequence.new(order_process1, 'bottom').process
    expect(OrderProcess.pluck(:id)).to eq([order_process2.id, order_process1.id])
  end

  it 'moves an order process to the top' do
    Catalog::OrderProcessSequence.new(order_process2, 'top').process
    expect(OrderProcess.pluck(:id)).to eq([order_process2.id, order_process1.id])
  end
end
