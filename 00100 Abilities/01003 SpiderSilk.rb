module Battle
  module Effects
    class Ability
      class SpiderSilk < Ability
        # Create a new Spider Silk effect
        # @param logic [Battle::Logic]
        # @param target [PFM::PokemonBattler]
        # @param db_symbol [Symbol] db_symbol of the item
        def initialize(logic, target, db_symbol)
          super
          @attacked = []
        end

        # Function called before the accuracy check of a move is done
        # @param logic [Battle::Logic] Logic of the battle
        # @param scene [Battle::Scene] Battle scene
        # @param targets [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        def on_pre_accuracy_check(logic, scene, targets, launcher, skill)
          return if launcher != @target

          @attacked.clear
        end

        # Function called after the accuracy check of a move is done (and the move should land)
        # @param logic [Battle::Logic] Logic of the battle
        # @param scene [Battle::Scene] Battle scene
        # @param targets [Array<PFM::PokemonBattler>] Expected targets
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        def on_post_accuracy_check(logic, scene, targets, launcher, skill)
          return if launcher != @target
          return unless skill&.web? && skill&.db_symbol != :sticky_web

          @attacked += targets
        end

        # Function called at the end of an action
        # @param logic [Battle::Logic] Logic of the battle
        # @param scene [Battle::Scene] Battle scene
        # @param battlers [Array<PFM::PokemonBattler>] All alive battlers
        def on_post_action_event(logic, scene, battlers)
          return unless battlers.include?(@target)
          return if @target.dead?
          return if @attacked.empty?

          scene.visual.show_ability(@target)
          @attacked.uniq.each { |battler| logic.stat_change_handler.stat_change_with_process(:eva, -2, battler, @target) }
          @attacked.clear
        end
      end

      register(:spider_silk, SpiderSilk)
    end

    class StickyWeb
      alias zhec_spider_silk__on_switch_event on_switch_event
      def on_switch_event(handler, who, with)
        zhec_spider_silk__on_switch_event(handler, who, with)

        return unless origin&.has_ability?(:spider_silk)
        return if !with.grounded? || with.hold_item?(:heavy_duty_boots)

        handler.scene.visual.show_ability(origin)
        handler.logic.stat_change_handler.stat_change_with_process(
          :eva, -2, with, with.has_ability?(:mirror_armor) ? origin : nil
        )
      end
    end
  end
end
