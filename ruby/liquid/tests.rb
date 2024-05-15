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

  def test_assign1
    fire( <<ASSIGN1)
{% assign my_variable = "tomato" %}
{{ my_variable }}
ASSIGN1
  end

  def test_at_least
    fire( <<AT_LEAST)
{{ 4 | at_least: 5 }}
{{ 4 | at_least: 3 }}
AT_LEAST
  end

  def test_at_most
    fire( <<AT_MOST)
{{ 4 | at_most: 5 }}
{{ 4 | at_most: 3 }}
AT_MOST
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

  def test_continue
    fire( <<CONTINUE)
{% for i in (1..5) %}
  {% if i == 4 %}
    {% continue %}
  {% else %}
    {{ i }}
  {% endif %}
{% endfor %}
CONTINUE
  end

  def test_divided_by
    fire( <<DIVIDED_BY)
{{ 16 | divided_by: 4 }}
{{ 5 | divided_by: 3 }}
{{ 20 | divided_by: 7.0 }}
DIVIDED_BY
  end

  def test_floor
    fire( <<FLOOR)
{{ 1.2 | floor }}
{{ 2.0 | floor }}
{{ 183.357 | floor }}
{{ "3.5" | floor }}
FLOOR
  end

  def test_for
    fire( <<FOR, {'basket' => ['Apple']})
{% for fruit in basket %}
{{ fruit }}
{% endfor %}
FOR
  end

  def test_for_else
    fire( <<FOR, {'basket' => []})
{% for fruit in basket %}
{{ fruit }}
{% else %}
Empty basket
{% endfor %}
FOR
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

  def test_if1
    fire( <<IF1, {'fruit' => {'green' => true, 'red' => false}})
{% if fruit.green or fruit.red %}
Apple
{% endif %}
IF1
  end

  def test_if2
    fire( <<IF2)
{% if true %}
Apple
{% endif %}
IF2
  end

  def test_object1
    fire( '{{ hash.array[0] }}', {'hash' => {'array' => ['Hello World']}})
  end

  def test_object2
    fire( '{{ hash.array[0].field }}',
          {'hash' => {'array' => [{'field' => 'Hello World'}]}})
  end

  def test_render1
    prepare( <<RENDER1, 'included.liquid')
Passed {{ threepwood }}
RENDER1
    fire2( "{% render 'included', threepwood:guybrush %}",
           {'guybrush' => 'Mighty pirate'})
  end

  def test_render2
    prepare( <<RENDER1, 'included.liquid')
Passed {{ count }} {{ fruit }}
RENDER1
    fire2( "{% render 'included', count:3, fruit:'apples' %}",
           {})
  end

  def test_render3
    prepare( <<RENDER1, 'included.liquid')
Passed {{ count }} {{ fruit }}
RENDER1
    fire2( "{% render 'included', count:counts[0],fruit:'apples' %}",
           {'counts' => [3]})
  end

  def test_split
    fire( <<SPLIT)
{% assign beatles = "John, Paul, George, Ringo" | split: ", " %}

{% for member in beatles %}
  {{ member }}
{% endfor %}
SPLIT
  end

  def test_text1
    fire( 'Hello World')
  end

  def test_text2
    fire( 'const re = /(?:\?|,)origin=([^#&]*)/;')
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

  def test_white_space
    fire( <<WHITE_SPACE)
{% assign username = "John G. Chalmers-Smith" %}
{%- if username and username.size > 10 -%}
  Wow, {{ username -}} , you have a long name!
{%- else -%}
  Hello there!
{%- endif %}
WHITE_SPACE
  end
end
