module Battle
  module Effects
    class Flinch
      alias zhec_battle__on_move_prevention_user on_move_prevention_user
      def on_move_prevention_user(user, targets, move)
        return kill if user == @pokemon && user.has_ability?(:inner_focus)

        return zhec_battle__on_move_prevention_user(user, targets, move)
      end
    end
  end
end
