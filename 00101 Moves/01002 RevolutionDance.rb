module Battle
  class Move
    class RevolutionDance < StatusBoostedMove
      STATS_TO_INSPECT = %i[atk dfe spd ats dfs]

      # Get the basis atk for the move
      # @param user [PFM::PokemonBattler]
      # @param target [PFM::PokemonBattler]
      # @param ph_move [Boolean] true: physical, false: special
      # @return [Integer]
      def calc_sp_atk_basis(user, target, ph_move)
        basis_getters = STATS_TO_INSPECT.map { |stat| :"#{stat}_basis" }
        modifier_getters = STATS_TO_INSPECT.map { |stat| :"#{stat}_modifier" }

        stats = basis_getters.zip(modifier_getters).map do |basis, modifier|
          (user.send(basis) * user.send(modifier)).floor
        end

        @best_index = stats.each_with_index.max[1]
        log_data("Highest stat for this move is #{STATS_TO_INSPECT[@best_index]}")
        return user.send(basis_getters[@best_index])
      end

      # Statistic modifier calculation: ATK/ATS
      # @param user [PFM::PokemonBattler]
      # @param target [PFM::PokemonBattler]
      # @param ph_move [Boolean] true: physical, false: special
      # @return [Integer]
      def calc_atk_stat_modifier(user, target, ph_move)
        return super unless @best_index

        modifier = user.send(:"#{STATS_TO_INSPECT[@best_index]}_modifier")
        modifier = 1 if modifier < 1 && critical_hit?
        return modifier
      end

      # Check if the move must be boosted
      # @param user [PFM::PokemonBattler]
      # @param _target [PFM::PokemonBattler]
      # @return [Boolean]
      def boosted?(user, _target)
        return user.confused?
      end

      # Play the move animation
      # @param user [PFM::PokemonBattler]
      # @param targets [Array<PFM::PokemonBattler>]
      def play_animation(user, targets)
        Battle::Move.new(:teeter_dance, 0, 0, @scene).send(:play_animation, user, targets)
      end
    end

    Move.register(:s_revolution_dance, RevolutionDance)
  end
end
