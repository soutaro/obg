require "readline"

trap("INT", "SIG_IGN")

module Obg
  class CLI
    attr_reader :argv #: Array[String]

    # @rbs (Array[String]) -> void
    def initialize(argv)
      @argv = argv
    end

    LoadCommand = __skip__ = Data.define(
      :queries #: Array[Query::Q]
    )
    PopCommand = Data.define()
    UpCommand = __skip__ = Data.define()
    DownCommand = __skip__ = Data.define()
    SelectCommand = __skip__ = Data.define(
      :indexes #: Array[Integer]
    )
    SampleCommand = __skip__ = Data.define
    AddCommand = __skip__ = Data.define(
      :query #: Query::Q
    )

    # @rbs! type command = LoadCommand | PopCommand | UpCommand | DownCommand | SelectCommand | SampleCommand | AddCommand

    # @rbs (command, Cursor) -> Cursor?
    def process_command(command, cursor)
      case command
      when LoadCommand
        Cursor.new(cursor.graph, Query.new(cursor.graph).query(command.queries), cursor)
      when PopCommand
        cursor.last_cursor || cursor
      when UpCommand
        cursor.up
      when DownCommand
        cursor.down
      when SelectCommand
        cursor.select(command.indexes)
      when SampleCommand
        cursor.vertexes.take(10).each do |vertex|
          puts vertex
        end
        nil
      when AddCommand
        cursor.add(command.query)
      end
    end

    def parse_command(string) #: command?
      case string
      when /\Aload (.+)\z/
        qs = $1 or raise
        queries = qs.split(/ +/).map {|q| Query::Q.parse(q) }
        LoadCommand.new(queries)
      when "pop"
        PopCommand.new
      when "up"
        UpCommand.new
      when "down"
        DownCommand.new
      when "sample"
        SampleCommand.new
      when /\Aselect (.+)\z/
        is = $1 or raise
        indexes = is.split(/ +/).map(&:to_i)
        SelectCommand.new(indexes)
      end
    end

    def start #: Integer
      file = argv.shift or raise

      graph = Graph.new.load(Pathname(file))
      cursor = Cursor.new(graph, [], nil)

      while true
        line = Readline.readline("Command >> ", true) or break

        if command = parse_command(line)
          STDOUT.puts
          if c2 = process_command(command, cursor)
            cursor = c2

            unless graph.vertexes.empty?
              STDOUT.puts "#{cursor.vertexes.size} vertexes (#{(cursor.vertexes.size * 100.0 / graph.vertexes.size).to_i}%)"
              cursor.group_by_location.take(15).each_with_index do |(location, vertexes), index|
                i = sprintf("%3d", index)
                p =
                  if cursor.vertexes.empty?
                    "N/A"
                  else
                    "#{(vertexes.size.to_f * 100 / cursor.vertexes.size).to_i}%"
                  end
                STDOUT.puts "#{i}: #{location} (#{vertexes.size} / #{p})"
              end
            else
              STDOUT.puts "No vertexes"
            end
          end
          STDOUT.puts
        end
      end

      0
    end
  end
end
