require 'liquid'
Liquid::Template.file_system = Liquid::LocalFileSystem.new( 'liquid',
                                                            pattern = "%s.liquid")
Liquid.cache_classes = false
code = <<CODE
{{ 123 | remove: 2 }}
CODE
liquid         =  Liquid::Template.parse(code)
params = {'d' => []}
puts liquid.render( params)

# Ractor.new do
#   page_template = Liquid::Template.parse("{% include 'page' %}")
#   sleep 3
#   puts 'Done 1'
# end
#
# Ractor.new do
#   page_template = Liquid::Template.parse("{% include 'page' %}")
#   sleep 3
#   puts 'Done 2'
# end
#
# sleep 5
#
