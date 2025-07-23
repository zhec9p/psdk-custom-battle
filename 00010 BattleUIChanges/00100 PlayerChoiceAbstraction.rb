module BattleUI
  module PlayerChoiceAbstraction
    alias zhec_battle_reset reset
    def reset(can_switch)
      logic = scene.logic
      battler = logic.battler(0, scene.player_actions.size)
      zhec_battle_reset(logic.switch_handler.can_switch?(battler, reason: :flee))
    end
  end
end
