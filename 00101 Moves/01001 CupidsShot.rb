module Battle
  class Move
    # Class managing the Cupid's Shot move
    class CupidsShot < UTurn
      # Function that deals the effect to the battler
      # @param user [PFM::PokemonBattler] User of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        return false unless super

        log_data("teeeeeeest")
        actual_targets.each do |target|
          user.effects.add(Effects::CupidsShot.new(@logic, user, target))
        end
      end

      # Does the skill have a gender-related effect?
      # @return [Boolean]
      def gender?
        return true
      end
    end

    Move.register(:s_cupids_shot, CupidsShot)
  end

  module Effects
    # Class managing the effects of Cupid's Shot
    class CupidsShot < PokemonTiedEffectBase
      # Create a new CupidsShot effect
      # @param logic [Battle::Logic]
      # @param user [PFM::PokemonBattler] User of the move
      # @param target [PFM::PokemonBattler] Target of the move
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
      # @param who [PFM::PokemonBattler] Creature that is switched out
      # @param with [PFM::PokemonBattler] Creature that is switched in
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

      # Function that deals the Destiny Knot effect on the infatuator
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
