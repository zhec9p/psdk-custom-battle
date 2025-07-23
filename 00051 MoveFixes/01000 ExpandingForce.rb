module Battle
  class Move
    class ExpandingForce
      # Test if the effect is working
      # @param user [PFM::PokemonBattler] User of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] Targets that will be affected by the move
      # @return [Boolean]
      def effect_working?(user, actual_targets)
        return user.grounded? && @logic.field_terrain_effect.psychic?
      end
    end
  end
end
