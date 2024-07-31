module Obg
  class Graph
    Root = __skip__ = Data.define(
      :type, #: "ROOT"
      :root, #: String
      :references #: Array[String]
    )
    Vertex = __skip__ = Data.define(
      :type, #: String
      :address, #: String
      :references, #: Array[String]
      :object, #: untyped
      :graph, #: Graph
    )
    class Vertex
      def name #: String
        case type
        when "CLASS", "MODULE"
          "#{object[:name]}(#{type})"
        else
          if klass_addr = object[:class]
            if klass = graph.vertexes.fetch(klass_addr)
              if klass_name = (klass.object[:name] || klass.object[:real_class_name])
                return "#{klass_name}(#{type})"
              end
            end
          end

          "(unknown:#{type})"
        end
      end

      def class_name #: String?
        case type
        when "CLASS"
          "Class"
        when "MODULE"
          "Module"
        else
          if klass_addr = object[:class]
            if klass = graph.vertexes.fetch(klass_addr)
              if klass_name = (klass.object[:name] || klass.object[:real_class_name])
                klass_name
              end
            end
          end
        end
      end

      def file #: String?
        object[:file]
      end

      def line #: Integer?
        object[:line]
      end

      def location #: String?
        file = object[:file]
        line = object[:line]

        if file && line
          "#{file}:#{line}"
        end
      end

      def method #: String?
        object[:method]
      end

      def to_s #: String
        buf = +"#{name} (#{address})"

        if loc = location
          buf << " at #{loc}"
        end

        if m = method
          buf << " in #{m}"
        end

        buf
      end
    end

    attr_reader :roots #: Array[Root]
    attr_reader :vertexes #: Hash[String, Vertex]

    # Set of references from objects
    attr_reader :refs_from #: Hash[String, Set[String]]

    # Set of references to objects
    attr_reader :refs_to #: Hash[String, Set[String]]

    def initialize #: void
      @roots = []
      @vertexes = {}
      @refs_from = {}
      @refs_to = {}
    end

    # @rbs (Pathname) -> self
    def load(file)
      roots.clear
      vertexes.clear

      file.each_line do |line|
        json = JSON.parse(line, symbolize_names: true)
        case json[:type]
        when "ROOT"
          roots << Root.new("ROOT", json[:root], json[:references])
        else
          addr = json.fetch(:address) #: String
          references = json.fetch(:references, []) #: Array[String]

          references.each do |ref|
            (refs_from[addr] ||= Set.new) << ref
            (refs_to[ref] ||= Set.new) << addr
          end

          vertexes[addr] = Vertex.new(json[:type], addr, references, json, self)
        end
      end

      self
    end

    # @rbs (String | Vertex) { (Vertex) -> void } -> void
    #    | (String | Vertex) -> Enumerator[Vertex, void]
    def each_reference_from(addr)
      if block_given?
        addr = addr.address if addr.is_a?(Vertex)

        refs_from.fetch(addr, nil)&.each do |ref|
          yield vertexes.fetch(ref)
        end
      else
        enum_for __method__ || raise, addr
      end
    end

    # @rbs (String | Vertex) { (Vertex) -> void } -> void
    #    | (String | Vertex) -> Enumerator[Vertex, void]
    def each_reference_to(addr)
      if block_given?
        addr = addr.address if addr.is_a?(Vertex)

        refs_to.fetch(addr, nil)&.each do |ref|
          yield vertexes.fetch(ref)
        end
      else
        enum_for __method__ || raise, addr
      end
    end
  end
end

