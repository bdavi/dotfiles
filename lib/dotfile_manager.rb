require 'fileutils'

class DotFileManager
  def initialize config
    @config        = config
    @filenames     = Dir.new(@config.dotfiles_dir).reject {|f| f =~ /\A\.{1,2}\z/ }
    @home_paths    = Hash[filenames.map {|f| [f, File.join(Dir.home, f)           ] }]
    @backup_paths  = Hash[filenames.map {|f| [f, File.join(config.backup_dir, f)  ] }]
    @install_paths = Hash[filenames.map {|f| [f, File.join(config.dotfiles_dir, f)] }]
  end

  def install
    prepare_backup_dir
    move_existing_dotfiles_to_backup
    create_symbolic_links_to_new_files
  end

  def uninstall
    remove_symbolic_links
    copy_dotfile_backups_to_home
    remove_dotfile_backup
  end

private
  attr_reader :config, :filenames, :home_paths, :backup_paths, :install_paths

  def prepare_backup_dir
      Dir.mkdir(config.backup_dir) unless Dir.exist?(config.backup_dir)
  end

  def move_existing_dotfiles_to_backup
    filenames.each do |f|
      FileUtils.mv(home_paths[f], backup_paths[f]) if File.exist?(home_paths[f])
    end
  end

  def create_symbolic_links_to_new_files
    filenames.each do |f|
      FileUtils.ln_s(install_paths[f], home_paths[f])
    end
  end

  def remove_symbolic_links
    FileUtils.rm home_paths.values, force: true
  end

  def copy_dotfile_backups_to_home
    filenames.each do |f|
      FileUtils.cp(backup_paths[f], home_paths[f]) if File.exist?(backup_paths[f])
    end
  end

  def remove_dotfile_backup
    FileUtils.rm_rf config.backup_dir
  end
end
