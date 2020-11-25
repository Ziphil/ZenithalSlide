# coding: utf-8


class Zenithal::Slide::WholeSlideConverter

  TEMPLATE = File.read(File.join(File.dirname(__FILE__), "resource/template.html"))

  def initialize(args)
    @mode, @open = nil, false
    @dirs = {:output => "out", :document => "document", :template => "template"}
    @image_size = [1920, 1080]
    options, rest_args = args.partition{|s| s =~ /^\-\w$/}
    if options.include?("-i")
      @mode = :image
    else
      if options.include?("-o")
        @open = true
      end
      @mode = :normal
    end
    @rest_args = rest_args
    @paths = create_paths
    @parser = create_parser
    @converter = create_converter
    @driver = create_driver
  end

  def execute
    case @mode
    when :image
      execute_image
    when :normal
      execute_normal
    end
  end

  def execute_normal
    @paths.each_with_index do |path, index|
      convert_normal(path)
      convert_open(path) if @open
    end
  end

  def execute_image
    @paths.each_with_index do |path, index|
      convert_image(path)
    end
    @driver.quit
  end

  def convert_normal(path)
    extension = File.extname(path).gsub(/^\./, "")
    output_path = path.gsub(@dirs[:document], @dirs[:output]).then(&method(:modify_extension))
    count_path = path.gsub(@dirs[:document], @dirs[:output]).gsub("slide", "image").gsub(".zml", ".txt")
    output_dir = File.dirname(output_path)
    count_dir = File.dirname(count_path)
    FileUtils.mkdir_p(output_dir)
    FileUtils.mkdir_p(count_dir)
    case extension
    when "zml"
      @parser.update(File.read(path))
      document = @parser.run
      @converter.update(document)
      main_string = @converter.convert
      header_string = ""
      count = @converter.variables[:slide_count].to_i.to_s
      output = TEMPLATE.gsub(/#\{(.*?)\}/){instance_eval($1)}.gsub(/\r/, "")
      File.write(output_path, output)
      File.write(count_path, count)
    when "scss"
      option = {}
      option[:style] = :expanded
      option[:filename] = path
      output = SassC::Engine.new(File.read(path), option).render
      File.write(output_path, output)
    when "html", "js", "svg"
      output = File.read(path)
      File.write(output_path, output)
    end
  end

  def convert_image(path)
    page_path = path.gsub(@dirs[:document], @dirs[:output]).then(&method(:modify_extension))
    output_path = path.gsub(@dirs[:document], @dirs[:output]).gsub("slide", "image").gsub(".zml", "")
    count_path = path.gsub(@dirs[:document], @dirs[:output]).gsub("slide", "image").gsub(".zml", ".txt")
    output_dir = File.dirname(output_path)
    count = File.read(count_path).to_i
    FileUtils.mkdir_p(output_dir)
    @driver.navigate.to("file:///#{File.join(Dir.pwd, page_path)}")
    @driver.manage.window.resize_to(*@image_size)
    @driver.execute_script("document.body.classList.add('simple');")
    count.times do |index|
      @driver.execute_script("document.querySelectorAll('*[class$=\\'slide\\']')[#{index}].scrollIntoView();")
      @driver.save_screenshot("#{output_path}-#{index}.png")
    end
  end

  def convert_open(path)
    output_path = path.gsub(@dirs[:document], @dirs[:output]).then(&method(:modify_extension))
    Kernel.spawn("start #{output_path}")
  end

  def create_paths
    paths = []
    if @rest_args.empty?
      dirs = []
      dirs << File.join(@dirs[:document], "slide")
      if @mode == :normal
        dirs << File.join(@dirs[:document], "asset") 
        paths << File.join(@dirs[:document], "style", "style.scss")
        paths << File.join(@dirs[:document], "script", "script.js")
      end
      dirs.each do |dir|
        Dir.each_child(dir) do |entry|
          if entry =~ /\.\w+$/
            paths << File.join(dir, entry)
          end
        end
      end
    else
      path = @rest_args.map{|s| s.gsub("\\", "/").gsub("c:/", "C:/")}[0].encode("utf-8")
      paths << path
    end
    return paths
  end

  def create_parser(main = true)
    parser = ZenithalParser.new("")
    parser.brace_name = "x"
    parser.bracket_name = "xn"
    parser.slash_name = "i"
    if main
      parser.register_macro("import") do |attributes, _|
        import_path = attributes["src"]
        import_parser = create_parser(false)
        import_parser.update(File.read(File.join(@dirs[:document], import_path)))
        document = import_parser.run
        import_nodes = (attributes["expand"]) ? document.root.children : [document.root]
        next import_nodes
      end
    end
    return parser
  end

  def create_converter
    converter = ZenithalConverter.new(nil, :text)
    Dir.each_child(@dirs[:template]) do |entry|
      if entry.end_with?(".rb")
        binding = TOPLEVEL_BINDING
        binding.local_variable_set(:converter, converter)
        Kernel.eval(File.read(File.join(@dirs[:template], entry)), binding, entry)
      end
    end
    return converter
  end

  def create_driver
    if @mode == :image
      options = Selenium::WebDriver::Chrome::Options.new
      options.add_argument("--headless")
      options.add_option("excludeSwitches", ["enable-logging"])
      driver = Selenium::WebDriver.for(:chrome, options: options)
    else
      driver = nil
    end
    return driver
  end

  def modify_extension(path)
    result = path.clone
    result.gsub!(/\.zml$/, ".html")
    result.gsub!(/\.scss$/, ".css")
    result.gsub!(/\.ts$/, ".js")
    return result
  end

  def output_dir=(dir)
    @dirs[:output] = dir
  end

  def document_dir=(dir)
    @dirs[:document] = dir
  end

  def template_dir=(dir)
    @dirs[:template] = dir
  end

  def image_size=(image_size)
    @image_size = image_size
  end

end