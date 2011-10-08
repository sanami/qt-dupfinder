Qt::require ROOT('resources/form.ui'), ROOT('tmp')
Qt::require ROOT('resources/resources.qrc'), ROOT('tmp')

class Form < Qt::MainWindow
	slots 'on_toolButton_clicked()'
	slots 'on_comboBox_currentIndexChanged(const QString &)'
	slots 'on_checkBox_clicked()'

	slots 'on_action_start_triggered()'

	slots 'on_action_quit_triggered()'
	slots 'on_action_new_triggered()'
	slots 'on_action_open_triggered()'
	slots 'on_action_save_triggered()'
	slots 'on_action_save_as_triggered()'

	def initialize(settings, finder)
		super()
		init_ui

		@finder = finder

		# Загрузить настройки
		@settings = settings
		load_settings
	end

protected
	##
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
	##
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

		@ui.treeWidget.setColumnWidth 0, 600
		@ui.treeWidget.setColumnWidth 1, 600

	end

	##
	# В отдельный таб со списком сообщений
	def log(str)
		@ui.textEdit.append str
	end

	##
	# Сообщение в строке статуса
	def show_message(str)
		statusBar.showMessage str
	end
	
	def inform_pic_change(pic)
		@settings.current_file = pic.filename
		t = Time.now.strftime('%H:%M:%S')
		log "#{t} #{pic.columns} x #{pic.rows} #{pic.filesize} #{pic.filename}"
		show_message "#{t} #{pic.filename}"
	end

	##
	# Выйти из программы
	def on_action_quit_triggered
		$qApp.quit
	end

	##
	# Запустить поиск
	def on_action_start_triggered
		folder1 = @ui.lineEdit.text
		folder2 = @ui.lineEdit_2.text

		@ui.treeWidget.clear

		@finder.run(folder1, folder2) do |files1, files2|
			pp [files1, files2]
			pp '------------------------'
			max_index = [files1.count, files2.count ].max
			file_size = files1[0].size
			parent_it = nil
			max_index.times do |i|
				text1 = "#{files1[i]}"
				text2 = "#{files2[i]}"

				columns = [ text1, text2, file_size.to_s ]

				if parent_it
					Qt::TreeWidgetItem.new parent_it, columns
				else
					parent_it = Qt::TreeWidgetItem.new @ui.treeWidget, columns
					parent_it.setExpanded true
				end

			end

		end

	end

	#		Qt::TreeWidgetItem.new @ui.treeWidget, [dir]
	#Qt::DesktopServices::openUrl(Qt::Url.new("file://#{@settings.current_file}"));

	##
	#
	def on_action_new_triggered
		#if Qt::MessageBox::question(self, "Confirm Clear", "Are you sure?", Qt::MessageBox::Ok, Qt::MessageBox::Cancel) == Qt::MessageBox::Ok
		#end
	end

	##
	# Открыть диалог добавление каталога
	def on_action_open_triggered
		#@settings.current_dir ||= '.'
		#dir_name = Qt::FileDialog::getExistingDirectory(self, 'Add Directory', @settings.current_dir, Qt::FileDialog::ShowDirsOnly)
		#if dir_name
		#	add_folder dir_name
		#	@settings.current_dir = dir_name
		#end
	end

	##
	#
	def on_toolButton_clicked
	end

	##
	#
	def on_comboBox_currentIndexChanged(text)
	end

	##
	#
	def on_checkBox_clicked
#		if @ui.checkBox.checked?
#		else
#	  end
	end

	##
	# Загрузка и применение настроек
	def load_settings
		if @settings.form_geometry
			self.restoreGeometry Qt::ByteArray.new(@settings.form_geometry.to_s)
		end

		if @settings.current_dir
			add_folder @settings.current_dir
		end
	end

	##
	# Сохранение настроек
	def save_settings
		@settings.form_geometry = self.saveGeometry.to_s
	end

end
