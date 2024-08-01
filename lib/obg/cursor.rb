module Obg
  class Cursor
    attr_reader :graph #: Graph

    attr_reader :vertexes #: Array[Graph::Vertex]

    attr_reader :last_cursor #: Cursor?

    # @rbs (Graph, Array[Graph::Vertex], Cursor?) -> void
    def initialize(graph, vertexes, last_cursor)
      @graph = graph
      @vertexes = vertexes
      @last_cursor = last_cursor
    end

    # @rbs () { (Graph::Vertex) -> void } -> void
    #    | () -> Enumerator[Graph::Vertex, void]
    def each_vertex(&block)
      if block
        vertexes.each(&block)
      else
        vertexes.each
      end
    end

    # @rbs () -> Array[[String?, Array[Graph::Vertex]]]
    def group_by_location
      vertexes.group_by { "#{_1.name} @ #{_1.location}" }.entries.sort_by { -_2.size }
    end

    # @rbs (Array[Integer]) -> Cursor
    def select(indexes)
      vs = [] #: Array[Graph::Vertex]
      groups = group_by_location

      indexes.each do
        vs.concat(groups[_1][1])
      end

      Cursor.new(graph, vs, self)
    end

    # @rbs (Array[Integer]) -> Cursor
    def up(indexes)
      if indexes.empty?
        vs = Set.new(vertexes).flat_map do |vertex|
          graph.each_reference_to(vertex).to_a
        end
      else
        vs = [] #: Array[Graph::Vertex]

        group_by_location.each_with_index do |(location, group), i|
          if indexes.include?(i)
            group.each do |vertex|
              graph.each_reference_to(vertex) do |v|
                vs << v
              end
            end
          else
            vs.concat(group)
          end
        end
      end
      vs = Set.new(vs).to_a
      Cursor.new(graph, vs, self)
    end

    # @rbs (Array[Integer]) -> Cursor
    def down(indexes)
      if indexes.empty?
        vs = Set.new(vertexes).flat_map do |vertex|
          graph.each_reference_from(vertex).to_a
        end
      else
        vs = [] #: Array[Graph::Vertex]

        group_by_location.each_with_index do |(location, group), i|
          if indexes.include?(i)
            group.each do |vertex|
              graph.each_reference_from(vertex) do |v|
                vs << v
              end
            end
          else
            vs.concat(group)
          end
        end
      end
      
      vs = Set.new(vs).to_a
      Cursor.new(graph, vs, self)
    end

    # @rbs (Query::Q) -> Cursor
    def add(query)
      vs = Query.new(graph).query([query])
      Cursor.new(graph, vertexes + vs, self)
    end
  end
end
