module Obg
  class Reachability
    attr_reader :graph #: Graph

    # @rbs (Graph) -> void
    def initialize(graph)
      @graph = graph
    end

    def reachable_from_root() #: Set[String]
      set = Set[]

      graph.roots.each do |root|
        root.references.each do |ref|
          reachable_from(ref, set)
        end
      end

      set
    end

    # @rbs (String | Graph::Vertex, ?Set[String]) -> Set[String]
    def reachable_from(vertex, set = Set[])
      vertex = vertex.address if vertex.is_a?(Graph::Vertex)

      unless set.include?(vertex)
        set << vertex
        graph.refs_from[vertex]&.each do |v|
          reachable_from(v, set)
        end
      end

      set
    end
  end
end
