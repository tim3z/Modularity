class Node
  attr_reader :id, :edges
  attr_accessor :data

  def initialize id
    @id = id
    @edges = []
    @data = {}
  end

  def add_edge e
    @edges << e
    @weight = nil
  end

  def == other
    @id == other.id
  end

  def each_edge &block
    @edges.each &block
  end

  def each_adjacent
    each_edge { |edge| yield edge.to }
  end

  def summed_edge_weight
    return @weight unless @weight.nil?
    @weight = @edges.inject(0) { |sum, edge| sum + edge.weight }
  end

  def simple_summed_edge_weight
    @edges.inject(0) { |sum, edge| sum + (edge.weight / ((edge.loop? ? 2 : 1))) }
  end
end