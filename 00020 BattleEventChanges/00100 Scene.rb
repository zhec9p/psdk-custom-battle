module Battle
  class Scene
    # Register an event for the battle
    # @param name [Symbol] name of the event
    # @param block [Proc] code of the event
    def register_event(name, &block)
      (@battle_events[name] ||= []) << block
      log_debug("Battle event #{name} registered")
    end

    # Call a named event to let the Maker put some personnal configuration of the battle
    # @param name [Symbol] name of the event
    # @param args [Array] arguments of the event if any
    def call_event(name, *args)
      events = @battle_events[name]
      return unless events

      log_debug("Calling #{name} battle event.")

      @battle_events[name].each do |event|
        next unless event.is_a?(Proc)

        event.call(self, *args)
      end
    end
  end
end
