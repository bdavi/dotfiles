require 'fileutils'

class DotFileManager
  DEFAULT_BACKUP_PATH = '~/original_dotfile_backup'
  DEFAULT_FILES_PATH = '~/code/dotfiles/config_files'

  def install *args
    init(*args)
    prepare_backup_dir
    move_existing_dotfiles_to_backup
    create_symbolic_links_to_new_files
  end

  def uninstall *args
    init(*args)
    remove_symbolic_links
    copy_dotfile_backups_to_home
    remove_dotfile_backup
  end

private
  attr_reader :filenames, :home_paths, :backup_paths, :install_paths,
              :backup_path, :files_path

  def init files_path=DEFAULT_FILES_PATH, backup_path=DEFAULT_BACKUP_PATH
    @files_path    = File.expand_path(files_path)
    @backup_path   = File.expand_path(backup_path)
    @filenames     = Dir.new(@files_path).reject {|f| f =~ /\A\.{1,2}\z/ }
    @home_paths    = Hash[filenames.map {|f| [f, File.join(Dir.home,     f)] }]
    @backup_paths  = Hash[filenames.map {|f| [f, File.join(@backup_path, f)] }]
    @install_paths = Hash[filenames.map {|f| [f, File.join(@files_path,  f)] }]
  end

  def prepare_backup_dir
    Dir.mkdir(backup_path) unless Dir.exist?(backup_path)
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
    return unless Dir.exists?(backup_path)

    filenames.each do |f|
      FileUtils.cp(backup_paths[f], home_paths[f]) if File.exist?(backup_paths[f])
    end
  end

  def remove_dotfile_backup
    FileUtils.rm_rf(backup_path) if Dir.exists?(backup_path)
  end
end
