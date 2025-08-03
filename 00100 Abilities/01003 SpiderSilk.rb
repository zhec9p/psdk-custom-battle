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
          @attacked.uniq!

          @attacked.each do |battler|
            logic.stat_change_handler.stat_change_with_process(:eva, -1, battler, @target)
            battler.effects.add(Effects::SpiderSilkMark.new(logic, battler)) unless battler.effects.has?(:spider_silk_mark)
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
        with.effects.add(Effects::SpiderSilkMark.new(handler.logic, with)) unless with.effects.has?(:spider_silk_mark)
      end
    end

    class SpiderSilkMark < PokemonTiedEffectBase
      # Create a new SpiderSilkMark effect
      # @param logic [Battle::Logic]
      # @param target [PFM::PokemonBattler]
      def initialize(logic, target)
        super
        logic.scene.display_message_and_wait(message(target))
      end

      # Get the name of the effect
      # @return [Symbol]
      def name
        return :spider_silk_mark
      end

      # Chance of the OHKO move hitting
      # @param user [PFM::PokemonBattler] User of the move
      # @param target [PFM::PokemonBattler] Target of the move
      # @param move [Battle::Move]
      # @return [Float]
      def ohko_chance(user, target, move)
        return 0 unless move.ohko?
        return move.zhec_battle__chance_of_hit(user, target) if target != @pokemon

        # 30% baseline for higher level is intentional
        chance = [0, user.level - target.level].max + 30
        chance *= move.evasion_mod(target)
        return chance
      end

      private

      # Message to display when Spider Silk's OHKO chance effect is applied to the target
      # @param target [PFM::PokemonBattler]
      # @return [String]
      def message(target)
        return parse_text_with_pokemon(1000, 18, target)
      end
    end
  end

  class Move
    class OHKO
      # Tell if the move is an OHKO move
      # @return [Boolean]
      def ohko?
        return true
      end

      alias zhec_battle__chance_of_hit chance_of_hit
      def chance_of_hit(user, target)
        chance = zhec_battle__chance_of_hit(user, target)
        effect = target.effects.get(:spider_silk_mark)
        return chance unless effect && chance < 100

        return effect.ohko_chance(user, target, self)
      end
    end
  end
end
