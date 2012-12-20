require_relative 'graph'
require_relative 'cluster'
require 'koala'

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

  my_id = fb.get_object('tim.zeitz')['id']
  g.create_node(my_id).data[:name] = 'Tim Zeitz'
  friends = fb.get_connection('me', 'friends')
  friends.each do |friend|
    g.create_node(friend['id']).data[:name] = friend['name']
    g.add_edge my_id, friend['id']
  end
  friends.each do |friend|
    fb.get_connections('me', "mutualfriends/#{friend['id']}").each do |other_friend|
      unless g.get_node(friend['id']).edges.map { |edge| edge.to.id }.include? other_friend['id']
        g.add_edge friend['id'], other_friend['id']
      end
    end
  end

  g
end

#g = facebook_neighborhood

c = g.louvain
c.each do |cluster|
  puts cluster.nodes.map { |node| node.data[:name] }.inject { |all, name| all + ", " + name }
end
puts g.modularity c
