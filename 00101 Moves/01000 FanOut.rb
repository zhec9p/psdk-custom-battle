module Battle
  class Move
    class FanOut < Move
      # Function that tests if the user is able to use the move
      # @param user [PFM::PokemonBattler] User of the move
      # @param targets [Array<PFM::PokemonBattler>] Expected targets
      # @note Thing that prevents the move from being used should be defined by :move_prevention_user Hook
      # @return [Boolean] If the procedure can continue
      def move_usable_by_user(user, _targets)
        return false unless super
        return show_usage_failure(user) && false if user.effects.has?(:fan_out)

        return true
      end

      # Function that deals the effect to the creature
      # @param user [PFM::PokemonBattler] User of the move
      # @param _actual_targets [Array<PFM::PokemonBattler>] Targets that will be affected by the move
      def deal_effect(user, actual_targets)
        actual_targets.each do |target|
          next if target.effects.has?(:fan_out)

          target.effects.add(Effects::FanOut.new(logic, target, duration))
          @logic.scene.display_message_and_wait(message(target))
        end
      end

      private

      # Number of turns the effect works
      # @return Integer
      def duration
        return 4
      end

      # Message when the effect begins
      # @param target [PFM::PokemonBattler]
      # @return [String]
      def message(target)
        return parse_text_with_pokemon(1000, 6, target)
      end
    end

    # Internal procedure of a FanOut-affected user's move
    # @param user [PFM::PokemonBattler] User of the move
    # @param targets [Array<PFM::PokemonBattler>] Expected targets
    def proceed_internal_fan_out(user, targets)
      actual_targets = fan_out_battler_targets(user, targets)
      @fanned_out = one_target? && actual_targets.length > targets.length
      proceed_internal(user, actual_targets)
    end

    # Convert a FanOut-affected user's single-target move to multi-target
    # @param user [PFM::PokemonBattler] user of the move
    # @param targets [Array<PFM::PokemonBattler>] Initial targets
    # @return [Array<PFM::PokemonBattler>] New targets
    def fan_out_battler_targets(user, targets)
      return if targets.length > 1

      attacking_foe = targets.any? { |t| user.bank != t.bank }
      actual_targets = targets.clone
      actual_targets += logic.foes_of(user) if target == :random_foe
      actual_targets += logic.adjacent_foes_of(user) if target == :adjacent_foe
      actual_targets += logic.adjacent_allies_of(user) if target == :adjacent_ally
      actual_targets += logic.adjacent_allies_of(user) + [user] if target == :user_or_adjacent_ally
      actual_targets += logic.send(attacking_foe ? :adjacent_foes_of : :adjacent_allies_of, user) if target == :adjacent_pokemon
      actual_targets += logic.send(attacking_foe ? :foes_of : :allies_of, user) if target == :any_other_pokemon

      return actual_targets.uniq
    end

    alias zhec_fan_out_initialize initialize
    def initialize(...)
      zhec_fan_out_initialize(...)
      @fanned_out = false
    end

    alias zhec_fan_out_calc_mod1_tvt calc_mod1_tvt
    def calc_mod1_tvt(...)
      return 0.75 if @fanned_out

      return zhec_fan_out_calc_mod1_tvt(...)
    end

    register(:s_fan_out, FanOut)
  end

  module Effects
    class FanOut < PokemonTiedEffectBase
      # Create a new FanOut effect
      # @param logic [Battle::Logic]
      # @param target [PFM::PokemonBattler]
      # @param duration [Integer] Number of turns the effect should last
      def initialize(logic, target, duration = Float::INFINITY)
        super(logic, target)
        self.counter = duration
      end

      # Get the name of the effect
      # @return [Symbol]
      def name
        return :fan_out
      end

      # Return the specific proceed_internal if the condition is fulfilled
      # @param user [PFM::PokemonBattler] User of the move
      # @param target [PFM::PokemonBattler] Target of the move
      # @param move [Battle::Move] Move
      # @return [Symbol, nil] :proceed_internal_fan_out or nil
      def specific_proceed_internal(user, targets, move)
        return unless move.one_target?
        return if move.db_symbol == :expanding_force && move.effect_working?(user, targets)

        return :proceed_internal_fan_out
      end

      # Function called when the effect has been deleted from the effects handler
      def on_delete
        return if @pokemon.dead?

        @logic.scene.display_message_and_wait(message(@pokemon))
      end

      private

      # Transfer the effect to the given creature via Baton Pass
      # @param with [PFM::PokemonBattler] The creature switched in
      # @return [Battle::Effects::PokemonTiedEffectBase, nil] The effect to give to the switched-in creature, nil if
      #         this effect isn't transferrable via Baton Pass
      def baton_switch_transfer(with)
        return self.class.new(@logic, with, @counter)
      end

      # Message when the effect ends
      # @param target [PFM::PokemonBattler]
      # @return [String]
      def message(target)
        return parse_text_with_pokemon(1000, 9, target)
      end
    end
  end
end
