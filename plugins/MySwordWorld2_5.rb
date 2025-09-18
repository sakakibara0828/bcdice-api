module BCDice
  module GameSystem
    class SwordWorld2_5 < BCDice::GameSystem::Base
      ID = 'MySwordWorld2_5'
      NAME = '改造ソード・ワールド2.5'
      SORT_KEY = 'かいそうそおとわあると2.5'

      def self.register_command_pattern
        /k\d+(?:[+-]\d+)*(?:@\d+)?/i
      end

      register_prefix('k')

      def eval_game_system_specific_command(command)
        parser = BCDice::Command::Parser.new(
          /\Ak(?<power>\d+)(?<modifier>(?:[+-]\d+)*)@(?<critical>\d+)/i,
          round_type: BCDice::RoundType::NORMAL
        )

        cmd = parser.parse(command)
        return "コマンド解析失敗" unless cmd

        power = cmd.named[:power].to_i
        critical = cmd.named[:critical].to_i
        modifier = cmd.named[:modifier].to_s.scan(/[+-]\d+/).map(&:to_i).sum

        dice = @randomizer.roll_once(10)
        base = dice >= critical ? power : (power / 2.0).floor
        total = base + modifier

        "(#{command}) ＞ 出目: #{dice} ＞ 威力: #{base} + 修正: #{modifier} = 合計: #{total}"
      end
    end
  end
end
