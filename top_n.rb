require 'set'
require 'optparse'

class IntegerFileProcessor
  def initialize(file, max_size)
    raise ArgumentError, "Invalid file name: #{file}." unless file.is_a?(String)
    raise ArgumentError, "File '#{file}' does not exist." unless File.exist?(file)
    raise ArgumentError, "Invalid maximum size #{max_size}." unless max_size.is_a?(Integer)
    raise ArgumentError, 'Maximum size must be greater than zero.' unless max_size.positive?

    @min_pq = MinPriorityQueue.new
    @file = file
    @max_size = max_size
  end

  def read
    File.foreach(@file) do |line|
      integer_from_file = extract_integer(line)
      next if integer_from_file.nil?

      @min_pq.insert(integer_from_file)
      @min_pq.delete_min if @min_pq.size > @max_size     # Keep the heap size relevant
    end
    @min_pq
  end

  private

  def extract_integer(line)
    match = line.match(/^(\d+)$/)
    if match.nil?
      puts "Invalid line: '#{line.strip}'"
      nil
    else
      match[0].to_i
    end
  end
end

class MinPriorityQueue
  attr_reader :size

  def initialize
    @set = Set.new # Ensure heap does not have repeated values
    @priority_queue = [] # Array with position zero unused for simplicity
    @size = 0 # Size is also used as index
  end

  def empty?
    @size.zero?
  end

  def insert(value)
    return if @set.include?(value) # Skip insertion if value already exists

    @size += 1
    @priority_queue[@size] = value
    swim(@size)
  end

  def delete_min
    return if empty?

    min = @priority_queue[1]
    swap(1, @size)
    @size -= 1
    sink(1)
    min
  end

  private

  def less(index, other_index)
    (@priority_queue[index] <=> @priority_queue[other_index]).negative?
  end

  def swap(index, other_index)
    @priority_queue[index], @priority_queue[other_index] = @priority_queue[other_index], @priority_queue[index]
  end

  def swim(index)
    while index > 1 && less(index, index / 2)
      swap(index, index / 2)
      index /= 2
    end
  end

  def sink(index)
    while (2 * index) <= @size
      current_index = 2 * index
      current_index += 1 if current_index < @size && less(current_index + 1, current_index)
      break unless less(current_index, index)

      swap(current_index, index)
      index = current_index
    end
  end
end

class ArgumentParser
  class << self
    def parse(arguments)
      options = {}

      @opt_parser = OptionParser.new do |opts|
        opts.banner = "Usage: #{__FILE__} [options]"

        opts.on('-h', '--help', 'Prints this help') do
          puts opts
          exit
        end

        opts.on('-f FILE', '--file FILE', String, 'Absolute path to the file that will be read') do |f|
          options[:file] = f
        end

        opts.on('-t NUMBER', '--top NUMBER', Integer, 'Show top [NUMBER] largest integers in the file') do |n|
          raise ArgumentError, 'Number is lesser or equal to zero' unless n.positive?

          options[:top] = n
        end
      end

      @opt_parser.parse!(arguments)
      validate_options(options)
      options
    end

    private

    def validate_options(options)
      mandatory = %i[file top]
      missing = mandatory.select { |param| options[param].nil? }
      unless missing.empty?
        puts "Missing options: #{missing.join(', ')}"
        puts @opt_parser
        exit
      end
    end
  end
end

# "Main" execution
if $PROGRAM_NAME == __FILE__

  ARGV << '-h' if ARGV.empty?     # Automatically print help if no argument is passed
  options = ArgumentParser.parse(ARGV)

  file_processor = IntegerFileProcessor.new(options[:file], options[:top])
  min_pq = file_processor.read

  array = []
  array.push(min_pq.delete_min) until min_pq.empty?

  puts "\n-= RESULT =-"
  puts array.pop until array.empty?
end
