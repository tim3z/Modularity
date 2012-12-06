class Cluster
  attr_reader :nodes

  def initialize g
    @graph = g
    @nodes = []
  end

  def total_weight_fraction
    #nodes.inject(0) { |sum, node| sum + node.summed_edge_weight } / (2 * @graph.total_weight)
    weight = 0
    @nodes.each do |node|
      node.each_edge do |edge|
        weight += edge.weight
      end
    end
    weight / (2 * @graph.total_weight)
  end

  def inner_weight_fraction
    weight_fraction_to self
  end

  def weight_fraction_to cluster
    weight = 0
    @nodes.each do |node|
      node.each_edge do |edge|
        weight += edge.weight if cluster.nodes.include? edge.to
      end
    end
    weight / (2 * @graph.total_weight)
  end

  def << node
    @nodes << node
  end

  def add nodes
    @nodes += nodes
  end

  def merge other
    c = Cluster.new @graph
    c.add @nodes
    c.add other.nodes
    c
  end

  def remove node
    @nodes.delete node
  end

  def modularity_change_for_move node, to
    return nil unless @nodes.include? node

    k_ito, k_ifrom = 0, 0
    node.each_edge do |edge|
      k_ifrom += edge.weight if @nodes.include? edge.to
      k_ito += edge.weight if to.nodes.include? edge.to
    end

    ((k_ito - to.total_weight_fraction * node.summed_edge_weight) - k_ifrom + (total_weight_fraction - node.summed_edge_weight / (2 * @graph.total_weight)) * node.summed_edge_weight) / @graph.total_weight
  end

  def merge! other
    @nodes += other.nodes
    self
  end

  def to_s
    s = ""
    @nodes.each do |n|
      s << n.id.to_s << " "
    end
    s
  end
end