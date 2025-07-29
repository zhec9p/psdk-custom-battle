module BattleUI
  module PlayerChoiceAbstraction
    # Quick fix for the issue where fleeing is tied to switch prevention effects instead flee prevention effects.
    alias zhec_battle__reset reset
    def reset(_can_switch)
      battler = scene.logic.battler(0, scene.player_actions.size)
      can_flee = scene.logic.switch_handler.can_switch?(battler, reason: :flee)
      zhec_battle__reset(can_flee)
    end
  end
end
