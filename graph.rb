require_relative 'node'
require_relative 'edge'

class Graph
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

  def modularity clustering
    modularity = 0
    clustering.each do |cluster|
      modularity += cluster.inner_weight_fraction - cluster.total_weight_fraction ** 2
    end
    modularity
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

  def cnm
    clustering = singleton_clustering
    clusterings = []

    (clustering.size - 1).times do
      i, j = nil
      max = -Float::INFINITY
      clustering.permutation(2) .each do |perm|
        modularity_increase = 2 * (perm[0].weight_fraction_to(perm[1]) - perm[0].inner_weight_fraction * perm[1].inner_weight_fraction)
        puts "c1: #{perm[0]} c2: #{perm[1]} delta_mod: #{modularity_increase}"
        if i.nil? || j.nil? || modularity_increase > max
          max = modularity_increase
          i, j = perm[0], perm[1]
        end
      end

      clusterings << clustering
      merged = []
      clustering.each do |c|
        merged << c unless c == i || c == j
      end
      merged << i.merge(j)
      clustering = merged
    end

    max = -1
    final = nil
    clusterings.each do |c|
      q = modularity(c)
      if final.nil? || q > max
        final, max = c, q
      end
    end

    final
  end

  def singleton_clustering
    @nodes.values.map do |node|
      c = Cluster.new self
      c << node
      c
    end
  end

  def louvain
    puts "pass"
    clustering = singleton_clustering

    node_to_cluster = {}
    clustering.each do |cluster|
      node_to_cluster[cluster.nodes[0]] = cluster
    end

    increased = true
    while increased
      increased = false

      @nodes.each_value do |node|
        origin = node_to_cluster[node]
        best_move = 0
        cluster = nil
        node.each_adjacent do |connected_node|
          target = node_to_cluster[connected_node]
          move = origin.modularity_change_for_move node, target
          puts "node: #{node.id} origin: #{origin} cluster: #{target} delta_mod: #{move}"
          best_move, cluster = move, target if origin != target && (cluster.nil? || move > best_move)
        end

        if best_move > 0
          puts modularity clustering
          puts "move  val: #{best_move}"
          increased = true
          origin.remove node
          cluster << node
          node_to_cluster[node] = cluster
          puts modularity clustering
        end
      end
    end

    unless clustering.inject(true) { |result, cluster| result && cluster.nodes.size == 1 } # something changed
      g = Graph.new
      clustering.each_with_index do |cluster, i|
        (g.create_node i).data = cluster unless cluster.nodes.empty?
      end

      for i in 0...clustering.size
        for j in i...clustering.size
          weight = (clustering[i].weight_fraction_to(clustering[j]) * total_weight * ((i == j) ? 1 : 2))
          g.add_edge i, j,weight unless weight == 0
        end
      end

      meta_clustering = g.louvain
      clustering = []
      meta_clustering.each do |cluster|
        clustering << c = Cluster.new(self)
        cluster.nodes.each do |node|
          c.add node.data.nodes
        end
      end
    end
    clustering.reject { |cluster| cluster.nodes.size == 0 }
  end
end