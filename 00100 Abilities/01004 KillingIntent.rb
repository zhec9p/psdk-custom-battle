module Battle
  module Effects
    class Ability
      class KillingIntent < Ability
        # Function called when a creature has actually switched with another one
        # @param handler [Battle::Logic::SwitchHandler]
        # @param _who [PFM::PokemonBattler]
        # @param with [PFM::PokemonBattler]
        def on_switch_event(handler, _who, with)
          return if with != @target

          foes = handler.logic.foes_of(with).select { |foe| foe.position == with.position }
          return if foes.empty?

          foe = foes.sample(random: handler.logic.generic_rng)
          apply_effect(handler, with, foe)
        end

        private

        # Message for the Killing Intent victim
        # @param target [PFM::PokemonBattler]
        # @return [String]
        def message(target)
          return parse_text_with_pokemon(1000, 21, target)
        end

        # Apply the flinching effect
        # @param handler [Battle::Logic::ChangeHandlerBase]
        # @param user [PFM::PokemonBattler]
        # @param target [PFM::PokemonBattler]
        def apply_effect(handler, user, target)
          handler.scene.visual.show_ability(user)
          target.effects.add(Battle::Effects::KillingIntent.new(handler.logic, target, user))
          Battle::Move.new(:scary_face, 0, 0, handler.scene).send(:play_animation, user, [target])
          handler.scene.display_message_and_wait(message(target))
        end
      end

      register(:killing_intent, KillingIntent)
    end

    class KillingIntent < Flinch
      # @param logic [Battle::Logic]
      # @param target [PFM::PokemonBattler]
      # @param origin [PFM::PokemonBattler]
      def initialize(logic, target, origin)
        super(logic, target)
        @origin = origin
        self.counter = 2
      end

      # Function called when we try to use a move as the user (returns :prevent if user fails)
      # @param user [PFM::PokemonBattler]
      # @param targets [Array<PFM::PokemonBattler>]
      # @param move [Battle::Move]
      # @return [:prevent, nil] :prevent if the move cannot continue
      def on_move_prevention_user(user, targets, move)
        return if user != @pokemon
        return kill unless @logic.all_alive_battlers.include?(@origin)

        return super
      end

      # Function called at the end of a turn
      # @param logic [Battle::Logic]
      # @param scene [Battle::Scene]
      # @param battlers [Array<PFM::PokemonBattler>] All alive battlers
      def on_end_turn_event(logic, scene, battlers)
        return unless battlers.include?(@pokemon)
        return unless target_action?(logic.current_action, @pokemon)

        kill
      end

      # Function called when the effect has been deleted from the effects handler
      def on_delete
        return unless @logic.all_alive_battlers.include?(@pokemon)

        @logic.scene.display_message_and_wait(message(@pokemon))
      end

      private

      # Does this action belongs to the target?
      # @param action [Actions::Base]
      # @param target [PFM::PokemonBattler]
      # @return [Boolean]
      def target_action?(action, target)
        return (action.is_a?(Actions::Attack) && action.launcher == target) ||
              #  (action.is_a?(Actions::Shift)  && action.launcher == target) ||
               (action.is_a?(Actions::Switch) && action.who == target)      ||
               (action.is_a?(Actions::Item)   && action.user == target)     ||
               (action.is_a?(Actions::Flee)   && action.target == target)
      end

      # Message when the effect ends
      # @param target [PFM::PokemonBattler]
      # @return [String]
      def message(target)
        return parse_text_with_2pokemon(1000, 24, target, @origin)
      end
    end
  end
end
