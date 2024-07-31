module Obg
  class CLI
    attr_reader :argv #: Array[String]

    # @rbs (Array[String]) -> void
    def initialize(argv)
      @argv = argv
    end

    def start #: Integer
      file = argv.shift or raise

      graph = Graph.new.load(Pathname(file))

      command = argv.shift or raise

      case command
      when "refs_to"
        addr = argv.shift or raise

        refs = References.new(graph)
        last_line = ""
        refs.each_reference_to(addr) do |ref, level, loop|
          buf = +" " * level

          buf << ref.to_s

          if loop
            buf << " (loop)"
          end

          puts buf if buf != last_line
          last_line = buf
        end
      when "refs_from"
        addr = argv.shift or raise

        refs = References.new(graph)
        last_line = ""
        refs.each_reference_from(addr) do |ref, level, loop|
          buf = +" " * level

          buf << ref.to_s

          if loop
            buf << " (loop)"
          end

          puts buf if buf != last_line
          last_line = buf
        end
      when "objects"
        query = argv.shift or raise

        query = Query::Q.parse(query)

        q = Query.new(graph)
        q.query([query]).each do |v|
          puts v
        end
      end

      0
    end
  end
end
