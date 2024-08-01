module Obg
  class Query
    Q = __skip__ = Data.define(
      :class_name, #: String
      :file, #: String?
      :line, #: Integer?
    )

    class Q
      # @rbs (String) -> Q
      def self.parse(string)
        class_name, rest = string.split(/@/)
        class_name or raise

        if rest
          file, line = rest.split(/:/)
        end

        Q.new(class_name, file, line&.to_i)
      end
    end

    attr_reader :graph #: Graph

    # @rbs (Graph) -> void
    def initialize(graph)
      @graph = graph
    end

    # @rbs (Array[Q]) -> Array[Graph::Vertex]
    def query(qs)
      graph.vertexes.each_value.select do |vertex|
        qs.any? {|q| test_query(q, vertex) }
      end
    end

    # @rbs (Q, Graph::Vertex) -> bool
    def test_query(q, vertex)
      class_name = vertex.class_name or return false

      if q.class_name.end_with?("*")
        unless class_name.start_with?(q.class_name.delete_suffix("*"))
          return false
        end
      else
        unless class_name == q.class_name
          return false
        end
      end
      if q.file
        return false unless vertex.file == q.file
      end
      if q.line
        return false unless vertex.line == q.line
      end

      true
    end
  end
end
