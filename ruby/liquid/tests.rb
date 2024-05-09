#
# To run individual test add command line argument
# like:
#
#   --name=test_object
#

require 'minitest/autorun'
require 'liquid'

require_relative 'transpiler'

class TestTranspiler < Minitest::Test
  @@transpiler  = Transpiler.new
  @@dir         = ENV['TEMP_DIR'] ? ENV['TEMP_DIR'] : Dir.tmpdir
  Liquid::Template.file_system = Liquid::LocalFileSystem.new( @@dir,
                                                              pattern = "%s.liquid")
  Liquid.cache_classes = false

  def setup
    Dir.entries( @@dir).each do |f|
      if /\.liquid$/ =~ f
        File.delete( @@dir + '/' + f)
      end
    end
  end

  def fire( code, params = {})
    liquid         =  Liquid::Template.parse(code)
    liquid_output  =  liquid.render( params)
    clazz          =  "Temp"
    @@transpiler.transpile_source( 'test', code, clazz, @@dir)
    load( @@dir + '/' + clazz + '.rb')
    transpiled_output = Object.const_get(clazz).test( params)
    assert_equal liquid_output, transpiled_output
  end

  def fire2( code, params = {})
    liquid         =  Liquid::Template.parse(code)
    liquid_output  =  liquid.render( params)
    prepare( code, 'test.liquid')
    clazz          =  "Temp"
    @@transpiler.transpile_dir( @@dir, clazz, @@dir)
    load( @@dir + '/' + clazz + '.rb')
    transpiled_output = Object.const_get(clazz).test( params)
    assert_equal liquid_output, transpiled_output
  end

  def prepare( code, path)
    File.open( @@dir + '/' + path, 'w') do |io|
      io.print code
    end
  end

  def test_break
    fire( <<BREAK)
{% for i in (0..9) %}
{{ i }}
{% break %}
{% endfor %}
BREAK
  end

  def test_case
    fire( <<CASE)
{% case 2 %}
{% when 1 %}Apple
{% when 2 %}Banana
{% endcase %}
CASE
  end

  def test_case_else
    fire( <<CASE_ELSE)
{% case 2 %}
{% when 1 %}Apple
{% else %}Banana
{% endcase %}
CASE_ELSE
  end

  def test_if_else
    fire( <<IF_ELSE)
{% if false %}
Apple
{% else %}
Banana
{% endif %}
IF_ELSE
  end

  def test_for
    fire( <<FOR, {'basket' => ['Apple']})
{% for fruit in basket %}
{{ fruit }}
{% endfor %}
FOR
  end

  def test_if
    fire( <<IF)
{% if true %}
Apple
{% endif %}
IF
  end

  def test_include1
    prepare( <<INCLUDE1, 'included.liquid')
Passed {{ threepwood }}
INCLUDE1
    fire2( "{% include 'included', threepwood:guybrush %}",
           {'guybrush' => 'Mighty pirate'})
  end

  def test_include2
    prepare( <<INCLUDE2A, 'included1.liquid')
{% for i in (1..1) %}{% include 'included2', i:i %}{% endfor %}
INCLUDE2A
    prepare( <<INCLUDE2B, 'included2.liquid')
{{ threepwood }} # {{ i }}
INCLUDE2B
    fire2( "{% include 'included1', threepwood:guybrush %}",
           {'guybrush' => 'Mighty pirate'})
  end

  def test_object
    fire( '{{ hash.array[0] }}', {'hash' => {'array' => ['Hello World']}})
  end

  def test_text
    fire( 'Hello World')
  end

  def test_times
    fire( <<TIMES)
{{ 3 | times: 2 }}    
{{ 24 | times: 7 }}    
{{ 183.357 | times: 12 }}
TIMES
  end

  def test_unless
    fire( <<UNLESS)
{% unless false %}
Apple
{% endunless %}
UNLESS
  end
end
