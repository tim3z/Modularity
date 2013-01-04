require_relative 'graph'
require_relative 'cluster'
require 'koala'

def log s
  puts s
end

def k_4_k_4
  Graph.build [1,2, 1,3, 1,4, 2,3, 2,4, 3,4,
               5,6, 5,7, 5,8, 6,7, 6,8, 7,8,
               4,5, ]
end
def k_5_k_5
  Graph.build [1,2, 1,3, 1,4, 2,3, 2,4, 3,4,
               5,6, 5,7, 5,8, 6,7, 6,8, 7,8,
               9,10, 9,11, 9,12, 10,11, 10,12, 11,12,
               4,5, 4,9, 5,9, ]
end

def facebook_neighborhood token
  fb = Koala::Facebook::API.new token
  g = Graph.new

  me = fb.get_object('me')
  g.create_node(me['id']).data[:name] = me['name']
  friends = fb.get_connection('me', 'friends')
  friends.each do |friend|
    g.create_node(friend['id']).data[:name] = friend['name']
    g.add_edge me['id'], friend['id']
  end

  mutuals = []
  friends.each_slice(50) do |slice|
    mutuals += fb.batch do |batch|
      slice.each do |friend|
        batch.get_connections('me', "mutualfriends/#{friend['id']}")
      end
    end
  end
  for i in 0...friends.size
    if mutuals[i] # TODO mutuals not initialized??
      mutuals[i].each do |other_friend|
        unless g.get_node(friends[i]['id']).edges.map { |edge| edge.to.id }.include? other_friend['id']
          g.add_edge friends[i]['id'], other_friend['id']
        end
      end
    end
  end

  g
end

def to_dot clustering
  File.open 'dotfile', 'w' do |f|
    f.puts "graph {"
    i = -1
    clustering.each do |cluster|
      f.puts "subgraph cluster#{i += 1} {"
      cluster.nodes.each do |node|
        f.puts "\"#{node.data[:name]}\""
      end
      f.puts "}"
    end
    clustering.each do |cluster|
      cluster.nodes.each do |node|
        node.edges.each do |edge|
          f.puts "\"#{node.data[:name]}\" -- \"#{edge.to.data[:name]}\"" unless edge.to.data[:marked]
        end
        node.data[:marked] = true
      end
    end
    f.puts "}"
  end
end

def print_named_clustering c
  c.each do |cluster|
    puts cluster.nodes.map { |node| node.data[:name] }.inject { |all, name| all + ", " + name }
  end
  puts g.modularity c
end

def facebook
  puts "enter token"
  g = facebook_neighborhood gets

  log "graph obtained, starting clustering"
  c = g.louvain

  log "generating dotfile"
  to_dot c

  log "drawing graph"
  exec "fdp dotfile -Tpng -ograph.png"

  log "done"
end

facebook