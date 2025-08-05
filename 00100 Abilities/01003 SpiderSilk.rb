module Battle
  module Effects
    class Ability
      class SpiderSilk < Ability
        # @param logic [Battle::Logic]
        # @param target [PFM::PokemonBattler]
        # @param db_symbol [Symbol]
        def initialize(logic, target, db_symbol)
          super
          @attacked = []
        end

        # Function called before the accuracy check of a move is done
        # @param _logic [Battle::Logic]
        # @param _scene [Battle::Scene]
        # @param _targets [Array<PFM::PokemonBattler>]
        # @param launcher [PFM::PokemonBattler, nil]
        # @param _skill [Battle::Move, nil]
        def on_pre_accuracy_check(_logic, _scene, _targets, launcher, _skill)
          return if launcher != @target

          @attacked.clear
        end

        # Function called after the accuracy check of a move is done (and the move should land)
        # @param _logic [Battle::Logic]
        # @param _scene [Battle::Scene]
        # @param targets [Array<PFM::PokemonBattler>]
        # @param launcher [PFM::PokemonBattler, nil]
        # @param skill [Battle::Move, nil]
        def on_post_accuracy_check(_logic, _scene, targets, launcher, skill)
          return if launcher != @target
          return unless skill&.web? && skill&.db_symbol != :sticky_web

          @attacked += targets
        end

        # Function called at the end of an action
        # @param logic [Battle::Logic]
        # @param scene [Battle::Scene]
        # @param battlers [Array<PFM::PokemonBattler>] All alive battlers
        def on_post_action_event(logic, scene, battlers)
          return unless battlers.include?(@target)
          return if @target.dead?
          return if @attacked.empty?

          scene.visual.show_ability(@target)
          @attacked.uniq!

          @attacked.each do |battler|
            logic.stat_change_handler.stat_change_with_process(:eva, -2, battler, @target)
            battler.effects.add(Effects::SpiderSilk.new(logic, battler)) unless battler.effects.has?(:spider_silk)
          end

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
        launcher = with.has_ability?(:mirror_armor) ? origin : nil
        handler.logic.stat_change_handler.stat_change_with_process(:eva, -1, with, launcher)
        with.effects.add(Effects::SpiderSilk.new(handler.logic, with)) unless with.effects.has?(:spider_silk)
      end
    end

    class SpiderSilk < PokemonTiedEffectBase
      # @param logic [Battle::Logic]
      # @param target [PFM::PokemonBattler]
      def initialize(logic, target)
        super
        logic.scene.display_message_and_wait(message(target))
      end

      # Get the name of the effect
      # @return [Symbol]
      def name
        return :spider_silk
      end

      # Get the chance of the OHKO move hitting
      # @param user [PFM::PokemonBattler]
      # @param target [PFM::PokemonBattler]
      # @param move [Battle::Move]
      # @return [Float]
      def ohko_chance(user, target, move)
        return 0 unless move.ohko?
        return move.zhec_battle__chance_of_hit(user, target) if target != @pokemon

        # Higher-level creatures are no longer immune.
        chance = [0, user.level - target.level].max + 30
        chance *= move.evasion_mod(target) if target.eva_stage <= 0
        return chance
      end

      private

      # Message for Spider Silk's OHKO chance effect
      # @param target [PFM::PokemonBattler]
      # @return [String]
      def message(target)
        return parse_text_with_pokemon(1000, 18, target)
      end
    end
  end

  class Move
    class OHKO
      alias zhec_battle__chance_of_hit chance_of_hit
      def chance_of_hit(user, target)
        chance = zhec_battle__chance_of_hit(user, target)
        effect = target.effects.get(:spider_silk)
        return chance unless effect && chance < 100

        return effect.ohko_chance(user, target, self)
      end
    end
  end
end
