class CompareSites
  def ignore?( path)
    false
    # return true if /Diary\/201(3|4)/ =~ path
    # ['Articles/Diary/2022/wagamamas/index.html',
    #  'Articles/Diary/2022/Thursford_2022/index.html',
    # 'Articles/Diary/2022/browns_cambridge/index.html'].include?( path)
  end

  def compare_dir( dir1, dir2)
    entries1 = list_dir( dir1)
    entries2 = list_dir( dir2)

    entries1.each_pair do |f1,p1|
      if p2 = entries2[f1]
        if File.directory?( p1)
          compare_dir( p1, p2)
        elsif /\.html$/ =~ f1
          compare_html( p1, p2)
        end
      else
        error "Removed #{p1}"
      end
    end

    entries2.each_pair do |f,p|
      unless entries1[f]
        error "Added #{p}"
      end
    end
  end

  def error( msg)
    puts "*** #{msg}"
    exit 1
  end

  def list_dir( dir)
    map = {}
    Dir.entries( dir).each do |f|
      unless /^(\.|_)/ =~ f
        map[ f] = dir + '/' + f
      end
    end
    map
  end

  def compare_html( f1, f2)
    return if ignore?( f1)
    lines1 = load_lines( f1)
    lines2 = load_lines( f2)

    (0...(lines1.size)).each do |i|
      if lines1[i] != lines2[i]
        puts lines1[i]
        puts lines2[i]
        error "Line #{i+1} different for #{f1}"
      end
    end

    if lines1.size != lines2.size
      error "Different size to #{f1}"
    end
  end

  def load_lines( f)
    lines, inside = [], false
    IO.readlines( f).each do |line|
      if /<pre>/i =~ line
        lines  << line.strip
        inside = true
      elsif /<\/pre>/i =~ line
        lines  << line.rstrip
        inside = false
      elsif inside
        lines  << line.rstrip
      elsif line.strip != ''
        lines << line.strip
      end
    end
  end
end

cs = CompareSites.new
cs.compare_dir( ARGV[0], ARGV[1])