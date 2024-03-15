require_relative '../utils'

module Elements
  class Resource < Element
    include Utils

    def initialize( compiler, article, path)
      path = path[0]
      path1  = (/^\// =~ path) ? path : abs_filename( article.filename, path).gsub( '//', '/')
      source = compiler.source_filename( path1)

      if File.exist? source
        sink = compiler.sink_filename( path1)
        compiler.record( sink)
        unless File.exist?( sink) && FileUtils.compare_file( source, sink)
          FileUtils.copy( source, sink)
        end
      else
        article.error( "Unknown resource: #{path}")
      end
    end

    def multiline?
      false
    end

    def page_content?
      false
    end
  end
end