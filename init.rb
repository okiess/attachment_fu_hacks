#http://www.deepcalm.com/writing/cropped-thumbnails-in-attachment_fu-using-imagescience
Geometry.class_eval do
    FLAGS = ['', '%', '<', '>', '!']#, '@']
    
    # Convert object to a geometry string
    def to_s
      str = ''
      str << "%g" % @width if @width > 0
      str << 'x' if (@width > 0 || @height > 0)
      str << "%g" % @height if @height > 0
      str << "%+d%+d" % [@x, @y] if (@x != 0 || @y != 0)
      str << RFLAGS.index(@flag)
      #str << FLAGS[@flag.to_i]
    end
    
    def new_dimensions_for(orig_width, orig_height)
      new_width  = orig_width
      new_height = orig_height

      case @flag
        when :aspect
          new_width = @width unless @width.nil?
          new_height = @height unless @height.nil?
        when :percent
          scale_x = @width.zero?  ? 100 : @width
          scale_y = @height.zero? ? @width : @height
          new_width    = scale_x.to_f * (orig_width.to_f  / 100.0)
          new_height   = scale_y.to_f * (orig_height.to_f / 100.0)
        when :<, :>, nil
          scale_factor =
            if new_width.zero? || new_height.zero?
              1.0
            else
              if @width.nonzero? && @height.nonzero?
                [@width.to_f / new_width.to_f, @height.to_f / new_height.to_f].min
              else
                @width.nonzero? ? (@width.to_f / new_width.to_f) : (@height.to_f / new_height.to_f)
              end
            end
          new_width  = scale_factor * new_width.to_f
          new_height = scale_factor * new_height.to_f
          new_width  = orig_width  if @flag && orig_width.send(@flag,  new_width)
          new_height = orig_height if @flag && orig_height.send(@flag, new_height)
      end

      [new_width, new_height].collect! { |v| v.round }
    end
    
end

#http://blog.iandrysdale.com/2007/05/22/cropped-thumbnails-in-attachment_fu-using-mini_magick/
Technoweenie::AttachmentFu::Processors::MiniMagickProcessor.module_eval do
  def resize_image(img, size)
    size = size.first if size.is_a?(Array) && size.length == 1
    if size.is_a?(Fixnum) || (size.is_a?(Array) && size.first.is_a?(Fixnum))
      if size.is_a?(Fixnum)
        size = [size, size]
        img.resize(size.join('x'))
      else
        img.resize(size.join('x') + '!')
      end
    else
      n_size = [img[:width], img[:height]] / size.to_s
      if size.ends_with? "!"
        aspect = n_size[0].to_f / n_size[1].to_f
        ih, iw = img[:height], img[:width]
        if aspect > 1 and iw > ih
          w, h = (ih / aspect), (iw * aspect)
        else
          w, h = (ih * aspect), (iw / aspect)
        end
        w = [iw, w].min.to_i
        h = [ih, h].min.to_i
        offset = 0.5 # Tweak this parameter if necessary
        if ih > h
          img.gravity 'center'
          img.crop("#{h}x#{h}+0+#{offset * (ih-h)}")
        end
        if iw > w
          img.gravity 'center'
          img.crop("#{w}x#{w}+#{offset * (iw-w)}+0")
        end
        img.resize(size.to_s)
      else
        img.resize(size.to_s)
      end
    end
    temp_paths.unshift img
  end
end

