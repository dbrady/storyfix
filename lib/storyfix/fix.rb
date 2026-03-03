module Storyfix
  class Fix
    RESERVED_NAMES = %w[list add remove show get-config set-config list-configs help version].freeze

    attr_reader :name, :description, :body

    def initialize(name:, description:, body:)
      @name = name
      @description = description
      @body = body
    end

    def render(args = [])
      result = @body.dup
      
      required_args = result.scan(/\{\{(\d+)\}\}/).flatten.map(&:to_i).max || 0
      
      if args.length < required_args
        raise ArgumentError, "Fix '#{@name}' requires exactly #{required_args} arguments, but got #{args.length}"
      end
      
      if args.length > required_args
        raise ArgumentError, "Fix '#{@name}' requires exactly #{required_args} arguments, but got #{args.length}"
      end

      args.each_with_index do |arg, index|
        result.gsub!("{{#{index + 1}}}", arg.to_s)
      end

      result
    end

    class Store
      def initialize(db)
        @db = db
      end

      def find(name)
        row = @db.query_single("SELECT name, description, body FROM fixes WHERE name = ?", name)
        return nil unless row
        
        Fix.new(name: row[:name], description: row[:description], body: row[:body])
      end

      def all
        @db.query("SELECT name, description, body FROM fixes ORDER BY name ASC").map do |row|
          Fix.new(name: row[:name], description: row[:description], body: row[:body])
        end
      end

      def create(name:, description:, body:)
        if Fix::RESERVED_NAMES.include?(name.to_s.downcase)
          raise ArgumentError, "Cannot create fix with reserved name '#{name}'"
        end

        @db.execute(<<~SQL, name, description, body, description, body)
          INSERT INTO fixes (name, description, body) VALUES (?, ?, ?)
          ON CONFLICT(name) DO UPDATE SET description = ?, body = ?
        SQL
      end

      def delete(name)
        @db.execute("DELETE FROM fixes WHERE name = ?", name)
      end
    end
  end
end
