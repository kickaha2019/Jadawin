=begin
  Article.rb

  Represent article for HTML generation
=end

require 'digest/sha1'
require 'liquid'

require_relative 'utils'
require_relative 'elements/heading'
require_relative 'elements/icon'
require_relative 'elements/inset'
require_relative 'elements/links'
require_relative 'elements/tag'
require_relative 'elements/resource'
require_relative 'elements/svg'
require_relative 'styles/base'

class Article < Liquid::Drop
  include Utils
  attr_accessor :content_added
  attr_reader   :blurb, :style

  def initialize( compiler, parents, filename)
    @compiler        = compiler
    @parents         = parents
    @filename        = filename
    @children        = []
    @children_sorted = true
    @errors          = []
    @content         = []
    @specials        = {}
    @style           = nil
    # @style           = Styles::Base.new
    # @blurb           = nil
    # @date            = nil
    # @title           = nil
    @origins         = nil
#    @icon            = nil
  end

  def add_child( article)
    @children_sorted = false
    @children << article
  end

  def add_content( item, multiple_lines)
    unless item.discard?
      if multiple_lines && (! item.multiline?)
        error( item.type_name + ' takes only one line')
      elsif item.special?
        if @specials[ item.type_name]
          error( 'Duplicate ' + item.type_name + ' definition')
        else
          @specials[ item.type_name] = item
        end
      else
        @content << item
      end
    end
  end

  def blurb
    @specials['Blurb'] ? @specials['Blurb'].text : nil
  end

  def breadcrumbs( ancestors)
    return false if ancestors.empty?

    ancestors.collect do |ancestor|
      {'path'  => relative_path( filename, ancestor.filename),
       'title' => prettify( ancestor.title)}
    end
  end

  def children
    if not @children_sorted
      @children = style.sort( @children)
      @children_sorted = true
    end
    @children
  end

  def children?
    @children.size > 0
  end

  def date
    @specials['Date'] ? @specials['Date'].date : nil
  end

  def discard_future_children
    @children = @children.select do |child|
      child.date.nil? || (child.date <= Time.now)
    end
    self
  end

  def dump_content( tag)
    @content.each do |item|
      p [tag, item.class.to_s]
    end
  end

  def error( msg)
    @content.each do |element|
      return if element.ignore_error?( msg)
    end
    @errors << msg
  end

  def filename
    @filename
  end

  def grand_children?
    @children.each do |child|
      return true if child.children?
    end
    false
  end

  def has_any_content?
    # if /Baltics\/index/ =~ @filename
    #   puts 'DEBUG100'
    # end
    @content.each do |item|
      return true if item.page_content?
    end
    false
  end

  def icon
    return @specials['Icon'] if @specials['Icon']

    @content.each do |item|
      if icon = item.image
        return icon
      end
    end

    children.each do |child|
      if icon = child.icon
        return icon
      end
    end

    nil
  end

  def leaf?
    style.leaf?( self)
  end

  def name
    path = @filename.split( "/")
    (/^index\./i =~ path[-1]) ? path[-2] : path[-1].gsub( /\..*$/, '')
  end

  def off_page?
    false
  end

  def origin( name, ancestors)
    @origins = [] unless @origins
    @origins << [name, breadcrumbs( ancestors)]
  end

  def page_title
    @parents.empty? ? nil : prettify( title)
  end

  def post_process_html( root_url, html)
    html = style.post_process_html( root_url, self, html)
    @content.each do |element|
      html = element.post_process_html( self, html)
    end
    html
  end

  def prepare
    if (! styled?) && story?
      override_style( Styles::Story.new)
    end
    style.prepare( @compiler, self, @parents)

    @content.each_index do |i|
      @content[i].prepare( @compiler,
                           self,
                           @parents,
                           (@content.size > (i + 1)) ? @content[(i+1)..-1] : [])
    end
  end

  def report_errors
    @errors.each {|err| @compiler.error( @filename.gsub('html','txt'), err)}
  end

  def override_style( style)
    @style           = style
    @children_sorted = false
  end

  def story?
    has_any_content? && date && children? && (! grand_children?)
  end

  def style
    @style ? @style : (@specials['Style'] ? @specials['Style'].style : Styles::Base.new)
  end

  def styled?
    @specials['Style']
  end

  def tags
    @content.each do |element|
      yield element if element.is_a?( Elements::Tag)
    end
  end

  def text_index( articles, wide=true)
    index = 0
    articles.select {|a| a.style.index? && (wide || (! a.wide?))}.collect do |article|
      index += 1
      title = style.index_title(article)
      if title.size > 45
        while (title.size > 45) && (/ / =~ title)
          title = title.split( ' ')[0...-1].join( ' ')
        end
        title = title + ' ...'
      end
      {'path'     => relative_path( filename, article.filename),
       'off_page' => article.off_page?,
       'title'    => title.gsub( ' ', '&nbsp;'),
       'index'    => index
      }
    end
  end

  def title
    @specials['Title'] ? @specials['Title'].text : name
  end

  def to_data
    data = {}
    data['page_title']    = page_title
    data['blurb']         = blurb ? blurb : prettify( title)
    data['page_date']     = date ? format_date(date) : nil
    data['root']          = relative_path( filename, '/')
    data['breadcrumbs']   = breadcrumbs( @parents)
    data['origins']       = @origins

    if has_any_content?
      data['content']    = @content.select {|c| c.page_content?}.collect {|c| c.to_data( @compiler, self)}
      data['line_count'] = @content.inject(0) {|r,c| r + c.line_count}
      data['overlay']    = @content.inject(false) {|r,c| r || c.overlay?}
    end

    style.render( @compiler, @parents, self, data)
    data
  end

  def wide?
    @content.inject(false) {|r,e| r || e.wide?}
  end
end
