# @rbs use Obg::Graph::Vertex

module Obg
  class References
    attr_reader :graph #: Graph

    # @rbs (Graph) -> void
    def initialize(graph)
      @graph = graph
    end

    # @rbs (String, ?Integer, ?Set[String]) { (Vertex vertex, Integer level, bool loop) -> void } -> void
    def each_reference_to(addr, level = 0, visited = Set[], &block)
      vertex = graph.vertexes.fetch(addr)

      if visited.include?(addr)
        yield vertex, level, true unless vertex.type == "IMEMO"
      else
        unless vertex.type == "IMEMO"
          yield vertex, level, false
          level += 1
        end
        visited << vertex.address

        graph.each_reference_to(vertex) do |ref|
          next if ref.address == addr
          each_reference_to(ref.address, level, visited, &block)
        end
      end
    end

    # @rbs (String, ?Integer, ?Set[String]) { (Vertex vertex, Integer level, bool loop) -> void } -> void
    def each_reference_from(addr, level = 0, visited = Set[], &block)
      vertex = graph.vertexes.fetch(addr)

      if visited.include?(addr)
        unless vertex.type == "IMEMO"
          yield vertex, level, true
        end
      else
        unless vertex.type == "IMEMO"
          yield vertex, level, false
          
          level += 1
        end

        visited << vertex.address

        graph.each_reference_from(vertex) do |ref|
          next if ref.address == addr
          each_reference_from(ref.address, level, visited, &block)
        end
      end
    end
  end
end
