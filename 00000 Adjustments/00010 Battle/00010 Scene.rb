module Battle
  class Scene
    alias zhec_battle__register_event register_event
    alias zhec_battle__call_event call_event

    # Register an event for the battle
    # @param name [Symbol] name of the event
    # @param block [Proc] code of the event
    # @note Multiple events can be registered under the same name
    def register_event(name, &block)
      (@battle_events[name] ||= []) << block
      log_debug("Battle event #{name} registered")
    end

    # Call a named event(s) to let the Maker put some personnal configuration of the battle
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
