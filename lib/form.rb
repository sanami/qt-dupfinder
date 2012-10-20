Qt::require ROOT('resources/form.ui'), ROOT('tmp')
Qt::require ROOT('resources/resources.qrc'), ROOT('tmp')

class Form < Qt::MainWindow
  slots 'on_action_start_triggered()'
  slots 'on_action_delete_files_triggered()'
  slots 'on_action_delete_all_triggered()'
  slots 'on_action_quit_triggered()'
  slots 'on_action_new_triggered()'
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

  # Выйти из программы
  def on_action_quit_triggered
    $qApp.quit
  end

  # Запустить поиск
  def on_action_start_triggered
    find_in_folder
  end

  # Вызывается из меню
  def on_action_delete_files_triggered
    delete_selected_files @ui.duplicates
  end

  # Выбрать каталог
  def on_action_new_triggered
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
    $qApp.processEvents

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
  def on_action_delete_all_triggered
    if Qt::MessageBox::question(self, "Confirm delete all", "Are you sure?", Qt::MessageBox::Ok, Qt::MessageBox::Cancel) != Qt::MessageBox::Ok
      return
    end

    while (it = @ui.duplicates.takeTopLevelItem(0))
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

  # Открыть документ или архив
  def on_duplicates_itemDoubleClicked(it, column)
    url = Qt::Url.new("file:///" + it.text(1))
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

    @ui.folders.setPlainText(@settings.folders)
  end

  # Сохранение настроек
  def save_settings
    @settings.form_geometry = self.saveGeometry.to_s
    @settings.splitter_state = @ui.splitter.saveState.to_s

    @settings.folders = @ui.folders.toPlainText
  end

end
