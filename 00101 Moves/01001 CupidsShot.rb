module Battle
  class Move
    class CupidsShot < UTurn
      # Function that deals the effect to the battler
      # @param user [PFM::PokemonBattler]
      # @param actual_targets [Array<PFM::PokemonBattler>]
      def deal_effect(user, actual_targets)
        return false unless super

        actual_targets.each do |target|
          user.effects.add(Effects::CupidsShot.new(@logic, user, target))
        end
      end

      # Is this a gender-affected move?
      # @return [Boolean]
      def gender?
        return true
      end

      # Play the move animation
      # @param user [PFM::PokemonBattler]
      # @param targets [Array<PFM::PokemonBattler>]
      def play_animation(user, targets)
        Battle::Move.new(:attract, 0, 0, @scene).send(:play_animation, user, targets)
      end
    end

    Move.register(:s_cupid_s_shot, CupidsShot)
  end

  module Effects
    class CupidsShot < PokemonTiedEffectBase
      # @param logic [Battle::Logic]
      # @param user [PFM::PokemonBattler]
      # @param target [PFM::PokemonBattler]
      def initialize(logic, user, target)
        super(logic, user)
        @target = target
      end

      # Get the name of the effect
      # @return [Symbol]
      def name
        return :cupid_s_shot
      end

      # Function called when a creature has actually switched with another one
      # @param handler [Battle::Logic::SwitchHandler]
      # @param who [PFM::PokemonBattler]
      # @param with [PFM::PokemonBattler]
      def on_switch_event(handler, who, with)
        return if who != @pokemon
        return kill unless @logic.all_alive_battlers.include?(@target) && @target.hp > 0
        return kill if @target.gender * with.gender != 2 || @target.effects.has?(:attract)

        @target.effects.add(Effects::Attract.new(@logic, @target, with))
        handler.scene.visual.show_status_animation(@target, :attract)
        handler.scene.display_message_and_wait(parse_text_with_pokemon(19, 327, @target))

        handle_destiny_knot_effect(with, @target) if @target.hold_item?(:destiny_knot)
        kill
      end

      private

      # Deals the Destiny Knot effect to the infatuator
      # @param with [PFM::PokemonBattler]
      # @param target [PFM::PokemonBattler]
      def handle_destiny_knot_effect(with, target)
        return if with.effects.has?(:attract)

        with.effects.add(Effects::Attract.new(@logic, with, target))
        scene.show_status_animation(target, :attract)
        scene.display_message_and_wait(parse_text_with_pokemon(19, 327, with))
      end
    end
  end
end
