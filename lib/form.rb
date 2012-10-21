Qt::require ROOT('resources/form.ui'), ROOT('tmp')
Qt::require ROOT('resources/resources.qrc'), ROOT('tmp')

class Form < Qt::MainWindow
  slots 'on_start_clicked()'
  slots 'on_add_folder_clicked()'
  slots 'on_delete_all_clicked()'
  slots 'on_action_delete_files_triggered()'
  slots 'on_duplicates_itemDoubleClicked(QTreeWidgetItem *, int)'

  def initialize(settings, finder)
    super()
    init_ui

    @finder = finder

    # Загрузить настройки
    @settings = settings
    load_settings
  end

protected
  # Не должен быть private
  def closeEvent(e)
    #unless $debug
    #  if Qt::MessageBox::question(self, "Confirm Exit", "Are you sure?", Qt::MessageBox::Ok, Qt::MessageBox::Cancel) != Qt::MessageBox::Ok
    #    e.ignore
    #    return
    #  end
    #end

    # Сохранить настройки
    save_settings
    super
    puts "closeEvent"
    $qApp.quit
  end

private
  # Инициализация GUI
  def init_ui
    @ui = Ui::Form.new
    @ui.setupUi(self)
    #Qt::optimize_layouts self

    resize(1000, 600)
    move(0, 0)
    setWindowIcon(Qt::Icon.new(':/resources/app.ico'))
    setWindowTitle 'DupFinder'

    # Скрыть меню
    @ui.menubar.hide

    @ui.duplicates.setColumnWidth 0, 150

    # Контекстное меню
    @ui.duplicates.addAction @ui.action_delete_files

  end

  # Сообщение в строке статуса
  def show_message(str)
    statusBar.showMessage str
  end

  # Запустить поиск
  def on_start_clicked
    find_in_folder
  end

  # Вызывается из меню
  def on_action_delete_files_triggered
    delete_selected_files @ui.duplicates
  end

  # Выбрать каталог
  def on_add_folder_clicked
    @settings.last_dir ||= '.'
    dir_name = Qt::FileDialog::getExistingDirectory(self, 'Select folder', @settings.last_dir, Qt::FileDialog::ShowDirsOnly)
    if dir_name
      @ui.folders.appendPlainText dir_name
      @settings.last_dir = dir_name
    end
  end

  # Поиск дубликатов в каталоге
  def find_in_folder
    folders = @ui.folders.toPlainText.split("\n")
    @ui.folders.setReadOnly(true)
    @ui.duplicates.clear

    @finder.run(folders) do |dup_files|
      pp dup_files
      pp '------------------------'

      parent_it = nil
      dup_files.each do |file|
        if parent_it
          Qt::TreeWidgetItem.new parent_it, [nil, file.to_s]
        else
          size = file.size.to_s.rjust(12)
          parent_it = Qt::TreeWidgetItem.new @ui.duplicates, [size, file.to_s]
          parent_it.setTextAlignment 0, Qt::AlignRight
          parent_it.setExpanded true
        end
      end
      $qApp.processEvents

    end

    @ui.folders.setReadOnly(false)
  end

  # Delete all duplicates
  def on_delete_all_clicked
    #if Qt::MessageBox::question(self, "Confirm delete all", "Are you sure?", Qt::MessageBox::Ok, Qt::MessageBox::Cancel) != Qt::MessageBox::Ok
    #  return
    #end

    folders_to_clean = @ui.folders_to_clean.toPlainText.split("\n")
    folders_to_clean.select! do |dir_name|
      File.directory?(dir_name)
    end
    puts "folders_to_clean:"
    pp folders_to_clean
    real_delete = !@ui.pretend.isChecked
    puts "real_delete = #{real_delete}"

    top_level_row = 0
    while (it = @ui.duplicates.topLevelItem(top_level_row))
      # Files in item
      all_files = get_item_files(it)
      #pp all_files.keys

      # Files in folders to clean
      files_to_delete = all_files.select do |file_path, file_item|
        # Skip files archives
        if file_path.start_with? 'zip://'
          false
        else
          file_dir = File.dirname(file_path)
          to_delete = folders_to_clean.any? {|dir| file_dir.start_with?(dir) }
        end
      end

      # Leave one file
      if files_to_delete.count == all_files.count
        # First file in 'all_files' is top_item
        top_file = all_files.keys.first
        files_to_delete.delete top_file
      end

      unless files_to_delete.empty?
        puts "files_to_delete:"
        pp files_to_delete.keys
      end

      top_item_removed = false

      files_to_delete.each do |file_path, file_item|
        puts "delete: #{file_path}"
        if real_delete
          begin
            File.delete file_path
          rescue => ex
            pp ex
          end
        end

        unless file_item.parent
          top_item_removed = true
        end

        # Remove item from tree
        file_item.dispose
      end

      unless top_item_removed
        top_level_row += 1
      end
    end

  end

  # Files in top item / children items
  #
  # Returns { path => item, ...}
  def get_item_files(it)
    file_path = it.text(1)
    all = { file_path => it }

    it.childCount.times do |i|
      child = it.child(i)
      file_path = child.text(1)
      all[file_path] = child
    end

    all
  end

  # Открыть документ или архив
  def on_duplicates_itemDoubleClicked(it, column)
    url = Qt::Url.fromLocalFile(it.text(1))
    Qt::DesktopServices::openUrl(url);
  end

  # Удалить файлы выбранные в таблице результатов поиска
  def delete_selected_files(table)
    until (all = table.selectedItems).empty?
      it = all.first
      file_path = it.text(1)

      puts "delete: #{file_path}"
      begin
        File.delete file_path
      rescue => ex
        pp ex
      end

      # Удалить из таблицы
      it.dispose
    end
  end

  # Загрузка и применение настроек
  def load_settings
    if @settings.form_geometry
      self.restoreGeometry Qt::ByteArray.new(@settings.form_geometry.to_s)
    end
    if @settings.splitter_state
      @ui.splitter.restoreState Qt::ByteArray.new(@settings.splitter_state.to_s)
    end
    if @settings.splitter_2_state
      @ui.splitter_2.restoreState Qt::ByteArray.new(@settings.splitter_2_state.to_s)
    end

    @ui.folders.setPlainText(@settings.folders)
    @ui.folders_to_clean.setPlainText(@settings.folders_to_clean)
  end

  # Сохранение настроек
  def save_settings
    @settings.form_geometry = self.saveGeometry.to_s
    @settings.splitter_state = @ui.splitter.saveState.to_s
    @settings.splitter_2_state = @ui.splitter_2.saveState.to_s

    @settings.folders = @ui.folders.toPlainText
    @settings.folders_to_clean = @ui.folders_to_clean.toPlainText
  end

end
