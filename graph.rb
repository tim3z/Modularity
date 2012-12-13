require_relative 'node'
require_relative 'edge'
require_relative 'modularity'

class Graph
  include Modularity

  attr_reader :nodes

  def initialize
    @nodes = {}
  end

  def create_node id
    @nodes[id] = Node.new id
  end

  def add_edge id_a, id_b, weight = 1.0
    node_a = (id_a.is_a? Node) ? id_a : @nodes[id_a]
    node_b = (id_b.is_a? Node) ? id_b : @nodes[id_b]
    node_a.add_edge(Edge.new node_a, node_b, weight)
    node_b.add_edge(Edge.new node_b, node_a, weight)
  end

  def total_weight
    return @total_weight if @total_weight
    @total_weight = 0
    each_node do |node|
      node.each_edge do |edge|
        @total_weight += edge.weight
      end
    end
    @total_weight /= 2.0
  end

  def each_node &block
    @nodes.each_value &block
  end

  def get_node id
    @nodes[id]
  end

  def fill edge_list
    i = 0
    while i < edge_list.length
      @nodes[edge_list[i]] ||= Node.new edge_list[i]
      @nodes[edge_list[i+1]] ||= Node.new edge_list[i+1]

      add_edge edge_list[i], edge_list[i+1]
      i += 2
    end
  end

  def self.build edge_list
    g = Graph.new
    g.fill edge_list
    g
  end

end