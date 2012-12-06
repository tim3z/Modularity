require_relative 'graph'
require_relative 'cluster'

g = Graph.build [1,2, 1,3, 1,4, 2,3, 2,4, 3,4, 4,5, 5,6, 5,7, 5,8, 6,7, 6,8, 7,8]
#ids = (1..6).to_a
#
#c = Cluster.new g
#ids.each { |id| c << g.get_node(id) }
#puts g.modularity [c]
#
#puts g.modularity g.singleton_clustering

puts g.cnm
