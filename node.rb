class Node
  attr_reader :id
  attr_accessor :data

  def initialize id
    @id = id
    @edges = []
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
    @weight = 0
    each_edge do |edge|
      @weight += edge.weight
    end
    @weight
  end
end