require 'digest/md5'

module Jekyll
  
  class PhotosUtil
    def initialize(context)
      @context = context
    end

    def path_for(filename)
      filename = filename.strip
      if filename.include? "://"
        "#{filename}"
      else  
        prefix = (@context.environments.first['site']['photos_prefix'])
        "#{prefix}#{filename}"
      end
    end

    def thumb_for(filename, thumb=nil)
      filename = filename.strip
      # FIXME: This seems excessive
      if not thumb
        thumb = filename
      elsif thumb == 'default'
        parts = filename.split(".").reverse
        ext = parts.shift
        base_name = parts.reverse.join(".")
        thumb = "#{base_name}_m.#{ext}"
      elsif filename =~ /\./
        thumb = filename.gsub(/(?:_b)?\.(?<ext>[^\.]+)?$/, "_m.\\k<ext>")
      else
        thumb = "#{filename}_m"
      end
      path_for(thumb)
    end
  end

  class FancyboxStylePatch < Liquid::Tag
    def render(context)
      return <<-eof
<!-- Fix FancyBox style for OctoPress -->
<style type="text/css">
  .fancybox-wrap { position: fixed !important; }
  .fancybox-opened {
    -webkit-border-radius: 4px !important;
       -moz-border-radius: 4px !important;
            border-radius: 4px !important;
  }
  .fancybox-close, .fancybox-prev span, .fancybox-next span {
    background-color: transparent !important;
    border: 0 !important;
  }
</style>
      eof
    end
  end

  class PhotoTag < Liquid::Tag
    def initialize(tag_name, markup, tokens)
      if /(?<filename>\S+)(?:\s+(?<thumb>\S+))?(?:\s+(?<title>.+))?/i =~ markup
        @filename = filename
        @thumb = thumb
        @title = title
      end
      super
    end

    def render(context)
      p = PhotosUtil.new(context)
      if @filename
        "<a href=\"#{p.path_for(@filename)}\" class=\"fancybox\" title=\"#{@title}\"><img src=\"#{p.thumb_for(@filename,@thumb)}\" alt=\"#{@title}\" /></a>"
      else
        "Error processing input, expected syntax: {% photo filename [thumbnail] [title] %}"
      end
    end
  end

  class GalleryTag < Liquid::Block
    def initialize(tag_name, markup, tokens)
      # No initializing needed
      super
    end

    def render(context)
      # Convert the entire content array into one large string
      lines = super
      # Get a unique identifier based on content
      md5 = Digest::MD5.hexdigest(lines)
      # split the text by newlines
      lines = lines.split("\n")

      p = PhotosUtil.new(context)
      list = ""

      lines.each do |line|
        line_text = line.strip()
        if line_text.size == 0
          next
        end
        items = line_text.split(" ")
        filename = items.shift
        arg2  = items.shift
        title = items.shift
        thumb = arg2
        if arg2 and arg2.strip()[0] == "["
          thumb = arg2.strip().sub("[", "").sub("]", "")
        elsif arg2 and not title
          title = arg2.strip()
        end
        unless title
          title = filename.split("/").last
        end
        list << "<li><a href=\"#{p.path_for(filename)}\" class=\"fancybox\" rel=\"gallery-#{md5}\" title=\"#{title.strip}\">"
        list << "<img src=\"#{p.thumb_for(filename,thumb)}\" alt=\"#{title.strip}\" style=\"width: 220px;\"/></a></li>"
      end
      "<ul class=\"gallery\">\n#{list}\n</ul>"
    end
  end

end

Liquid::Template.register_tag('photo', Jekyll::PhotoTag)
Liquid::Template.register_tag('gallery', Jekyll::GalleryTag)
Liquid::Template.register_tag('fancyboxstylefix', Jekyll::FancyboxStylePatch)
