=begin
	Compiler.rb

	Generate HTML structure from article files
=end

require 'bundler/setup'
# require 'rexml/document'
# require 'rexml/xpath'
require 'yaml'
require 'cgi'
require 'fileutils'
require 'json'

require_relative 'Article'
require_relative 'elements/error'
require_relative 'utils'

class Compiler
  include Utils

  # Initialisation
  def initialize( source, config, sink, debug_pages=nil)
    @errors        = 0
    @source        = source
    @sink          = sink
    @debug_pages   = debug_pages.nil? ? nil : Regexp.new( debug_pages)
    @config        = YAML.load( File.open( config))
    @words, @names = load_words
    @new_words     = []
    @generated     = {}
    @key2paths     = Hash.new {|h,k| h[k] = []}
    prepare_templates
  end

# =================================================================
# Main logic
# =================================================================

  def add_content( verb, article, info, ref)
    begin
      require_relative( 'elements/' + verb.downcase)
    rescue LoadError
      article.error( 'Unknown directive: ' + verb)
      return
    end

    if verb.downcase == verb
      verb = verb.split( '_').collect {|n| n.capitalize}.join('')
    end

    begin
      clazz = Kernel.const_get( 'Elements::' + verb)
    rescue NameError
      article.error( 'Directive error: ' + ref)
      return
    end

    begin
      article.add_content( clazz.new( self, article, info), info.size > 1)
    rescue NoMethodError
      article.error( 'Directive error: ' + ref)
    end
  end

  # Compile
  def compile
    puts "... Initialised #{Time.now.strftime( '%Y-%m-%d %H:%M:%S')}"

    # Scan for images
    Elements::Image.find_images( @source)

    # Parse all the articles recursively
    @articles = parse( nil, "")
    puts "... Parsed      #{Time.now.strftime( '%Y-%m-%d %H:%M:%S')}"

    # Prepare the articles now all articles parsed
    prepare( [], @articles)
    puts "... Prepared    #{Time.now.strftime( '%Y-%m-%d %H:%M:%S')}"

    # Regenerate the HTML files
    regenerate( [], @articles)
    puts "... Generated   #{Time.now.strftime( '%Y-%m-%d %H:%M:%S')}"

    # Delete files not regenerated
    tidy_up( @sink)

    # Check locations all rendered
    Elements::Tag.check_all_rendered

    # Report new words
    report_new_words

    # Report tests run
    puts "... #{Elements::Expect.number_of_tests + Elements::Error.number_of_tests} tests run"

    # Report any errors
    Elements::Error.report_errors
    report_errors( @articles)
    puts "*** #{@errors} Errors in compilation" if @errors > 0
  end

  def copy_resource( f)
    from   = @source + '/' + f
    to     = @sink + '/' + f
    to_dir = File.dirname( to)
    Dir.mkdir( to_dir) unless File.exist?( to_dir)
    record( to)
    unless File.exist?( to) && (IO.read( to) == IO.read( from))
      FileUtils.cp( from, to)
    end
  end

  def debug_hook( article, msg)
    # puts "DEBUG100: #{article.sink_filename}"
    if @debug_pages && (@debug_pages =~ article.filename)
      puts "!!! #{article.filename} : #{msg}"
    end
  end

  # Parse the articles
  def parse( parent, path)

    # Article for the directory
    dir_article = Article.new( path + '/index.html')
    remember( (path == '') ? '.' : path, dir_article)
    parent.add_child( dir_article) if parent

    # Hash of articles in this directory
    dir_articles = Hash.new do |h,k|
      a = Article.new( path + '/' + k + '.html')
      dir_article.add_child( a)
      remember( path + '/' + k, a)
      h[k] = a
    end
    dir_articles['index'] = dir_article

    # Loop over source files - skip image files and other specials
    Dir.entries( @source + path).each do |file|
      next if /^\./ =~ file
      next if /^\_/ =~ file
      path1 = path + "/" + file

      if File.directory?( @source + path1)
        Dir.mkdir( @sink + path1) if not File.exist?( @sink + path1)
        parse( dir_article, path1)
      elsif m = /^(.*)\.txt$/.match( file)
        child = dir_articles[m[1]]
        parse_article(path, file, child)
      elsif /\.(JPG|jpg|JPEG|jpeg|png|zip|rb|kml|afphoto|command|erb|pdf|gif|svg|webp)$/ =~ file
        remember( path1, @source + path1)
      else
        raise "Unhandled file: #{path1}"
      end
    end

    dir_article.discard_future_children
  end

  def parse_article(path, file, article)
    debug_hook( article, "Parsing article")
    text = IO.read( @source + path + "/" + file)
    lines = text.split( "\n")
    i = 0

    while i < lines.size
      if m = /^@(\S+)\s*$/.match( lines[i])
        j = i
        while ((j+1) < lines.size) && (! (/^@\S/ =~ lines[j+1]))
          j = j + 1
        end

        k = j
        while (k > (i+1)) && (lines[k].strip == '')
          k = k - 1
        end

        add_content( m[1], article, lines[(i+1)..k], lines[i])
        i = j + 1
      elsif m2 = /^@(\S+)\s+(\S.*)$/.match( lines[i])
        add_content( m2[1], article, [m2[2].strip], lines[i])
        i += 1
      elsif lines[i].strip == ''
        i = lines.size + 1
      else
        article.error( "Expected directive: " + lines[i])
        i = lines.size + 1
      end
    end
  end

  def prepare_templates
    if @config['mode'].nil? ||
        @config['mode'] == 'liquid' ||
        @config['mode'] == 'liquid-c'
      require 'liquid'
      if @config['mode'] == 'liquid-c'
        require 'liquid/c'
      end
      Liquid::Template.file_system = Liquid::LocalFileSystem.new( @config['liquid'],
                                                                  pattern = "%s.liquid")
      @page_template = Liquid::Template.parse("{% include 't_page' with config:config, page:page %}")
      Liquid.cache_classes = false
    elsif @config['mode'] == 'transpile'
      require_relative 'liquid/transpiler'
      Transpiler.new.transpile_dir( @config['liquid'], 'Transpiled', @config['liquid'])
      require( @config['liquid'] + '/Transpiled.rb')
    end
  end

  def dimensions( key)
    @config['dimensions'][key]
  end

  def error( path, msg)
    @errors = @errors + 1
    puts "*** #{msg} [#{path}]"
  end

  def errors?
    @errors > 0
  end

  def get_config( key)
    @config[key]
  end

  def load_words
    if dir = @config['spell_checking']
      unless File.exist?( dir)
        raise "Spell checking directory not found"
      end
      words, names = {}, {}

      Dir.entries( dir).each do |f|
        if /\.txt$/ =~ f
          IO.readlines( dir + '/' + f).each do |line|
            word = line.strip
            next if word == ''

            if word.downcase == word
              words[word.downcase] = true
            else
              names[word] = true
            end
          end
        end
      end

      #p ['load_words', words.size, names.size]
      return words, names
    else
      return nil, nil
    end
  end

  def log( message)
    puts message
  end

  def lookup( path, ref)
    if File.exist?( @source + path) && (! File.directory?( @source + path))
      return path.gsub( /\.txt$/, '.html')
    end
    matches = @key2paths[path]

    if matches.size < 1
      return nil, "Path not found for #{ref}"
    elsif matches.size > 1
      return nil, "Ambiguous path for #{ref}"
    else
      return matches[0], nil
    end
  end

  def offsite?( url)
    if url.index( @config['root_url'])
      false
    elsif /^http/ =~ url
      true
    else
      false
    end
  end

  def prepare( parents, article)
    debug_hook( article, "Preparing")

    begin
      article.prepare( self, parents)
    rescue Exception => bang
      article.error( bang.message)
      raise
    end

    article.children.each do |child|
      prepare( parents + [article], child)
    end
  end

  def record( path)
    @generated[path] = true
  end

  def record_article( article, path)
    if @generated[path]
      article.error( "Duplicate path: #{path} already used")
    else
      @generated[path] = true
    end
  end

  def regenerate( parents, article)
    debug_hook( article, "Regenerating")

    to_data = article.to_data( self, parents)
    params  = {'config' => @config,
               'page'   => to_data}
    if @config['mode'] == 'transpile'
      html = Transpiled.test( params)
    else
      html = @page_template.render( params)
    end

    if /Liquid error:/m =~ html
      article.error( 'Liquid templating error')
    end

    html = article.post_process_html( @config['root_url'], html)
    path = sink_filename( article.filename)
    record_article( article, path)
    Dir.mkdir( File.dirname( path)) if not File.exist?( File.dirname( path))
    rewrite = ! File.exist?( path)

    if ! rewrite
      current = IO.readlines( path).collect {|line| line.chomp}
      rewrite = (current.join("\n").strip != html.strip)
    end

    if rewrite
      puts "... Writing #{path}"
      File.open( path, 'w') {|io| io.print html}
    end

    article.children.each do |child|
      regenerate( parents + [article], child) if child.is_a?( Article)
    end
  end

  def remember( key, path)
    key = key.split('/')
    (0...key.length).each do |i|
      @key2paths[ key[i..-1].join('/')] << path
    end
  end

  def report_errors( article)
    article.report_errors( self)
    article.children.each do |child|
      report_errors( child) if child.is_a?( Article)
    end
  end

  def report_new_words
    if @new_words.size > 0
      @new_words = @new_words.uniq.sort
      puts "... #{@new_words.size} unknown words"
      File.open( @config['misspelt_words'], 'w') do |io|
        io.puts @new_words.join("\n")
      end
    end
  end

  def sink_filename( file)
    if m = /^(\/resources\/)(.*)$/.match( file)
      raise 'resource reference: ' + file
    end
    @sink + ((/^\// =~ file) ? '' : '/') + file
  end

  def source_filename( file)
    @source + ((/^\// =~ file) ? '' : '/') + file
  end

  def spell_check( article, text)

    # Check for spelling checking active
    return unless @words

    # Convert HTML entity codes for letters
    text = text.gsub( /&(.)(acute|caron|cedil|grave|circ|slash|uml|ring);/) do |element|
      element[1..1]
    end

    # Scan scrunched text
    pos, scanner = -100, StringScanner.new( text)
    while pos < scanner.pos
      pos  = scanner.pos
      if scanner.scan_until( /(?:^|^'|\W'|["\s\(])([a-z][a-z'\-]*[a-z])(?:$|\W|\))/i)
        word = scanner[1]

        if m = /^(.*)('s|-like|-wise|-ish|-style)$/.match( word)
          word = m[1]
        end

        if m = /^(pre-|quasi-|ex-|half-|mini-|multi-|non-|pseudo-)(.*)$/i.match( word)
          word = m[2]
        end

        next if @names[word]
        next if @words[word.downcase]

        @new_words << word
        article.error( "Unknown word: #{scanner[1]}")
      end
    end
  end

  def tidy_up( path)
    keep = false
    Dir.entries( path).each do |f|
      next if /^\./ =~ f
      path1 = path + '/' + f
      if File.directory?( path1)
        if tidy_up( path1)
          keep = true
        else
          puts "... Deleting #{path1}"
          File.delete( path1 + '/.DS_Store') if File.exist?( path1 + '/.DS_Store')
          Dir.rmdir( path1)
        end
      else
        if @generated[path1]
          keep = true
        else
          puts "... Deleting #{path1}"
          File.delete( path1)
        end
      end
    end
    keep
  end

  def to_class( name)
    # if name.downcase == 'stdprn'
    #   puts 'DEBUG100'
    # end
    require_relative( 'elements/' + name.downcase)
    if name.downcase == name
      name = name.split( '_').collect {|n| n.capitalize}.join('')
    end
    Kernel.const_get( 'Elements::' + name)
  end
end

compiler = Compiler.new( * ARGV)
compiler.compile
exit 1 if compiler.errors?
