module Battle
  module Effects
    class Ability
      class Steadfast
        alias zhec_battle__on_post_status_change on_post_status_change
        def on_post_status_change(handler, status, target, launcher, skill)
          nil
        end

        # Function called at the end of an action
        # @param logic [Battle::Logic]
        # @param scene [Battle::Scene]
        # @param battlers [Array<PFM::PokemonBattler>] All alive battlers
        def on_post_action_event(logic, scene, battlers)
          return unless battlers.include?(@target)
          return unless target_move?(logic.current_action, @target)
          return unless @target.effects.has?(:flinch)

          handler.scene.visual.show_ability(@target)
          handler.logic.stat_change_handler.stat_change_with_process(:spd, 1, @target)
        end

        private

        # Check if an action is the target making a move
        # @param logic [Battle::Logic]
        # @param target [PFM::PokemonBattler]
        # @return [Boolean]
        def target_move?(action, target)
          return action.is_a?(Actions::Attack) && action.launcher == target
          # return (action.is_a?(Actions::Attack) && action.launcher == target) ||
          #        (action.is_a?(Actions::Shift)  && action.launcher == target)
        end
      end
    end
  end
end
