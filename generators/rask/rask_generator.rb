class RaskGenerator < Rails::Generator::NamedBase
  def initialize(runtime_args, runtime_options = {})
    super
  end

  def manifest
    record do |m|
      m.class_collisions class_path, "#{class_name}Task"
      m.directory File.join('lib/rask', class_path)
      m.directory File.join('script/rask', class_path)
      
      m.template 'lib.rb', 
                 File.join('lib/rask', 
                 class_path, 
                 "#{file_name}_task.rb") 

      m.template 'script.rb', 
                 File.join('script/rask', 
                 class_path, 
                 "#{file_name}_task.rb") 

    end
  end
end

