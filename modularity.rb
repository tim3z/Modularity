module Modularity

  def modularity clustering
    clustering.inject(0) { |sum, cluster| sum + cluster.inner_weight_fraction - cluster.total_weight_fraction ** 2 }
  end

  def cnm
    clustering = Cluster.singleton_clustering self
    clusterings = []

    (clustering.size - 1).times do
      i, j = nil
      max = -Float::INFINITY
      clustering.permutation(2) .each do |perm|
        modularity_increase = 2 * (perm[0].weight_fraction_to(perm[1]) - perm[0].total_weight_fraction * perm[1].total_weight_fraction)
        if i.nil? || j.nil? || modularity_increase > max
          max = modularity_increase
          i, j = perm[0], perm[1]
        end
      end

      clusterings << [clustering, modularity(clustering)]
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
      if final.nil? || c[1] > max
        final, max = *c
      end
    end

    final.each { |cluster| cluster.reapply_nodes }
    final
  end

  def louvain
    log "pass"
    clustering = Cluster.singleton_clustering self

    increased = true
    while increased
      increased = false

      @nodes.each_value do |node|
        origin = node.data[:cluster]
        best_move = 0
        cluster = nil
        node.each_adjacent do |connected_node|
          target = connected_node.data[:cluster]
          move = origin.modularity_change_for_move node, target
          best_move, cluster = move, target if origin != target && (cluster.nil? || move > best_move)
        end

        if best_move > 0
          increased = true
          origin.remove node
          # TODO O(n^2)
          cluster << node
        end
      end
    end

    clustering.reject! { |cluster| cluster.nodes.size == 0 }
    unless clustering.inject(true) { |result, cluster| result && cluster.nodes.size == 1 } # something changed
      g = Graph.new
      clustering.each_with_index { |cluster, i| (g.create_node i).data[:subgraph] = cluster }

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
          c.add node.data[:subgraph].nodes
        end
      end
    end
    clustering
  end
end