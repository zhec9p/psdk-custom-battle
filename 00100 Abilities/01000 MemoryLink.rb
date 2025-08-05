module Battle
  class Logic
    SwitchHandler.register_switch_event_hook('PSDK switch: Memory Link effect') do |handler, who, with|
      has_ability = ->(battler) { battler.has_ability?(:memory_link) }
      users = (handler.logic.all_alive_battlers + [who, with]).uniq.select { |battler| has_ability.call(battler) }

      if who != with && has_ability.call(who)
        who.ability_effect.on_switch_event(handler, who, with)
        handler.pre_checked_effects << who.ability_effect
        users.reject! { |battler| battler == who }
      end

      users.sort_by!(&:spd).reverse!

      users.each do |battler|
        battler.ability_effect.on_switch_event(handler, battler, battler)
        handler.pre_checked_effects << battler.ability_effect
      end
    end
  end

  module Effects
    class Ability
      class MemoryLink < Ability
        # @param logic [Battle::Logic]
        # @param target [PFM::PokemonBattler]
        # @param db_symbol [Symbol]
        def initialize(logic, target, db_symbol)
          super
          @activated = false
        end

        # Function called when a creature has actually switched with another one
        # @param _handler [Battle::Logic::SwitchHandler]
        # @param who [PFM::PokemonBattler]
        # @param with [PFM::PokemonBattler]
        def on_switch_event(_handler, who, with)
          if who != with && who == @target
            delete_baton_passes_around(who)
          else
            add_baton_passes_around(@target)
          end
        end

        # Function called after damages were applied and when target died (post_damage_death)
        # @param _handler [Battle::Logic::DamageHandler]
        # @param _hp [Integer]
        # @param target [PFM::PokemonBattler]
        # @param _launcher [PFM::PokemonBattler, nil]
        # @param _skill [Battle::Move, nil]
        def on_post_damage_death(_handler, _hp, target, _launcher, _skill)
          return unless activated?

          if target == @target
            delete_baton_passes_around(target)
          else
            # Fainting doesn't remove the target's effects
            delete_baton_pass(target)
          end
        end

        # Function called when a pre_ability_change is checked
        # @param _handler [Battle::Logic::AbilityChangeHandler]
        # @param db_symbol [Symbol] Symbol ID of the ability to give
        # @param target [PFM::PokemonBattler]
        # @param _launcher [PFM::PokemonBattler, nil]
        # @param _skill [Battle::Move, nil]
        def on_pre_ability_change(_handler, db_symbol, target, _launcher, _skill)
          return if target != @target
          return if db_symbol == target.battle_ability_db_symbol

          delete_baton_passes_around(target)
        end

        # Is this ability currently activated?
        # @return [Boolean]
        def activated?
          return @activated
        end

        private

        # Adds a Baton Pass effect to all surrounding battlers
        # @param user [PFM::PokemonBattler]
        def add_baton_passes_around(user)
          log_data("#{user}: #{__method__}")

          unless activated?
            @logic.scene.visual.show_ability(user)
            @logic.scene.visual.wait_for_animation
            @logic.scene.display_message_and_wait(activation_message(user))
          end

          battlers = @logic.all_alive_battlers.reject { |battler| battler == user }
          battlers.each { |battler| add_baton_pass(battler) }
          @activated = true
        end

        # Removes the Baton Pass effect from all surrounding battlers
        # @param user [PFM::PokemonBattler]
        def delete_baton_passes_around(user)
          log_data("#{user}: #{__method__}")
          return unless activated?

          @logic.scene.display_message_and_wait(deactivation_message(user))
          battlers = @logic.all_alive_battlers.reject { |battler| battler == user }
          other_users = battlers.select { |battler| battler.has_ability?(db_symbol) }

          battlers.each do |battler|
            next unless other_users.reject { |holder| holder == battler }.empty?

            delete_baton_pass(battler)
          end

          @activated = false
        end

        # Adds the Baton Pass effect to a battler
        # @param target [PFM::PokemonBattler]
        def add_baton_pass(target)
          return if target.effects.has?(:baton_pass)

          target.effects.add(Battle::Effects::BatonPass.new(@logic, target))
          log_data("Applied Baton Pass effect to #{target}")
        end

        # Removes the Baton Pass effect from a battler
        # @param target [PFM::PokemonBattler]
        def delete_baton_pass(target)
          target.effects.get(:baton_pass)&.kill
          target.effects.delete_specific_dead_effect(:baton_pass)
          log_data("Removed Baton Pass effect from #{target}")
        end

        # Message when the ability is activated
        # @param user [PFM::PokemonBattler]
        # @return [String]
        def activation_message(user)
          return parse_text_with_pokemon(1000, 0, user)
        end

        # Message when the ability is deactivated
        # @param user [PFM::PokemonBattler]
        # @return [String]
        def deactivation_message(user)
          return parse_text_with_pokemon(1000, 3, user)
        end
      end

      register(:memory_link, MemoryLink)
    end
  end
end
