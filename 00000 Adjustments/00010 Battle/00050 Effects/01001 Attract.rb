module Battle
  module Effects
    class Attract
      # Function called when we try to use a move as the user (returns :prevent if user fails)
      # @param user [PFM::PokemonBattler]
      # @param targets [Array<PFM::PokemonBattler>]
      # @param move [Battle::Move]
      # @return [:prevent, nil] :prevent if the move cannot continue
      def on_move_prevention_user(user, targets, move)
        return if user != @pokemon
        return kill unless @logic.all_alive_battlers.include?(@attracted_to)
        return unless targets.include?(@attracted_to)

        move.scene.display_message_and_wait(parse_text_with_pokemon(19, 333, user, PFM::Text::PKNICK[1] => @attracted_to.given_name))
        return unless bchance?(0.5, move.logic)

        move.scene.display_message_and_wait(parse_text_with_pokemon(19, 336, user))
        return :prevent
      end
    end
  end
end
