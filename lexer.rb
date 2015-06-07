require 'pp'
require 'byebug'
class Lexer

  def tokenize(code)
    code.strip!
    tokens = code.split(/。|！/).reduce([]) do |acc, sentence|
      acc << sentence_tokenize(sentence)
      acc
    end
    tokens
  end

  private

  def sentence_tokenize(sentence)
    sentence.strip!
    tokens = sentence.split("\n").reduce([]) do |acc, line|
      acc << line_tokenize(line)
    end
    tokens
  end

  def line_tokenize(line)
    return [] if line.nil?
    line.strip!
    return [] if line.empty?
    tokens, rest_of_line = case
                        when line[/っていうのは/]
                          [[:DEFINE],
                            line.gsub(/っていうのは.*$/,'')]
                        when line[/^もし/]
                          line.gsub!(/もし/,'')
                          predicate, body = line.split(/だったら|なら/)
                          return [:IF,
                            line_tokenize(predicate),
                            line_tokenize(body)
                          ]
                        when line[/それ以外(だったら|なら)/]
                          [[:ELSE],
                            line.gsub(/それ以外(だったら|なら).*$/,'')]
                        when line[/を使って/]
                          [[],
                            line.gsub(/を使って.*$/,'')]
                        when line[/を(返す|返して)/]
                          [[],
                            line.gsub(/を(返す|返して).*$/,'')]
                        when line[/を(計算)?した(結果|もの)$/]
                          line.gsub!(/を(計算)?した(結果|もの)$/, '')
                          *arguments, _unused, id = line.split(/(で)/)
                          splitter = if arguments.join.split(/と、/).length > 1
                                       "と、"
                                     else
                                       "と"
                                     end
                          return [id] +
                          arguments.join.split(splitter).map do |arg|
                            line_tokenize(arg)
                          end
                        when line[/してみて/]
                          [[],
                            line.gsub(/してみて.*$/,'')]
                        when line[/を(かけた結果|かけたもの)/]
                          line.gsub!(/を(かけた結果|かけたもの).*$/,'')
                          return ["*"] +
                            line.split(/と、?/).map do |argument|
                              line_tokenize(argument)
                            end
                        when line[/を足した(もの|数)$/]
                          line.gsub!(/を足した(もの|数)/,'')
                          return ["+"] +
                            line.split(/に/).map do |argument|
                              line_tokenize(argument)
                            end
                        when line[/を引いた数$/]
                          line.gsub!(/を引いた数/,'')
                          return ["-"] +
                            line.split(/から/).map do |argument|
                              line_tokenize(argument)
                            end
                        when line[/その/]
                          [[],
                            line.gsub(/その/,'')]
                        when str = line[/^「(.*)」$/,1]
                          return [:STR, str]
                        # 助詞 / Particle
                        when line[/が/]
                          first, second = line.split(/が/)
                          return ["==", line_tokenize(first), line_tokenize(second)].flatten
                        when line[/で/]
                          *rest, last = line.split(/で/)
                          return line_tokenize(last) +
                            rest.join.split(/と、?/).map do |argument|
                              line_tokenize(argument)
                            end
                        when line[/と、?/]
                          return line.split(/と、?/).reduce([]) do |accu, partial_line|
                            accu + line_tokenize(partial_line)
                          end
                        when line[/[0-9]+/]
                          return [line[/[0-9]+/].to_i]
                        else
                          return [line]
                        end
    tokens + line_tokenize(rest_of_line)
  end

end
