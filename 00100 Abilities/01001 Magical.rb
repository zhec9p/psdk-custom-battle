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

          handler.scene.visual.show_ability(with)
          foes = handler.logic.adjacent_foes_of(with)
          foes.each { |foe| change_gender(handler, who: foe, with: with) }
        end

        # Function called when we try to check if the effect changes the definitive priority of the move
        # @param user [PFM::PokemonBattler]
        # @param priority [Integer]
        # @param move [Battle::Move]
        # @return [Proc, nil]
        def on_move_priority_change(user, priority, move)
          return nil if user != @target
          return nil unless gender_move?(move)

          return priority + 2
        end

        private

        class << self
          private

          # Configuration helper to allow the ability to transform gendered species/forms their gender counterparts
          # @param m [Array<Symbol, Integer>] Symbol and form of a male species/form
          # @param f [Array<Symbol, Integer>] Symbol and form of a female species/form
          # @param m2f [Boolean]: Whether the ability can transform the male species/form into the female one
          # @param f2m [Boolean]: Whether the ability can transform the female species/form into the male one
          # @return [Hash] Transformation configuration to be added to GENDER_LINES
          def link(m:, f:, m2f: true, f2m: true)
            hash = {}
            hash[m] = f if m2f
            hash[f] = m if f2m
            return hash
          end
        end

        # Gendered species/forms that the ability can transform into their gender counterparts
        GENDER_LINES = {}.merge(
          link(m: [:basculegion, 0], f: [:basculegion, 1]),
          link(m: [:meowstic, 0],    f: [:meowstic, 1]),
          link(m: [:indeedee, 0],    f: [:indeedee, 1]),
          link(m: [:oinkologne, 0],  f: [:oinkologne, 1]),
          link(m: [:nidoranm, 0],    f: [:nidoranf, 0]),
          link(m: [:nidorino, 0],    f: [:nidorina, 0]),
          link(m: [:nidoking, 0],    f: [:nidoqueen, 0]),
          link(m: [:gallade, 0],     f: [:gardevoir, 0],    f2m: false),
          link(m: [:glalie, 0],      f: [:froslass, 0],     m2f: false),
          link(m: [:mothim, 0],      f: [:wormadam, 0])
        )

        # List of moves with gender-based effects
        GENDER_MOVES = %i[attract captivate gmax_cuddle]

        # Changes a creature's gender to another creature's opposite gender
        # @param handler [Battle::Logic::TransformHandler]
        # @param who [PFM::PokemonBattler] Creature to change the gender of
        # @param with [PFM::PokemonBattler] Creature to get the opposite gender of
        def change_gender(handler, who:, with:)
          return unless can_change_gender(handler, who)

          new_gender = opposite_gender(with)
          return if who.gender == new_gender

          who.gender = new_gender
          gender_transform(handler, who)
          handler.scene.display_message_and_wait(message(who))
        end

        # Get the gender opposite of a battler's
        # @param target [PFM::PokemonBattler]
        # @return [Integer]
        def opposite_gender(target)
          return [0, 2, 1].index(target.gender)
        end

        # Whether a battler's gender can be changed
        # @param target [PFM::PokemonBattler]
        # @return [Boolean]
        def can_change_gender(handler, target)
          return false if target.db_symbol == :ditto

          return true
        end

        # Transforms a battler into the creature or form of the opposite gender
        # @param handler [Battle::Logic::ChangeHandlerBase]
        # @param target [PFM::PokemonBattler]
        def gender_transform(handler, target)
          transform_handler = handler.logic.transform_handler
          ability_change_handler = handler.logic.ability_change_handler

          return if target.illusion
          return unless transform_handler.can_transform?(target)
          return unless ability_change_handler.can_change_ability?(target)

          species, form = GENDER_LINES[[target.db_symbol, target.form]]
          return unless species && form

          old_ability = target.battle_ability_db_symbol
          transformed = new_creature(target, species, form)
          ability_change_handler.change_ability(target, transformed.ability_db_symbol)

          target.magical = transformed
          target.effects.add(Effects::Magical.new(handler.logic, target))
          handler.scene.visual.show_switch_form_animation(target)

          if old_ability != target.battle_ability_db_symbol
            switch_handler = handler.logic.switch_handler
            target.ability_effect.on_switch_event(switch_handler, target, target)
          end
        end

        # Get a new creature the target should transform into
        # @param target [PFM::PokemonBattler]
        # @param species [Symbol] Symbol of the new creature
        # @param form [Integer] Form of the new creature
        # @return [PFM::Pokemon]
        def new_creature(target, species, form)
          creature = PFM::Pokemon.new(species, target.level, target.shiny?, !target.shiny?, form, {
            gender: target.gender
          })

          creature.ability_index = target.original.ability_index
          creature.update_ability
          return creature
        end

        # Whether a move has a gender-based effect
        # @param move [Battle::Move]
        # @return [Boolean]
        # @todo Make this function a gender? method for Battle::Move instead.
        def gender_move?(move)
          return GENDER_MOVES.include?(move.db_symbol)
        end

        # Message when a battler's gender is changed
        # @param target [PFM::PokemonBattler]
        # @return [String]
        def message(target)
          return parse_text_with_pokemon(1000, 12, target)
        end
      end

      register(:magical, Magical)
    end

    class Magical < PokemonTiedEffectBase
      # Function called when a creature has actually switched with another one
      # @param _handler [Battle::Logic::SwitchHandler]
      # @param who [PFM::PokemonBattler] Creature that is switched out
      # @param with [PFM::PokemonBattler] Creature that is switched in
      def on_switch_event(_handler, who, with)
        return if who != @pokemon || with == @pokemon

        who.magical = nil
      end

      # Get the name of the effect
      # @return [Symbol]
      def name
        return :magical
      end
    end
  end

  class Logic
    class TransformHandler
      alias zhec_magical__can_transform? can_transform?
      def can_transform?(target)
        return !target.magical && zhec_magical__can_transform?(target)
      end
    end
  end
end

module PFM
  class PokemonBattler
    attr_reader :magical

    # Don't include :ability in these properties. Magical does ability changes elsewhere.
    MAGICAL_BATTLE_PROPERTIES = %i[id form gender shiny weight height type1 type2]
    MAGICAL_SETTERS = MAGICAL_BATTLE_PROPERTIES.to_h { |key| [key, :"#{key}="] }

    # Transform this battler into another creature or form
    # @param creature [PFM::Pokemon, nil]
    def magical=(creature)
      old_max_hp = max_hp
      @magical = creature
      copy_magical_properties

      # To avoid potentially coming up with +/-1 in current HP after calculations when max HP is the same.
      return if max_hp == old_max_hp

      @hp = [1, (@hp_rate * max_hp).round].max
      @hp_rate = @hp.to_f / max_hp
    end

    # Copy the properties of a gender-transformed creature
    def copy_magical_properties
      if @magical
        @battle_properties_before_magical = MAGICAL_BATTLE_PROPERTIES.map { |getter| send(getter) }
        MAGICAL_SETTERS.each { |getter, setter| send(setter, @magical.send(getter)) }

      elsif @battle_properties_before_magical
        MAGICAL_BATTLE_PROPERTIES.map.with_index do |key, index|
          send(MAGICAL_SETTERS[key], @battle_properties_before_magical[index])
        end
        @battle_properties_before_magical = nil
      end
    end

    alias zhec_magical__initialize initialize
    def initialize(...)
      zhec_magical__initialize(...)
      @magical = nil
    end

    alias zhec_magical__copy_properties copy_properties
    def copy_properties
      zhec_magical__copy_properties
      copy_magical_properties if @magical
    end

    alias zhec_magical__copy_properties_back_to_original copy_properties_back_to_original
    def copy_properties_back_to_original
      return zhec_magical__copy_properties_back_to_original unless @magical
      return if @scene.battle_info.max_level

      @battle_properties.clear
      self.transform = nil
      self.magical = nil
      self.illusion = nil
      original = @original

      BACK_PROPERTIES.each do |ivar_name|
        original.instance_variable_set(ivar_name, instance_variable_get(ivar_name))
      end

      @moveset.each_with_index do |move, i|
        @original.skills_set[i]&.pp = move.pp
      end
    end

    alias zhec_magical__cry cry
    def cry
      return @magical&.cry if @magical

      return zhec_magical__cry
    end

    alias zhec_magical__level_up_copy level_up_copy
    def level_up_copy
      return zhec_magical__level_up_copy unless @magical

      self.level = @original.level
      self.exp = @original.exp
      return level_up_stat_refresh if @transform

      @magical.level_up_stat_refresh
      self.hp = [1, (@original.hp_rate * @magical.max_hp).round].max

      %i[@ev_hp @ev_atk @ev_dfe @ev_spd @ev_ats @ev_dfs].each do |ivar_name|
        instance_variable_set(ivar_name, original.instance_variable_get(ivar_name))
      end
    end
  end
end

module BattleUI
  module ExpDistributionAbstraction
    alias zhec_magical__map_to_original_with_forms map_to_original_with_forms
    def map_to_original_with_forms(battlers)
      return zhec_magical__map_to_original_with_forms(battlers) if battlers.any? { |battler| battler.magical }
      return @__original_pokemon if @__original_pokemon

      @__original_forms = battlers.map { |battler| battler.original.form }
      @__original_pokemon = battlers.map do |battler|
        original = battler.original
        original.instance_variable_set(:@form, battler.form) unless battler.transform || battler.magical || battler.illusion
        next original
      end

      return @__original_pokemon
    end

    alias zhec_magical__show_level_up show_level_up
    def show_level_up(battler)
      return zhec_magical__show_level_up(battler) unless battler.magical

      original = battler.original
      original.hp = battler.hp unless battler.transform || battler.magical
      battler.update_loyalty
      list = original.level_up_stat_refresh
      yield(original, list)
      level_up_message(battler)
      scene.logic.evolve_request << battler unless scene.logic.evolve_request.include?(battler)
    end
  end
end
