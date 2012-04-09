Qt::require ROOT('resources/form.ui'), ROOT('tmp')
Qt::require ROOT('resources/resources.qrc'), ROOT('tmp')

class Form < Qt::MainWindow
  slots 'on_toolButton_clicked()'
  slots 'on_toolButton_2_clicked()'
  slots 'on_toolButton_3_clicked()'
  slots 'on_comboBox_currentIndexChanged(const QString &)'
  slots 'on_checkBox_clicked()'

  slots 'on_action_start_triggered()'
  slots 'on_action_delete_files_triggered()'
  slots 'on_action_delete_all_triggered()'

  slots 'on_action_quit_triggered()'
  slots 'on_action_new_triggered()'
  slots 'on_action_open_triggered()'
  slots 'on_action_save_triggered()'
  slots 'on_action_save_as_triggered()'

  slots 'on_treeWidget_2_itemDoubleClicked(QTreeWidgetItem *, int)'

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
    unless $debug
      if Qt::MessageBox::question(self, "Confirm Exit", "Are you sure?", Qt::MessageBox::Ok, Qt::MessageBox::Cancel) != Qt::MessageBox::Ok
        e.ignore
        return
      end
    end

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
    Qt::optimize_layouts self

    resize(1000, 600)
    move(0, 0)
    setWindowIcon(Qt::Icon.new(':/resources/app.ico'))
    setWindowTitle 'DupFinder'

    # Скрыть меню
    @ui.menubar.hide

    # Настроить тулбар
    #@ui.groupBox.children.each do |c|
    #	#p c.class
    #	unless c.inherits "QLayoutItem"
    #		@ui.toolBar.addWidget c
    #	end
    #
    #end
    #@ui.groupBox.dispose

    @ui.treeWidget.setColumnWidth 0, 150
    @ui.treeWidget.setColumnWidth 1, 600
    @ui.treeWidget.setColumnWidth 2, 600

    @ui.treeWidget_2.setColumnWidth 0, 150

    # Контекстное меню
    @ui.treeWidget_2.addAction @ui.action_delete_files

  end

  # В отдельный таб со списком сообщений
  def log(str)
    @ui.textEdit.append str
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
    tab = @ui.tabWidget.tabText(@ui.tabWidget.currentIndex)
    case tab
      when 'Compare'
        compare_folders
      when 'Find'
        find_in_folder
      else
        pp tab
    end
  end

  # Вызывается из меню
  def on_action_delete_files_triggered
    delete_selected_files @ui.treeWidget_2
    #tab = @ui.tabWidget.tabText(@ui.tabWidget.currentIndex)
    #case tab
    #	when 'Compare'
    #		delete_selected_files @ui.treeWidget
    #	when 'Find'
    #		delete_selected_files @ui.treeWidget_2
    #	else
    #		pp tab
    #end
  end

  # Сравнение двух каталогов
  def compare_folders
    folder1 = @ui.lineEdit.text
    folder2 = @ui.lineEdit_2.text

    log 'compare_folders'
    log folder1
    log folder2

    @ui.treeWidget.clear

    @finder.compare(folder1, folder2) do |files1, files2|
      pp [files1, files2]
      pp '------------------------'
      file_size = files1[0].size.to_s.rjust(12)
      parent_it = nil

      max_index = [files1.count, files2.count ].max
      max_index.times do |i|
        text1 = "#{files1[i]}"
        text2 = "#{files2[i]}"

        if parent_it
          Qt::TreeWidgetItem.new parent_it, [nil, text1, text2]
        else
          parent_it = Qt::TreeWidgetItem.new @ui.treeWidget, [file_size, text1, text2]
          parent_it.setTextAlignment 0, Qt::AlignRight
          parent_it.setExpanded true
        end

      end

    end
  end

  # Поиск дубликатов в каталоге
  def find_in_folder
    folder = @ui.lineEdit_3.text

    log 'find_in_folder'
    log folder

    @ui.treeWidget_2.clear
    @finder.run(folder) do |dup_files|
      pp dup_files
      pp '------------------------'

      parent_it = nil
      dup_files.each do |file|
        if parent_it
          Qt::TreeWidgetItem.new parent_it, [nil, file.to_s]
        else
          size = file.size.to_s.rjust(12)
          parent_it = Qt::TreeWidgetItem.new @ui.treeWidget_2, [size, file.to_s]
          parent_it.setTextAlignment 0, Qt::AlignRight
          parent_it.setExpanded true
        end
      end
    end
  end

  # Delete all duplicates
  def on_action_delete_all_triggered
    if Qt::MessageBox::question(self, "Confirm delete all", "Are you sure?", Qt::MessageBox::Ok, Qt::MessageBox::Cancel) != Qt::MessageBox::Ok
      return
    end

    while (it = @ui.treeWidget_2.takeTopLevelItem(0))
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
  def on_treeWidget_2_itemDoubleClicked(it, column)
    url = Qt::Url.new("file:///" + it.text(1))
    Qt::DesktopServices::openUrl(url);
  end

  # Выбрать каталог
  def select_folder(control)
    dir_name = Qt::FileDialog::getExistingDirectory(self, 'Select folder', control.text, Qt::FileDialog::ShowDirsOnly)
    if dir_name
      control.text = dir_name
    end
  end

  def on_toolButton_clicked
    select_folder @ui.lineEdit
  end

  def on_toolButton_2_clicked
    select_folder @ui.lineEdit_2
  end

  def on_toolButton_3_clicked
    select_folder @ui.lineEdit_3
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

  #
  def on_action_new_triggered
    #if Qt::MessageBox::question(self, "Confirm Clear", "Are you sure?", Qt::MessageBox::Ok, Qt::MessageBox::Cancel) == Qt::MessageBox::Ok
    #end
  end

  # Открыть диалог добавление каталога
  def on_action_open_triggered
    #@settings.current_dir ||= '.'
    #dir_name = Qt::FileDialog::getExistingDirectory(self, 'Add Directory', @settings.current_dir, Qt::FileDialog::ShowDirsOnly)
    #if dir_name
    #	add_folder dir_name
    #	@settings.current_dir = dir_name
    #end
  end

  #
  def on_comboBox_currentIndexChanged(text)
  end

  #
  def on_checkBox_clicked
#		if @ui.checkBox.checked?
#		else
#	  end
  end

  # Загрузка и применение настроек
  def load_settings
    if @settings.form_geometry
      self.restoreGeometry Qt::ByteArray.new(@settings.form_geometry.to_s)
    end

    @ui.lineEdit.text = @settings.folder1
    @ui.lineEdit_2.text = @settings.folder2
    @ui.lineEdit_3.text = @settings.folder3
  end

  # Сохранение настроек
  def save_settings
    @settings.form_geometry = self.saveGeometry.to_s

    @settings.folder1 = @ui.lineEdit.text
    @settings.folder2 = @ui.lineEdit_2.text
    @settings.folder3 = @ui.lineEdit_3.text
  end

end
