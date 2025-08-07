module ZV
  # Class for generating N random integers that add up to given sum
  # @see https://stackoverflow.com/questions/61393463/is-there-an-efficient-way-to-generate-n-random-integers-in-a-range-that-have-a-g/
  class PermutationPartitionGenerator
    # @param num_ints [Integer] Number of integers in a set
    # @param min [Integer] Smallest possible integer in a set
    # @param max [Integer] Largest possible integer in a set
    # @param sum [Integer] Sum that all numbers in every set must add up to
    def initialize(num_ints, min:, max:, sum:)
      raise 'num_ints should be positive' if num_ints <= 0

      @num_ints = num_ints
      @min = min
      @max = max
      @range = max - min
      raise 'min cannot be greater than max' if @range < 0

      @adjusted_sum = sum - num_ints * min
      raise 'sum is too small' if @adjusted_sum < 0
      raise 'sum is too large' if @adjusted_sum > num_ints * @range

      @distribution_table = calculate_distribution_table
    end

    # Generate a random permutation of integers
    # @param rng [Random]
    # @return [Array<Integer>]
    def get(rng)
      p = Array.new(@num_ints, 0)
      s = @adjusted_sum

      (@num_ints - 1).downto(0) do |i|
        t = rng.rand * @distribution_table[i + 1][s]
        table_row = @distribution_table[i]
        old_sum = s
        lower_bound = [0, s - @range].max
        s += 1

        loop do
          s -= 1
          t -= table_row[s]
          break if t <= 0 || s <= lower_bound
        end

        p[i] = @min + (old_sum - s)
      end
      raise 's != 0' if s != 0

      return p
    end

    private

    def calculate_distribution_table
      table = Array.new(@num_ints + 1) { Array.new(@adjusted_sum + 1, 0) }
      a = Array.new(@adjusted_sum + 1, 0)
      b = Array.new(@adjusted_sum + 1, 0)
      a[0] = 1
      table[0][0] = 1.0

      (1..@num_ints).each do |n|
        t = table[n]

        (0..@adjusted_sum).each do |s|
          b[s] = [0, s - @range].max.upto(s).inject(0) { |sum, i| sum + a[i] }
          t[s] = b[s].to_f
        end

        a, b = b, a
      end

      return table
    end
  end
end
