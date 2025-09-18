# frozen_string_literal: true

require 'bcdice/game_system/SwordWorld2_0'
require 'bcdice/arithmetic_evaluator'
require 'bcdice/command/parser'
require 'bcdice/user_defined_dice_table'

module BCDice
  module GameSystem
    class SwordWorld2_5 < SwordWorld2_0
      ID = 'MySwordWorld2_5'
      NAME = '改造ソード・ワールド2.5'
      SORT_KEY = 'かいそうそおとわあると2.5'

      def self.register_command_pattern
        /k\d+(?:[+-]\d+)*(?:@\d+)?/i
      end

      register_prefix('k', 'H?K', 'OHK', 'Gr', '2D6?@\d+', 'FT', 'TT', 'Dru', 'ABT')

      def eval_game_system_specific_command(command)
        case command
        when /^dru\[(\d+),(\d+),(\d+)\]/i
          power_list = Regexp.last_match.captures.map(&:to_i)
          druid_parser = Command::Parser.new(/dru\[\d+,\d+,\d+\]/i, round_type: BCDice::RoundType::CEIL)

          cmd = druid_parser.parse(command)
          unless cmd
            return "Druコマンド解析に失敗しました"
          end

          druid_dice(cmd, power_list)

        when 'ABT'
          get_abyss_curse_table

        when /\Ak/i
          parser = BCDice::Command::Parser.new(
            /\Ak(?<power>\d+)(?<modifier>(?:[+-]\d+)*)@(?<critical>\d+)/i,
            round_type: BCDice::RoundType::NORMAL
          )

          cmd = parser.parse(command)
          unless cmd
            return "コマンド解析に失敗しました（形式: k1000+10@10）"
          end

          power = cmd.named[:power].to_i
          critical = cmd.named[:critical].to_i
          modifier = cmd.named[:modifier].to_s.scan(/[+-]\d+/).map(&:to_i).sum

          dice = @randomizer.roll_once(10)
          is_critical = dice >= critical
          base = is_critical ? power : (power / 2.0).floor
          total = base + modifier

          sequence = [
            "(#{command})",
            "出目: #{dice}",
            is_critical ? "クリティカル！" : "通常威力",
            "威力: #{base} + 修正: #{modifier} = 合計: #{total}"
          ]

          sequence.join(" ＞ ")

        else
          super(command)
        end
      end

      def rating_parser
        RatingParser.new(version: :v2_5)
      end

      def druid_dice(command, power_list)
        dice_list = @randomizer.roll_barabara(2, 6)
        dice_total = dice_list.sum
        offset =
          case dice_total
          when 2..6 then 0
          when 7..9 then 1
          when 10..12 then 2
          end
        power = power_list[offset]
        total = power + command.modify_number

        sequence = [
          "(#{command.command.capitalize}#{Format.modifier(command.modify_number)})",
          "2D[#{dice_list.join(',')}]=#{dice_total}",
          "#{power}#{Format.modifier(command.modify_number)}",
          total
        ]

        sequence.join(" ＞ ")
      end

      def get_abyss_curse_table
        table_result = DiceTable::D66GridTable.from_i18n('SwordWorld2_5.AbyssCurseTable', @locale).roll(@randomizer)
        additional =
          case table_result.value
          when 14
            DiceTable::D66ParityTable.from_i18n('SwordWorld2_5.AbyssCurseCategoryTable', @locale).roll(@randomizer).to_s
          when 25
            DiceTable::D66ParityTable.from_i18n('SwordWorld2_5.AbyssCurseAttrTable', @locale).roll(@randomizer).to_s
          end

        [table_result.to_s, additional].compact.join("\n")
      end

      HELP_MESSAGE = <<~TEXT
        自動的成功、成功、失敗、自動的失敗の自動判定を行います。
        ・レーティング表 (Kx)
        例）K20、K10+5、k30、k10+10、Sk10-1、k10+5+2
        ・クリティカル値の設定
        例）K20[10]、K10+5[9]、k30[10]、k10[9]+10、k10-5@9
        ・その他の特殊記法（HK、OHK、$、#、r5、gf、sf、tf、2D6@、Gr、FT、TT、Dru、ABT）にも対応
      TEXT
    end
  end
end
