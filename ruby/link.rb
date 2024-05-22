class Link
  def initialize( article, tag, title=nil)
    @article = article
    @tag     = tag
    @title   = title ? title : @tag.title
  end

  def children
    []
  end

  def children?
    false
  end

  def has_content?
    false
  end

  def method_missing( name, *args, &block)
    @tag.send( name, *args, &block)
  end

  # def off_page?
  #   true
  # end

  def prepare
  end

  def title
    @title
  end
end
