class Cluster
  attr_reader :nodes

  def initialize g
    @graph = g
    @nodes = []
  end

  def total_weight_fraction
    total_weight / (2 * @graph.total_weight)
  end

  def total_weight
    nodes.inject(0) { |sum, node| sum + node.summed_edge_weight }
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
    node.data[:cluster] = self
  end

  def add nodes
    @nodes += nodes
    nodes.each { |node| node.data[:cluster] = self }
  end

  def merge other
    c = Cluster.new @graph
    c.add @nodes
    c.add other.nodes
    c
  end

  def remove node
    @nodes.delete node
    node.data[:cluster] = nil
  end

  def modularity_change_for_move node, to
    return nil unless @nodes.include? node

    k_ito, k_ifrom = 0, 0
    node.each_edge do |edge|
      k_ifrom += edge.weight if edge.to.data[:cluster] == self && edge.to != node
      k_ito += edge.weight if edge.to.data[:cluster] == to && edge.to != node
    end

    ((k_ito - k_ifrom) / @graph.total_weight) - node.summed_edge_weight * ((to.total_weight - (node.data[:cluster] == to ? node.summed_edge_weight : 0)) - (self.total_weight - node.summed_edge_weight)) / (2 * @graph.total_weight ** 2)
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

  def self.singleton_clustering graph
    graph.nodes.values.map do |node|
      c = Cluster.new graph
      c << node
      c
    end
  end
end