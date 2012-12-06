class Edge
  attr_accessor :weight
  attr_reader :from, :to

  def initialize node_a, node_b, weight = 1.0
    @from = node_a
    @to = node_b
    @weight = weight
  end

  def loop?
    @from == @to
  end
end