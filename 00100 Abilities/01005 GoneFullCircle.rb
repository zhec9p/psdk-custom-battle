module Battle
  module Effects
    class Ability
      # @todo Investigate what happens if a battler with this ability active changes to a different non-cosmetic form
      class GoneFullCircle < Ability
        STATS_TO_RANDOMIZE = { atk: 1, dfe: 2, spd: 3, ats: 4, dfs: 5 }
        MIN_STAT_VALUE = 5

        # @param logic [Battle::Logic]
        # @param target [PFM::PokemonBattler]
        # @param db_symbol [Symbol]
        def initialize(logic, target, db_symbol)
          super
          @regular_bst = original_bst(target)
          @regular_bst_partitioner = permutation_partitioner(@regular_bst)
          @high_bst = 720 - target.base_hp
          @high_bst_partitioner = permutation_partitioner(@high_bst)
          @active_partitioner = @regular_bst_partitioner
        end

        # Function called when a creature has actually switched with another one
        # @param handler [Battle::Logic::SwitchHandler]
        # @param _who [PFM::PokemonBattler]
        # @param with [PFM::PokemonBattler]
        def on_switch_event(handler, _who, with)
          return if with != @target
          return if $game_temp.battle_turn != 0

          recalculate_stats(handler.logic, with)
        end

        # Function called at the end of a turn
        # @param logic [Battle::Logic]
        # @param scene [Battle::Scene]
        # @param battlers [Array<PFM::PokemonBattler>] All alive battlers
        def on_end_turn_event(logic, scene, battlers)
          return unless battlers.include?(@target)

          if @active_partitioner == @high_bst_partitioner
            logic.scene.visual.show_ability(@target)
            logic.status_change_handler.status_change_with_process(:confusion, @target)
          end

          recalculate_stats(logic, @target)
        end

        private

        # Base stats total of a creature, minus HP
        # @param target [PFM::PokemonBattler]
        # @return [Integer]
        def original_bst(target)
          base_stats = STATS_TO_RANDOMIZE.keys.map { |stat| target.send(:"base_#{stat}") }
          return base_stats.inject(:+)
        end

        # Create a new permutation partition generator that gets random stat numbers that add up to a given total
        # @param bst [Integer]
        # @return [Array<Integer>]
        def permutation_partitioner(bst)
          n = STATS_TO_RANDOMIZE.length
          min_stat = MIN_STAT_VALUE
          max_stat = bst - min_stat * (n - 1)
          return ZV::PermutationPartitionGenerator.new(n, min: min_stat, max: max_stat, sum: bst)
        end

        def recalculate_stats(logic, target)
          @active_partitioner = @regular_bst_partitioner
          @active_partitioner = @high_bst_partitioner if bchance?(0.36, logic)
          new_base_stats = @active_partitioner.get(logic.generic_rng)

          STATS_TO_RANDOMIZE.keys.zip(new_base_stats, STATS_TO_RANDOMIZE.values) do |stat, new_base, nature_index|
            basis_setter = :"#{stat}_basis="
            iv = target.send(:"iv_#{stat}")
            ev = target.send(:"ev_#{stat}")
            target.send(basis_setter, target.send(:calc_regular_stat, new_base, iv, ev, nature_index))
          end

          log_data("Base stats (#{new_base_stats.length}): #{new_base_stats}, Total: #{new_base_stats.inject(:+)}")
        end

        def message(target)
          return parse_text_with_pokemon(1000, 31, target)
        end
      end

      register(:gone_full_circle, GoneFullCircle)
    end
  end
end
