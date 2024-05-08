#
# To run individual test add command line argument
# like:
#
#   --name=test_object
#

require 'minitest/autorun'
require 'liquid'

require_relative 'transpiler'

class TestTranspiler < MiniTest::Unit::TestCase
  @@clazz_index = 0
  @@transpiler  = Transpiler.new
  @@dir         = ENV['TEMP_DIR'] ? ENV['TEMP_DIR'] : Dir.tmpdir
  Liquid::Template.file_system = Liquid::LocalFileSystem.new( @@dir,
                                                              pattern = "%s.liquid")
  Liquid.cache_classes = false

  def setup
  end

  def fire( code, params = {})
    liquid         =  Liquid::Template.parse(code)
    liquid_output  =  liquid.render( params)
    clazz          =  "Temp#{@@clazz_index}"
    @@clazz_index  += 1
    @@transpiler.transpile_source( 'test', code, clazz, @@dir)
    require( @@dir + '/' + clazz + '.rb')
    transpiled_output = Object.const_get(clazz).test( params)
    assert_equal liquid_output, transpiled_output
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

  def test_object
    fire( '{{ hash.array[0] }}', {'hash' => {'array' => ['Hello World']}})
  end

  def test_text
    fire( 'Hello World')
  end
end
