require 'net/http'
require 'net/https'
require 'uri'

module Utils
  def abs_filename( path, filename)
    return filename if /^\// =~ filename
    path = File.dirname( path)
    while /^\.\.\// =~ filename
      path = File.dirname( path)
      filename = filename[3..-1]
    end

    if /\/$/ =~ path
      path + filename
    else
      path + '/' + filename
    end
  end

  def browser_get( url)
    @driver = Selenium::WebDriver.for :chrome unless defined?( @driver)
    @driver.navigate.to url
    @driver.execute_script('return document.documentElement.outerHTML;')
  end

  def column_align( value)
    return 'right' if /^\d+$/ =~ value
    'left'
  end

  def format_date( date)
    date.strftime( "%A, ") + date.day.to_s + format_ord( date.day) + date.strftime( " %B %Y")
  end

  def format_date_smaller( date)
    date.day.to_s + format_ord( date.day) + date.strftime( " %b %Y")
  end

  def format_ord( n)
    if (n > 3) and (n < 21)
      "th"
    elsif (n % 10) == 1
      "st"
    elsif (n % 10) == 2
      "nd"
    elsif (n % 10) == 3
      "rd"
    else
      "th"
    end
  end

  def get_scaled_dims( dims, images)
    aspect = 1000
    images.each do |image|
      next if image.width.nil?
      a = (image.height.to_f) / image.width
      aspect = a if a < aspect
    end

    a = dims[-1][1].to_f / dims[-1][0]
    aspect = a if a > aspect

    dims.collect do |dim|
      a =
      if dim[0] * aspect > dim[1]
        [(dim[1] / aspect).to_i, dim[1]]
      else
        [dim[0], (aspect * dim[0]).to_i]
      end
    end
  end

  # def hash( text)
  #   h = 0
  #   text.bytes.each do |b|
  #     h = h * 37 + b
  #   end
  #   h
  # end

  def http_get( url)
    uri = URI.parse( url)
    http = Net::HTTP.new( uri.host, uri.port)
    if /^https/ =~ url
      http.use_ssl     = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end

    response = http.request( Net::HTTP::Get.new(uri.request_uri))
    return response.code.to_i, response.body, response['Location']
    #response.value
    #response.body
  end

  def prettify( name)
    if m = /^\d+[_](.+)$/.match( name)
      name = m[1]
    end
    if name.downcase == name
      name.split( "_").collect do |part|
        part.capitalize
      end.join( " ")
    else
      name.gsub( "_", " ")
    end
  end

  def prettify_sort( name)
    name = prettify( name).downcase
    if m = /^(the|a|an) (.*)$/.match( name)
      m[2] + ', ' + m[1]
    else
      name
    end
  end

  def relative_path( from, to)
    return '.' if to.nil?
    from = from.split( "/")
    from = from[1..-1] if from[0] == ''
    from = from[0...-1] if /\.(html|php|txt)$/ =~ from[-1]

    to = to.split( "/")
    to = to[1..-1] if to[0] == ''

    while (to.size > 0) and (from.size > 0) and (to[0] == from[0])
      from = from[1..-1]
      to = to[1..-1]
    end
    rp = ((from.collect { ".."}) + to).join( "/")
    (rp == '') ? '.' : rp
  end
end