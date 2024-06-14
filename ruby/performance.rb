modes = ['liquid', 'liquid-c', 'transpile']

command_line = ['ruby',
                '-I',
                '/Users/peter/liquid-transpiler/lib',
                '/Users/peter/Jadawin/ruby/Compiler.rb',
                '/Users/peter/Website/Articles',
                '/Users/peter/Website/config.yaml',
                '/Users/peter/temp/Sites/Articles',
                'test'
]

File.open( ARGV[0], 'w') do |io|
  io.puts "\tLiquid\tLiquid-C\tTranspiler"
  (1..3).each do |run|
    io.print "Run #{run}"
    modes.each do |mode|
      before = Time.now.to_f
      unless system( command_line.join( ' ') + " mode=#{mode}")
        raise "Mode #{mode} inconsistent"
      end
      after = Time.now.to_f
      io.print "\t#{((after - before) * 1000).floor}"
    end
    io.print "\n"
  end
end