module Battle
  module Effects
    class Ability
      class GodHand < Ability
        # Return the specific proceed_internal if the condition is fulfilled
        # @param user [PFM::PokemonBattler] User of the move
        # @param _targets [PFM::PokemonBattler] Target of the move
        # @param move [Battle::Move] Move
        # @return [Symbol, nil] :proceed_internal_god_hand or nil
        def specific_proceed_internal(user, _targets, move)
          return if user != @target
          return unless move.punching?

          return :proceed_internal_god_hand
        end
      end

      register(:god_hand, GodHand)
    end
  end

  class Move
    # Internal procedure of a punching move from a Four-Star Punch ability user
    # @param user [PFM::PokemonBattler] User of the move
    # @param targets [Array<PFM::PokemonBattler>] Expected targets
    def proceed_internal_god_hand(user, targets)
      god_hand_hits = 0

      4.times do |i|
        @god_hand_punches = i + 1
        actual_targets = proceed_internal_precheck(user, targets)

        unless actual_targets
          user.add_move_to_history(self, targets)
          break if targets.none?(&:alive?) && target != :random_foe

          next
        end

        god_hand_hits += 1
        post_accuracy_check_effects(user, actual_targets)
        post_accuracy_check_move(user, actual_targets)
        play_animation(user, targets)

        deal_damage(user, actual_targets) &&
          god_hand_hits <= 2 &&
          effect_working?(user, actual_targets) &&
          deal_status(user, actual_targets) &&
          deal_stats(user, actual_targets) &&
          deal_effect(user, actual_targets)

        user.add_move_to_history(self, actual_targets)
        user.add_successful_move_to_history(self, actual_targets)
        @scene.visual.set_info_state(:move_animation)
        @scene.visual.wait_for_animation
      end
    end

    alias zhec_god_hand__initialize initialize
    def initialize(...)
      zhec_god_hand__initialize(...)
      @god_hand_punches = 0
    end

    alias zhec_god_hand__decrease_pp decrease_pp
    def decrease_pp(user, targets)
      return if @god_hand_punches > 2

      zhec_god_hand__decrease_pp(user, targets)
    end
  end
end
