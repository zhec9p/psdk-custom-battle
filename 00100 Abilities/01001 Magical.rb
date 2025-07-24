module Battle
  module Effects
    class Ability
      class Magical < Ability
        # Function called when a creature has actually switched with another one
        # @param handler [Battle::Logic::SwitchHandler]
        # @param _who [PFM::PokemonBattler] Creature that is switched out
        # @param with [PFM::PokemonBattler] Creature that is switched in
        def on_switch_event(handler, _who, with)
          return if with != @target

          visual = handler.scene.visual
          visual.show_ability(with)
          foes = handler.logic.adjacent_foes_of(with)
          foes.each { |foe| change_gender(handler.scene, who: foe, to: with) }
        end

        # Function called when we try to check if the effect changes the definitive priority of the move
        # @param user [PFM::PokemonBattler]
        # @param priority [Integer]
        # @param move [Battle::Move]
        # @return [Proc, nil]
        def on_move_priority_change(user, priority, move)
          return nil if user != @target
          return nil unless gender_moves.include?(move.db_symbol)

          return priority + 2
        end

        private

        # List of moves with gender-based moves
        # @return [Array<Symbol>]
        def gender_moves
          return %i[attract captivate gmax_cuddle]
        end

        # Changes a creature's gender to another creature's opposite gender
        # @param scene [Battle::Scene] Battle scene
        # @param who [PFM::PokemonBattler] Creature to change the gender of
        # @param to [PFM::PokemonBattler] Creature to get the opposite gender of
        def change_gender(scene, who:, to:)
          return unless can_change_gender(who)
          return if who.gender == to.gender

          who.gender = opposite_gender(to)
          scene.display_message_and_wait(message(who))
        end

        # Whether the creature's gender can be changed
        # @param target [PFM::PokemonBattler]
        # @return [Boolean]
        # @note 100% male/female species are immune, but genderless species aren't
        def can_change_gender(target)
          return ![0, 100].include?(target.data.female_rate)
        end

        # Get a creature's opposite gender
        # @param target [PFM::PokemonBattler]
        # @return [Integer]
        def opposite_gender(target)
          return [0, 2, 1].index(target.gender)
        end

        # Message when a creature's gender is changed
        # @param target [PFM::PokemonBattler]
        # @return [String]
        def message(target)
          return parse_text_with_pokemon(1000, 12, target)
        end
      end

      register(:magical, Magical)
    end
  end
end
