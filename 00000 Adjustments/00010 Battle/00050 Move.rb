module Battle
  class Move
    GENDER_MOVES = %i[attract captivate gmax_cuddle]
    SILK_MOVES = %i[sticky_web spider_web electroweb toxic_thread silk_trap string_shot]

    # Does the skill have a gender-related effect?
    # @return [Boolean]
    def gender?
      return GENDER_MOVES.include?(db_symbol)
    end

    # Is the move a silk, string, or web move?
    def web?
      return SILK_MOVES.include?(db_symbol)
    end
  end
end
