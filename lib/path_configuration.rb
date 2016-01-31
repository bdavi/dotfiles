require 'yaml'

class PathConfiguration
  attr_reader :paths

  def initialize path_to_config_file
    @paths = YAML::load_file(path_to_config_file)
  end

  def method_missing m, *args, &block
    return nil unless paths[m.to_s]
    File.expand_path(paths[m.to_s])
  end
end
